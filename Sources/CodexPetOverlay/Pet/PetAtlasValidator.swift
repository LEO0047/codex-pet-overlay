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
    case missingBundledAsset

    var errorDescription: String? {
        switch self {
        case .missingSpritesheet(let path):
            return "Missing spritesheet at \(path)."
        case .unreadableImage(let path):
            return "Unable to read spritesheet at \(path)."
        case .invalidAtlas(let message):
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
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return PetAtlasValidation(width: 0, height: 0, isValid: false, message: "Unable to inspect spritesheet dimensions.")
        }

        let valid = width == expectedWidth && height == expectedHeight
        let message = valid
            ? "Valid Codex pet atlas."
            : """
            Selected pet folder does not match the expected Lucy v2 atlas contract.
            Expected: \(expectedWidth)x\(expectedHeight), \(columns) columns x \(rows) rows, \(cellWidth)x\(cellHeight) cells.
            Actual: \(width)x\(height).
            """

        return PetAtlasValidation(width: width, height: height, isValid: valid, message: message)
    }
}
