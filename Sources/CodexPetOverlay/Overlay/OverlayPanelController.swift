import AppKit

final class OverlayPanelController {
    let spriteView: SpriteOverlayView
    private let settings: AppSettings
    private let panel: NSPanel

    init(spriteView: SpriteOverlayView, settings: AppSettings) {
        self.spriteView = spriteView
        self.settings = settings
        self.panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: spriteView.frame.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configurePanel()
    }

    func show() {
        applySettings()
        panel.orderFrontRegardless()
    }

    func applySettings() {
        panel.ignoresMouseEvents = settings.clickThrough
        panel.level = settings.windowLevel.nsWindowLevel
        panel.setContentSize(spriteView.frame.size)
        panel.setFrameOrigin(clampedOrigin())
    }

    private func configurePanel() {
        panel.title = "Codex Pet Overlay"
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = spriteView
    }

    private func clampedOrigin() -> NSPoint {
        let saved = NSPoint(x: settings.windowOriginX, y: settings.windowOriginY)
        let frame = NSRect(origin: saved, size: spriteView.frame.size)
        let visibleFrames = NSScreen.screens.map(\.visibleFrame)

        if visibleFrames.contains(where: { $0.intersects(frame) }) {
            return saved
        }

        let primary = NSScreen.main?.visibleFrame ?? NSRect(x: 80, y: 80, width: 1200, height: 800)
        let fallback = NSPoint(
            x: primary.maxX - spriteView.frame.width - 48,
            y: primary.minY + 120
        )
        settings.windowOriginX = Double(fallback.x)
        settings.windowOriginY = Double(fallback.y)
        return fallback
    }
}
