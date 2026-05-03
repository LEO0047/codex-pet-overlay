import Foundation
import ImageIO

struct PetAtlasValidation {
    let width: Int
    let height: Int
    let isValid: Bool
    let message: String
}

enum PetLoadError: LocalizedError {
    case missingSpritesheet(String)
    case unreadableImage(String)
    case invalidAtlas(String)
    case invalidManifest(String)
    case missingPetAsset(String)
    case missingBundledAsset

    var errorDescription: String? {
        switch self {
        case .missingSpritesheet(let path):
            return "Missing spritesheet at \(path)."
        case .unreadableImage(let path):
            return "Unable to read spritesheet at \(path)."
        case .invalidAtlas(let message):
            return message
        case .invalidManifest(let message):
            return message
        case .missingPetAsset(let message):
            return message
        case .missingBundledAsset:
            return "Bundled Lucy v2 asset is missing."
        }
    }
}

struct PetAtlasValidator {
    static let expectedWidth = 1536
    static let expectedHeight = 1872
    static let columns = 8
    static let rows = 9
    static let cellWidth = 192
    static let cellHeight = 208

    static func validate(imageURL: URL) -> PetAtlasValidation {
        guard let dimensions = inspectDimensions(imageURL: imageURL) else {
            return PetAtlasValidation(width: 0, height: 0, isValid: false, message: "Unable to inspect spritesheet dimensions.")
        }

        let valid = dimensions.width == expectedWidth && dimensions.height == expectedHeight
        let message = valid
            ? "Valid Codex pet atlas."
            : """
            Selected pet folder does not match the expected Codex-compatible atlas contract.
            Expected: \(expectedWidth)x\(expectedHeight), \(columns) columns x \(rows) rows, \(cellWidth)x\(cellHeight) cells.
            Actual: \(dimensions.width)x\(dimensions.height).
            """

        return PetAtlasValidation(width: dimensions.width, height: dimensions.height, isValid: valid, message: message)
    }

    static func validate(imageURL: URL, descriptor: PetAssetDescriptor) -> PetAtlasValidation {
        guard descriptor.kind != .codexCompatibleAtlas else {
            return validate(imageURL: imageURL)
        }

        guard let dimensions = inspectDimensions(imageURL: imageURL) else {
            return PetAtlasValidation(width: 0, height: 0, isValid: false, message: "Unable to inspect spritesheet dimensions.")
        }

        let valid = dimensions.width == descriptor.expectedWidth && dimensions.height == descriptor.expectedHeight
        let manifestPath = descriptor.manifestURL?.path ?? "unknown manifest"
        let message = valid
            ? "Valid \(descriptor.kind.displayName)."
            : """
            Overlay asset does not match its manifest contract.
            Manifest: \(manifestPath)
            Spritesheet: \(imageURL.path)
            Expected: \(descriptor.expectedWidth)x\(descriptor.expectedHeight), \(descriptor.columns) columns x \(descriptor.rows) rows, \(descriptor.cellWidth)x\(descriptor.cellHeight) cells.
            Actual: \(dimensions.width)x\(dimensions.height).
            """

        return PetAtlasValidation(width: dimensions.width, height: dimensions.height, isValid: valid, message: message)
    }

    private static func inspectDimensions(imageURL: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        return (width, height)
    }
}
