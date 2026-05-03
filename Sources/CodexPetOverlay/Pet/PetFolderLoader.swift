import Foundation

final class PetFolderLoader {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadPet(settings: AppSettings) -> Result<SpriteAtlas, PetLoadError> {
        loadPet(petFolderPath: settings.petFolderPath)
    }

    func loadPet(petFolderPath: String) -> Result<SpriteAtlas, PetLoadError> {
        do {
            let descriptor = try resolveDescriptor(petFolderPath: petFolderPath)
            return .success(try SpriteAtlas(descriptor: descriptor))
        } catch let error as PetLoadError {
            return .failure(error)
        } catch {
            return .failure(.invalidManifest(error.localizedDescription))
        }
    }

    private func resolveDescriptor(petFolderPath: String) throws -> PetAssetDescriptor {
        let trimmedPath = petFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else {
            return try bundledLucyDescriptor()
        }
        return try selectedFolderDescriptor(folderURL: URL(fileURLWithPath: trimmedPath, isDirectory: true))
    }

    private func selectedFolderDescriptor(folderURL: URL) throws -> PetAssetDescriptor {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw PetLoadError.missingPetAsset("Selected pet folder does not exist: \(folderURL.path).")
        }

        let overlayManifestURL = folderURL.appendingPathComponent("overlay-highres/2x/manifest.json")
        if fileManager.fileExists(atPath: overlayManifestURL.path) {
            return try PetAssetDescriptor.overlayHighResAtlas(manifestURL: overlayManifestURL)
        }

        let rootManifestURL = folderURL.appendingPathComponent("manifest.json")
        if fileManager.fileExists(atPath: rootManifestURL.path),
           (try? PetAssetDescriptor.manifestKind(at: rootManifestURL)) == .overlayHighResAtlas {
            return try PetAssetDescriptor.overlayHighResAtlas(manifestURL: rootManifestURL)
        }

        let spritesheetURL = folderURL.appendingPathComponent("spritesheet.webp")
        if fileManager.fileExists(atPath: spritesheetURL.path) {
            return PetAssetDescriptor.codexCompatibleAtlas(
                imageURL: spritesheetURL,
                sourceName: "Selected pet folder"
            )
        }

        throw PetLoadError.missingPetAsset("""
        No usable pet asset was found in \(folderURL.path).
        Expected overlay-highres/2x/manifest.json, a root manifest.json with kind codex-pet-overlay-highres-atlas, or spritesheet.webp.
        """)
    }

    private func bundledLucyDescriptor() throws -> PetAssetDescriptor {
        if let bundledOverlayManifestURL = Bundle.main.resourceURL?.appendingPathComponent("output/lucy-v2/run/overlay-highres/2x/manifest.json"),
           fileManager.fileExists(atPath: bundledOverlayManifestURL.path) {
            return try PetAssetDescriptor.overlayHighResAtlas(manifestURL: bundledOverlayManifestURL)
        }

        guard let bundledSpritesheetURL = Bundle.main.resourceURL?.appendingPathComponent("Assets/lucy-v2/spritesheet.webp") else {
            throw PetLoadError.missingBundledAsset
        }

        guard fileManager.fileExists(atPath: bundledSpritesheetURL.path) else {
            throw PetLoadError.missingSpritesheet(bundledSpritesheetURL.path)
        }

        return PetAssetDescriptor.codexCompatibleAtlas(
            imageURL: bundledSpritesheetURL,
            sourceName: "Bundled Lucy v2"
        )
    }
}
