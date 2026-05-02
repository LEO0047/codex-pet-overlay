// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "codex-pet-overlay",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexPetOverlay", targets: ["CodexPetOverlay"])
    ],
    targets: [
        .executableTarget(
            name: "CodexPetOverlay",
            path: "Sources/CodexPetOverlay"
        )
    ]
)
