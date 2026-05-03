import AppKit

final class SpriteOverlayView: NSView {
    private let atlas: SpriteAtlas
    private let settings: AppSettings
    var onManualStateSelected: ((AnimationState) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onDisableClickThrough: (() -> Void)?

    var frameIndex = 0 {
        didSet { needsDisplay = true }
    }

    var animationState: AnimationState = .idle {
        didSet { needsDisplay = true }
    }

    var scale: Double {
        didSet {
            updateFrameSize()
            needsDisplay = true
        }
    }

    var showsStatusBubble: Bool {
        didSet {
            updateFrameSize()
            needsDisplay = true
        }
    }

    var statusText = "Idle" {
        didSet { needsDisplay = true }
    }

    private var dragStartWindowOrigin: NSPoint?
    private var dragStartMouseLocation: NSPoint?

    init(atlas: SpriteAtlas, settings: AppSettings) {
        self.atlas = atlas
        self.settings = settings
        self.scale = settings.scale
        self.showsStatusBubble = settings.showStatusBubble
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        updateFrameSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { false }

    private func updateFrameSize() {
        let bubbleHeight: CGFloat = showsStatusBubble ? 34 : 0
        frame.size = NSSize(
            width: atlas.cellSize.width * scale,
            height: atlas.cellSize.height * scale + bubbleHeight
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let spriteHeight = atlas.cellSize.height * scale
        let spriteRect = NSRect(
            x: 0,
            y: 0,
            width: atlas.cellSize.width * scale,
            height: spriteHeight
        )
        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.interpolationQuality = .high
            context.draw(atlas.frameImage(state: animationState, frameIndex: frameIndex), in: spriteRect)
            context.restoreGState()
        }

        guard showsStatusBubble else { return }
        drawStatusBubble(above: spriteRect)
    }

    private func drawStatusBubble(above spriteRect: NSRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let text = NSString(string: statusText)
        let size = text.size(withAttributes: attributes)
        let bubbleRect = NSRect(
            x: max(4, bounds.midX - (size.width + 22) / 2),
            y: spriteRect.maxY + 4,
            width: size.width + 22,
            height: 24
        )
        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)
        NSColor(calibratedWhite: 0.08, alpha: 0.82).setFill()
        path.fill()
        text.draw(
            at: NSPoint(x: bubbleRect.minX + 11, y: bubbleRect.minY + 5),
            withAttributes: attributes
        )
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        dragStartWindowOrigin = window.frame.origin
        dragStartMouseLocation = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window,
              let startOrigin = dragStartWindowOrigin,
              let startMouse = dragStartMouseLocation else { return }

        let currentMouse = NSEvent.mouseLocation
        let dx = currentMouse.x - startMouse.x
        let dy = currentMouse.y - startMouse.y
        let newOrigin = NSPoint(x: startOrigin.x + dx, y: startOrigin.y + dy)
        window.setFrameOrigin(newOrigin)
        settings.windowOriginX = Double(newOrigin.x)
        settings.windowOriginY = Double(newOrigin.y)
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Disable Click-through", action: #selector(disableClickThroughFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        for state in AnimationState.allCases {
            let item = NSMenuItem(title: "Animation: \(state.displayName)", action: #selector(selectAnimation(_:)), keyEquivalent: "")
            item.representedObject = state.rawValue
            item.target = self
            menu.addItem(item)
        }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func openSettingsFromMenu() {
        onOpenSettings?()
    }

    @objc private func disableClickThroughFromMenu() {
        onDisableClickThrough?()
    }

    @objc private func selectAnimation(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let state = AnimationState(rawValue: rawValue) else { return }
        onManualStateSelected?(state)
    }
}
