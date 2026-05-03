import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private var overlayController: OverlayPanelController?
    private var animator: SpriteAnimator?
    private var settingsWindow: NSWindow?
    private var axObserver: CodexAccessibilityObserver?
    private var stateDetector: CodexStateDetector?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        configureMainMenu()
        loadStateDetector()
        launchOverlay()
        startAccessibilityObserver()
    }

    func applicationWillTerminate(_ notification: Notification) {
        settings.save()
        axObserver?.stop()
        animator?.stop()
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "Codex Pet Overlay")

        addRecoveryItems(to: appMenu)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Codex Pet Overlay", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        appItem.submenu = appMenu
        mainMenu.addItem(appItem)
        NSApp.mainMenu = mainMenu
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu(title: "Codex Pet Overlay")
        addRecoveryItems(to: menu)
        return menu
    }

    private func addRecoveryItems(to menu: NSMenu) {
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let disableClickThroughItem = NSMenuItem(title: "Disable Click-through", action: #selector(disableClickThrough), keyEquivalent: "t")
        disableClickThroughItem.target = self
        menu.addItem(disableClickThroughItem)
    }

    private func loadStateDetector() {
        let configURL = Bundle.main.resourceURL?.appendingPathComponent("config/state-rules.json")
        stateDetector = CodexStateDetector(configURL: configURL)
    }

    private func launchOverlay() {
        let loader = PetFolderLoader()
        let result = loader.loadPet(settings: settings)

        switch result {
        case .success(let atlas):
            let spriteView = SpriteOverlayView(atlas: atlas, settings: settings)
            let controller = OverlayPanelController(spriteView: spriteView, settings: settings)
            let animator = SpriteAnimator { [weak spriteView] frameIndex in
                spriteView?.frameIndex = frameIndex
            }

            spriteView.onManualStateSelected = { [weak self] state in
                self?.settings.manualState = state
                self?.applyAnimationState(state, bubble: state.displayName)
            }
            spriteView.onOpenSettings = { [weak self] in
                self?.showSettings(nil)
            }
            spriteView.onDisableClickThrough = { [weak self] in
                self?.disableClickThrough(nil)
            }

            settings.onChange = { [weak self, weak spriteView, weak controller] in
                spriteView?.scale = self?.settings.scale ?? 2.0
                spriteView?.showsStatusBubble = self?.settings.showStatusBubble ?? true
                controller?.applySettings()
                if self?.settings.stateDetectionEnabled == false {
                    self?.applyAnimationState(self?.settings.manualState ?? .idle, bubble: "Manual")
                }
            }

            self.overlayController = controller
            self.animator = animator
            controller.show()
            animator.start()
            applyAnimationState(settings.manualState, bubble: "Ready")

        case .failure(let error):
            presentError(error.localizedDescription)
        }
    }

    private func startAccessibilityObserver() {
        axObserver?.stop()
        axObserver = CodexAccessibilityObserver { [weak self] observedText in
            guard let self, self.settings.stateDetectionEnabled else { return }
            guard AXPermissionManager.isTrusted else {
                self.applyAnimationState(self.settings.manualState, bubble: "AX permission needed")
                return
            }
            guard let observedText, !observedText.isEmpty else {
                self.applyAnimationState(.idle, bubble: "Codex idle")
                return
            }
            let state = self.stateDetector?.detect(in: observedText) ?? .idle
            self.applyAnimationState(state, bubble: state.statusBubble)
        }
        axObserver?.start()
    }

    private func applyAnimationState(_ state: AnimationState, bubble: String) {
        DispatchQueue.main.async {
            self.overlayController?.spriteView.animationState = state
            self.overlayController?.spriteView.statusText = bubble
        }
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Codex Pet Overlay could not start"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
    }

    @objc private func showSettings(_ sender: Any?) {
        if settingsWindow == nil {
            let view = SettingsView(settings: settings) { [weak self] in
                AXPermissionManager.requestPermission()
                self?.startAccessibilityObserver()
            }
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 460, height: 430),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Codex Pet Overlay Settings"
            window.contentViewController = NSHostingController(rootView: view)
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func disableClickThrough(_ sender: Any?) {
        settings.clickThrough = false
        overlayController?.applySettings()
    }
}
