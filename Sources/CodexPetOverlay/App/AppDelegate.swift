import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private let petLoader = PetFolderLoader()
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

        let resetPositionItem = NSMenuItem(title: "Reset Position", action: #selector(resetOverlayPosition), keyEquivalent: "r")
        resetPositionItem.target = self
        menu.addItem(resetPositionItem)

        let pauseTitle = animator?.isPaused == true ? "Resume Animation" : "Pause Animation"
        let pauseItem = NSMenuItem(title: pauseTitle, action: #selector(toggleAnimationPause), keyEquivalent: "p")
        pauseItem.target = self
        menu.addItem(pauseItem)
    }

    private func loadStateDetector() {
        let configURL = Bundle.main.resourceURL?.appendingPathComponent("config/state-rules.json")
        stateDetector = CodexStateDetector(configURL: configURL)
    }

    private func launchOverlay() {
        guard let atlas = loadInitialAtlas() else { return }
        settings.updateCurrentAssetStatus(atlas)
        settings.applyDefaultDisplayScaleIfUnset(atlas.defaultDisplayScale)

        let spriteView = SpriteOverlayView(atlas: atlas, settings: settings)
        let controller = OverlayPanelController(spriteView: spriteView, settings: settings)
        let animator = SpriteAnimator { [weak spriteView] frameIndex in
            spriteView?.frameIndex = frameIndex
        }

        configureSpriteViewCallbacks(spriteView)
        settings.onChange = { [weak self, weak spriteView, weak controller] in
            spriteView?.scale = self?.settings.scale ?? 2.0
            spriteView?.showsStatusBubble = self?.settings.showStatusBubble ?? true
            controller?.applySettings()
            if self?.settings.stateDetectionEnabled == false {
                let state = self?.settings.manualState ?? .idle
                self?.applyAnimationState(state, bubble: state.displayName)
            }
        }

        self.overlayController = controller
        self.animator = animator
        controller.show()
        animator.start()
        applyAnimationState(settings.manualState, bubble: "Ready")
    }

    private func loadInitialAtlas() -> SpriteAtlas? {
        switch petLoader.loadPet(settings: settings) {
        case .success(let atlas):
            settings.updateAssetLoadError(nil)
            return atlas
        case .failure(let error):
            settings.updateAssetLoadError(error.localizedDescription)
            let selectedPath = settings.petFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !selectedPath.isEmpty else {
                presentError(error.localizedDescription)
                return nil
            }

            switch petLoader.loadPet(petFolderPath: "") {
            case .success(let fallbackAtlas):
                return fallbackAtlas
            case .failure(let fallbackError):
                presentError("""
                \(error.localizedDescription)

                Bundled Lucy v2 fallback also failed:
                \(fallbackError.localizedDescription)
                """)
                return nil
            }
        }
    }

    private func configureSpriteViewCallbacks(_ spriteView: SpriteOverlayView) {
        spriteView.onManualStateSelected = { [weak self] state in
            self?.selectManualAnimation(state)
        }
        spriteView.onOpenSettings = { [weak self] in
            self?.showSettings(nil)
        }
        spriteView.onDisableClickThrough = { [weak self] in
            self?.disableClickThrough(nil)
        }
        spriteView.onResetPosition = { [weak self] in
            self?.resetOverlayPosition(nil)
        }
        spriteView.isAnimationPaused = { [weak self] in
            self?.animator?.isPaused ?? false
        }
        spriteView.onToggleAnimationPause = { [weak self] in
            self?.toggleAnimationPause(nil)
        }
        spriteView.onQuit = {
            NSApp.terminate(nil)
        }
    }

    private func startAccessibilityObserver() {
        axObserver?.stop()
        axObserver = CodexAccessibilityObserver { [weak self] observation in
            self?.handleCodexObservation(observation)
        }
        axObserver?.start()
    }

    private func handleCodexObservation(_ observation: CodexAccessibilityObservation) {
        switch observation.status {
        case .axPermissionNeeded:
            settings.updateCodexDetectionStatus(.axPermissionNeeded, details: nil)
            guard settings.stateDetectionEnabled else { return }
            applyAnimationState(settings.manualState, bubble: "AX permission needed")

        case .codexNotRunning:
            settings.updateCodexDetectionStatus(.codexNotRunning, details: nil)
            guard settings.stateDetectionEnabled else { return }
            applyAnimationState(.idle, bubble: "Codex not running")

        case .observingCodex:
            let details = stateDetector?.detect(in: observation.observedText ?? "")
                ?? CodexDetectionDetails(
                    state: .idle,
                    matchedRule: nil,
                    matchedText: nil,
                    reason: "No state detector available"
                )
            settings.updateCodexDetectionStatus(.observingCodex, details: details)
            guard settings.stateDetectionEnabled else { return }
            applyAnimationState(details.state, bubble: details.state.statusBubble)
        }
    }

    private func applyAnimationState(_ state: AnimationState, bubble: String) {
        DispatchQueue.main.async {
            self.overlayController?.spriteView.animationState = state
            self.overlayController?.spriteView.statusText = bubble
        }
    }

    private func selectManualAnimation(_ state: AnimationState) {
        settings.selectManualAnimation(state)
        applyAnimationState(state, bubble: state.displayName)
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
            let view = SettingsView(
                settings: settings,
                choosePetFolder: { [weak self] in
                    self?.choosePetFolder()
                },
                reloadPet: { [weak self] in
                    self?.reloadPet(nil)
                },
                requestAccessibility: { [weak self] in
                    self?.settings.markAccessibilityPermissionRequested()
                    AXPermissionManager.requestPermission()
                    self?.settings.refreshAccessibilityTrustStatus()
                    self?.startAccessibilityObserver()
                },
                resetPosition: { [weak self] in
                    self?.resetOverlayPosition(nil)
                }
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 700),
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

    private func choosePetFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Pet Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        let selectedPath = settings.petFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !selectedPath.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: selectedPath, isDirectory: true)
        }

        let completion: (NSApplication.ModalResponse) -> Void = { [weak self, panel] response in
            guard response == .OK, let url = panel.url else { return }
            self?.settings.petFolderPath = url.path
        }

        if let settingsWindow {
            panel.beginSheetModal(for: settingsWindow, completionHandler: completion)
        } else {
            completion(panel.runModal())
        }
    }

    @objc private func reloadPet(_ sender: Any?) {
        switch petLoader.loadPet(settings: settings) {
        case .success(let atlas):
            settings.updateAssetLoadError(nil)
            settings.updateCurrentAssetStatus(atlas)
            settings.applyDefaultDisplayScaleIfUnset(atlas.defaultDisplayScale)
            if let controller = overlayController {
                controller.spriteView.replaceAtlas(atlas)
                controller.applySettings()
                let state = controller.spriteView.animationState
                let bubble = settings.stateDetectionEnabled ? state.statusBubble : state.displayName
                applyAnimationState(state, bubble: bubble)
            } else {
                launchOverlay()
            }
        case .failure(let error):
            settings.updateAssetLoadError(error.localizedDescription)
            let state = overlayController?.spriteView.animationState ?? settings.manualState
            applyAnimationState(state, bubble: "Pet reload failed")
        }
    }

    @objc private func disableClickThrough(_ sender: Any?) {
        settings.clickThrough = false
        overlayController?.applySettings()
    }

    @objc private func toggleAnimationPause(_ sender: Any?) {
        guard let animator else { return }
        animator.isPaused.toggle()

        let state = overlayController?.spriteView.animationState ?? settings.manualState
        let bubble = animator.isPaused
            ? "Paused"
            : (settings.stateDetectionEnabled ? state.statusBubble : state.displayName)
        applyAnimationState(state, bubble: bubble)
    }

    @objc private func resetOverlayPosition(_ sender: Any?) {
        overlayController?.resetPosition()
    }
}

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleAnimationPause(_:)) {
            menuItem.title = animator?.isPaused == true ? "Resume Animation" : "Pause Animation"
            return animator != nil
        }
        return true
    }
}
