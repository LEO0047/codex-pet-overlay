import Foundation

struct StateRuleFile: Decodable {
    let rules: [StateRule]
}

struct StateRule: Decodable {
    let state: String
    let matchAny: [String]
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

    func detect(in text: String) -> AnimationState {
        let haystack = text.lowercased()
        for rule in rules {
            if rule.matchAny.contains(where: { haystack.contains($0.lowercased()) }) {
                switch rule.state {
                case "working":
                    return .waiting
                case "reviewing":
                    return .review
                case "failed":
                    return .failed
                case "idle":
                    return .idle
                default:
                    return AnimationState(rawValue: rule.state) ?? .idle
                }
            }
        }
        return .idle
    }
}
