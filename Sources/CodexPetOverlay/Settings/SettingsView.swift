import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let choosePetFolder: () -> Void
    let reloadPet: () -> Void
    let requestAccessibility: () -> Void
    let resetPosition: () -> Void

    private var manualAnimationBinding: Binding<AnimationState> {
        Binding {
            settings.manualState
        } set: { state in
            settings.selectManualAnimation(state)
        }
    }

    var body: some View {
        Form {
            Section("Pet") {
                TextField("Pet folder path", text: $settings.petFolderPath)
                HStack {
                    Button("Choose Folder...") {
                        choosePetFolder()
                    }
                    Button("Reload Pet") {
                        reloadPet()
                    }
                }
                Text("Leave empty to use bundled Lucy v2.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let status = settings.currentAssetStatus {
                    assetStatus(status)
                } else {
                    Text("Asset not loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = settings.assetLoadErrorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
                Button("Reset Position") {
                    resetPosition()
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
                detailRow("AX status", settings.accessibilityTrustStatus.displayName)
                detailRow("Codex status", settings.codexDetectionStatus.displayName)
                detailRow("Last state", settings.lastDetectedCodexState?.displayName ?? "Unavailable")
                if let rule = settings.lastMatchedCodexRule {
                    detailRow("Last rule", rule)
                }
                if let reason = settings.codexDetectionReason {
                    detailRow("Reason", reason)
                }
                if let matchedText = settings.lastMatchedCodexText {
                    debugText(matchedText)
                }
                Picker("Manual animation", selection: manualAnimationBinding) {
                    ForEach(AnimationState.allCases) { state in
                        Text(state.displayName).tag(state)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 540, height: 700)
    }

    private func assetStatus(_ status: CurrentAssetStatus) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            detailRow("Asset kind", status.kind)
            detailRow("Source path", status.sourcePath)
            if let manifestPath = status.manifestPath {
                detailRow("Manifest", manifestPath)
            }
            detailRow("Cell size", status.cellSize)
            detailRow("Grid", status.gridSize)
            detailRow("Source scale", String(format: "%.1fx", status.sourceScale))
            detailRow("Default scale", String(format: "%.1fx", status.defaultDisplayScale))
            detailRow("Display scale", String(format: "%.1fx", settings.scale))
        }
        .padding(.vertical, 2)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption)
    }

    private func debugText(_ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last matched text")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView {
                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 72)
            .padding(6)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
