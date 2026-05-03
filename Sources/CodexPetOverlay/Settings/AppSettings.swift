import AppKit
import Combine
import Foundation

enum OverlayWindowLevel: String, CaseIterable, Identifiable {
    case normal
    case floating
    case status

    var id: String { rawValue }

    var nsWindowLevel: NSWindow.Level {
        switch self {
        case .normal: return .normal
        case .floating: return .floating
        case .status: return .statusBar
        }
    }
}

enum AccessibilityTrustStatus {
    case trusted
    case notTrusted
    case permissionRequested

    var displayName: String {
        switch self {
        case .trusted: return "Trusted"
        case .notTrusted: return "Not trusted"
        case .permissionRequested: return "Permission requested"
        }
    }
}

enum CodexDetectionDisplayStatus {
    case codexNotRunning
    case axPermissionNeeded
    case observingCodex

    var displayName: String {
        switch self {
        case .codexNotRunning: return "Codex not running"
        case .axPermissionNeeded: return "AX permission needed"
        case .observingCodex: return "Observing Codex"
        }
    }

    var reason: String {
        switch self {
        case .codexNotRunning: return "Codex app is not running"
        case .axPermissionNeeded: return "Accessibility permission is required"
        case .observingCodex: return "Codex UI text is readable"
        }
    }
}

struct CurrentAssetStatus {
    let kind: String
    let sourcePath: String
    let manifestPath: String?
    let cellSize: String
    let gridSize: String
    let sourceScale: Double
    let defaultDisplayScale: Double

    init(atlas: SpriteAtlas) {
        let descriptor = atlas.descriptor
        kind = descriptor.kind.displayName
        sourcePath = descriptor.spritesheetURL.path
        manifestPath = descriptor.manifestURL?.path
        cellSize = "\(descriptor.cellWidth)x\(descriptor.cellHeight)"
        gridSize = "\(descriptor.columns)x\(descriptor.rows)"
        sourceScale = descriptor.sourceScale
        defaultDisplayScale = descriptor.defaultDisplayScale
    }
}

final class AppSettings: ObservableObject {
    var onChange: (() -> Void)?
    private var hasStoredScale: Bool
    private var accessibilityPermissionRequested = false

    @Published private(set) var currentAssetStatus: CurrentAssetStatus?
    @Published private(set) var assetLoadErrorMessage: String?
    @Published private(set) var accessibilityTrustStatus: AccessibilityTrustStatus = .notTrusted
    @Published private(set) var codexDetectionStatus: CodexDetectionDisplayStatus = .codexNotRunning
    @Published private(set) var lastDetectedCodexState: AnimationState?
    @Published private(set) var lastMatchedCodexRule: String?
    @Published private(set) var lastMatchedCodexText: String?
    @Published private(set) var codexDetectionReason: String?

    @Published var petFolderPath: String {
        didSet {
            persist("petFolderPath", petFolderPath)
            assetLoadErrorMessage = nil
        }
    }

    @Published var scale: Double {
        didSet {
            persist("scale", scale)
            onChange?()
        }
    }

    @Published var clickThrough: Bool {
        didSet {
            persist("clickThrough", clickThrough)
            onChange?()
        }
    }

    @Published var showStatusBubble: Bool {
        didSet {
            persist("showStatusBubble", showStatusBubble)
            onChange?()
        }
    }

    @Published var stateDetectionEnabled: Bool {
        didSet {
            persist("stateDetectionEnabled", stateDetectionEnabled)
            onChange?()
        }
    }

    @Published var manualState: AnimationState {
        didSet {
            persist("manualState", manualState.rawValue)
            onChange?()
        }
    }

    @Published var windowLevel: OverlayWindowLevel {
        didSet {
            persist("windowLevel", windowLevel.rawValue)
            onChange?()
        }
    }

    @Published var windowOriginX: Double {
        didSet { persist("windowOriginX", windowOriginX) }
    }

    @Published var windowOriginY: Double {
        didSet { persist("windowOriginY", windowOriginY) }
    }

    init(defaults: UserDefaults = .standard) {
        let storedScale = defaults.object(forKey: "scale") as? Double
        hasStoredScale = storedScale != nil
        petFolderPath = defaults.string(forKey: "petFolderPath") ?? ""
        scale = Self.clampedScale(storedScale ?? 2.0)
        clickThrough = defaults.object(forKey: "clickThrough") as? Bool ?? false
        showStatusBubble = defaults.object(forKey: "showStatusBubble") as? Bool ?? true
        stateDetectionEnabled = defaults.object(forKey: "stateDetectionEnabled") as? Bool ?? true
        manualState = AnimationState(rawValue: defaults.string(forKey: "manualState") ?? "") ?? .idle
        windowLevel = OverlayWindowLevel(rawValue: defaults.string(forKey: "windowLevel") ?? "") ?? .floating
        windowOriginX = defaults.object(forKey: "windowOriginX") as? Double ?? 1280
        windowOriginY = defaults.object(forKey: "windowOriginY") as? Double ?? 180
        refreshAccessibilityTrustStatus()
        updateCodexDetectionStatus(.codexNotRunning, details: nil)
    }

    func save() {
        UserDefaults.standard.synchronize()
    }

    func selectManualAnimation(_ state: AnimationState) {
        stateDetectionEnabled = false
        manualState = state
    }

    func applyDefaultDisplayScaleIfUnset(_ defaultDisplayScale: Double) {
        guard !hasStoredScale else { return }
        scale = Self.clampedScale(defaultDisplayScale)
        hasStoredScale = true
    }

    func updateCurrentAssetStatus(_ atlas: SpriteAtlas) {
        currentAssetStatus = CurrentAssetStatus(atlas: atlas)
    }

    func updateAssetLoadError(_ message: String?) {
        assetLoadErrorMessage = message
    }

    func markAccessibilityPermissionRequested() {
        accessibilityPermissionRequested = true
        refreshAccessibilityTrustStatus()
    }

    func refreshAccessibilityTrustStatus() {
        if AXPermissionManager.isTrusted {
            accessibilityTrustStatus = .trusted
        } else if accessibilityPermissionRequested {
            accessibilityTrustStatus = .permissionRequested
        } else {
            accessibilityTrustStatus = .notTrusted
        }
    }

    func updateCodexDetectionStatus(
        _ status: CodexDetectionDisplayStatus,
        details: CodexDetectionDetails?
    ) {
        refreshAccessibilityTrustStatus()
        codexDetectionStatus = status
        codexDetectionReason = details?.reason ?? status.reason

        guard let details else {
            lastDetectedCodexState = nil
            lastMatchedCodexRule = nil
            lastMatchedCodexText = nil
            return
        }

        lastDetectedCodexState = details.state
        lastMatchedCodexRule = details.matchedRule
        lastMatchedCodexText = Self.sanitizedDebugText(details.matchedText)
    }

    private func persist(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private static func clampedScale(_ value: Double) -> Double {
        min(4.0, max(1.0, value))
    }

    private static func sanitizedDebugText(_ text: String?) -> String? {
        guard let text else { return nil }
        var sanitized = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else { return nil }

        sanitized = sanitized.replacingOccurrences(
            of: "(?i)(api[_ -]?key|token|secret|password)\\s*[:=]\\s*\\S+",
            with: "[REDACTED credential]",
            options: .regularExpression
        )
        sanitized = sanitized.replacingOccurrences(
            of: "(?i)bearer\\s+[A-Za-z0-9._~+/=-]+",
            with: "Bearer [REDACTED]",
            options: .regularExpression
        )

        if sanitized.count > 240 {
            return "\(sanitized.prefix(240))..."
        }
        return sanitized
    }
}
