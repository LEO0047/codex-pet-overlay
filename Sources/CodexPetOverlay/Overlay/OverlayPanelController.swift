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

    func resetPosition() {
        panel.setContentSize(spriteView.frame.size)
        let origin = defaultVisibleOrigin()
        settings.windowOriginX = Double(origin.x)
        settings.windowOriginY = Double(origin.y)
        panel.setFrameOrigin(origin)
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

        let fallback = defaultVisibleOrigin()
        settings.windowOriginX = Double(fallback.x)
        settings.windowOriginY = Double(fallback.y)
        return fallback
    }

    private func defaultVisibleOrigin() -> NSPoint {
        let primary = NSScreen.main?.visibleFrame ?? NSRect(x: 80, y: 80, width: 1200, height: 800)
        let margin: CGFloat = 48
        let targetY = primary.minY + 120
        let x = clamped(
            primary.maxX - spriteView.frame.width - margin,
            lowerBound: primary.minX + margin,
            upperBound: primary.maxX - spriteView.frame.width
        )
        let y = clamped(
            targetY,
            lowerBound: primary.minY + margin,
            upperBound: primary.maxY - spriteView.frame.height
        )
        return NSPoint(x: x, y: y)
    }

    private func clamped(_ value: CGFloat, lowerBound: CGFloat, upperBound: CGFloat) -> CGFloat {
        guard upperBound >= lowerBound else { return lowerBound }
        return min(max(value, lowerBound), upperBound)
    }
}
