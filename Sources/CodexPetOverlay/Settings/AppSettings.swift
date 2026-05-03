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

final class AppSettings: ObservableObject {
    var onChange: (() -> Void)?

    @Published var petFolderPath: String {
        didSet { persist("petFolderPath", petFolderPath) }
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
        petFolderPath = defaults.string(forKey: "petFolderPath") ?? ""
        scale = Self.clampedScale(defaults.object(forKey: "scale") as? Double ?? 2.0)
        clickThrough = defaults.object(forKey: "clickThrough") as? Bool ?? false
        showStatusBubble = defaults.object(forKey: "showStatusBubble") as? Bool ?? true
        stateDetectionEnabled = defaults.object(forKey: "stateDetectionEnabled") as? Bool ?? true
        manualState = AnimationState(rawValue: defaults.string(forKey: "manualState") ?? "") ?? .idle
        windowLevel = OverlayWindowLevel(rawValue: defaults.string(forKey: "windowLevel") ?? "") ?? .floating
        windowOriginX = defaults.object(forKey: "windowOriginX") as? Double ?? 1280
        windowOriginY = defaults.object(forKey: "windowOriginY") as? Double ?? 180
    }

    func save() {
        UserDefaults.standard.synchronize()
    }

    private func persist(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private static func clampedScale(_ value: Double) -> Double {
        min(4.0, max(1.0, value))
    }
}
