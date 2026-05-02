import Foundation

enum AnimationState: String, CaseIterable, Identifiable, Codable {
    case idle
    case runningRight = "running-right"
    case runningLeft = "running-left"
    case running
    case waiting
    case waving
    case jumping
    case failed
    case review

    var id: String { rawValue }

    var rowIndex: Int {
        switch self {
        case .idle: return 0
        case .runningRight: return 1
        case .runningLeft: return 2
        case .running: return 3
        case .waiting: return 4
        case .waving: return 5
        case .jumping: return 6
        case .failed: return 7
        case .review: return 8
        }
    }

    var displayName: String {
        switch self {
        case .runningRight: return "running right"
        case .runningLeft: return "running left"
        default: return rawValue
        }
    }

    var statusBubble: String {
        switch self {
        case .idle: return "Idle"
        case .review: return "Reviewing"
        case .waiting: return "Working"
        case .failed: return "Needs attention"
        default: return displayName.capitalized
        }
    }
}
