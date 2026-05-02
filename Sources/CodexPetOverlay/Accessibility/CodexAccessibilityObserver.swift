import AppKit
import ApplicationServices

final class CodexAccessibilityObserver {
    private var timer: Timer?
    private let onObservation: (String?) -> Void

    init(onObservation: @escaping (String?) -> Void) {
        self.onObservation = onObservation
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer!, forMode: .common)
        poll()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard AXPermissionManager.isTrusted else {
            onObservation(nil)
            return
        }

        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == "com.openai.codex"
        }
        guard let app = apps.first else {
            onObservation(nil)
            return
        }

        let element = AXUIElementCreateApplication(app.processIdentifier)
        var chunks: [String] = []
        collectText(from: element, depth: 0, chunks: &chunks)
        onObservation(chunks.joined(separator: "\n"))
    }

    private func collectText(from element: AXUIElement, depth: Int, chunks: inout [String]) {
        guard depth < 5, chunks.count < 200 else { return }

        for attribute in [kAXTitleAttribute, kAXValueAttribute, kAXDescriptionAttribute, kAXHelpAttribute] {
            var value: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
               let text = value as? String,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chunks.append(text)
            }
        }

        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue) == .success,
              let children = childrenValue as? [AXUIElement] else { return }

        for child in children.prefix(40) {
            collectText(from: child, depth: depth + 1, chunks: &chunks)
        }
    }
}
