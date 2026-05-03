import Foundation

struct StateRuleFile: Decodable {
    let rules: [StateRule]
}

struct StateRule: Decodable {
    let state: String
    let matchAny: [String]
}

struct CodexDetectionDetails {
    let state: AnimationState
    let matchedRule: String?
    let matchedText: String?
    let reason: String
}

final class CodexStateDetector {
    private let rules: [StateRule]

    init(configURL: URL?) {
        guard let configURL,
              let data = try? Data(contentsOf: configURL),
              let file = try? JSONDecoder().decode(StateRuleFile.self, from: data) else {
            rules = []
            return
        }
        rules = file.rules
    }

    func detect(in text: String) -> CodexDetectionDetails {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return CodexDetectionDetails(
                state: .idle,
                matchedRule: nil,
                matchedText: nil,
                reason: "No observed Codex text"
            )
        }

        guard !rules.isEmpty else {
            return CodexDetectionDetails(
                state: .idle,
                matchedRule: nil,
                matchedText: nil,
                reason: "No state rules loaded"
            )
        }

        let haystack = text.lowercased()
        for rule in rules {
            if let match = rule.matchAny.first(where: { haystack.contains($0.lowercased()) }) {
                let state = animationState(for: rule.state)
                return CodexDetectionDetails(
                    state: state,
                    matchedRule: "\(rule.state): \(match)",
                    matchedText: matchedLine(in: text, containing: match),
                    reason: "Matched configured state rule"
                )
            }
        }
        return CodexDetectionDetails(
            state: .idle,
            matchedRule: nil,
            matchedText: nil,
            reason: "No configured state rule matched"
        )
    }

    private func animationState(for ruleState: String) -> AnimationState {
        switch ruleState {
        case "working":
            return .waiting
        case "reviewing":
            return .review
        case "failed":
            return .failed
        case "idle":
            return .idle
        default:
            return AnimationState(rawValue: ruleState) ?? .idle
        }
    }

    private func matchedLine(in text: String, containing match: String) -> String? {
        let needle = match.lowercased()
        return text
            .components(separatedBy: .newlines)
            .first { $0.lowercased().contains(needle) }?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
