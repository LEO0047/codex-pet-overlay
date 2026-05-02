import Foundation

final class PetFolderLoader {
    func loadPet(settings: AppSettings) -> Result<SpriteAtlas, PetLoadError> {
        let imageURL: URL

        if settings.petFolderPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let bundled = Bundle.main.resourceURL?.appendingPathComponent("Assets/lucy-v2/spritesheet.webp") else {
                return .failure(.missingBundledAsset)
            }
            imageURL = bundled
        } else {
            imageURL = URL(fileURLWithPath: settings.petFolderPath).appendingPathComponent("spritesheet.webp")
        }

        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            return .failure(.missingSpritesheet(imageURL.path))
        }

        do {
            return .success(try SpriteAtlas(imageURL: imageURL))
        } catch let error as PetLoadError {
            return .failure(error)
        } catch {
            return .failure(.unreadableImage(imageURL.path))
        }
    }
}
