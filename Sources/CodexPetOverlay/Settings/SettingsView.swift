import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let requestAccessibility: () -> Void

    var body: some View {
        Form {
            Section("Pet") {
                TextField("Pet folder path", text: $settings.petFolderPath)
                Text("Leave empty to use bundled Lucy v2.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Overlay") {
                Slider(value: $settings.scale, in: 1.0...4.0, step: 0.1) {
                    Text("Scale")
                }
                Text("Scale: \(settings.scale, specifier: "%.1f")x")
                    .font(.caption)

                Toggle("Click-through", isOn: $settings.clickThrough)
                Button("Disable Click-through") {
                    settings.clickThrough = false
                }

                Toggle("Show status bubble", isOn: $settings.showStatusBubble)
                Picker("Window level", selection: $settings.windowLevel) {
                    ForEach(OverlayWindowLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }

            Section("Codex State") {
                Toggle("Observe Codex with Accessibility", isOn: $settings.stateDetectionEnabled)
                Button("Request Accessibility Permission") {
                    requestAccessibility()
                }
                Picker("Manual animation", selection: $settings.manualState) {
                    ForEach(AnimationState.allCases) { state in
                        Text(state.displayName).tag(state)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 460, height: 430)
    }
}
