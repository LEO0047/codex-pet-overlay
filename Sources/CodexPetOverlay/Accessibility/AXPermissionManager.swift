import ApplicationServices
import Foundation

enum AXPermissionManager {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
