import AppKit
import Foundation

struct SpriteAtlas {
    let image: NSImage
    let imageSize: CGSize
    let columns: Int = 8
    let rows: Int = 9
    let cellSize = CGSize(width: 192, height: 208)

    init(imageURL: URL) throws {
        let validation = PetAtlasValidator.validate(imageURL: imageURL)
        guard validation.isValid else {
            throw PetLoadError.invalidAtlas(validation.message)
        }
        guard let image = NSImage(contentsOf: imageURL) else {
            throw PetLoadError.unreadableImage(imageURL.path)
        }
        self.image = image
        self.imageSize = CGSize(width: validation.width, height: validation.height)
    }

    func sourceRect(state: AnimationState, frameIndex: Int) -> NSRect {
        let clampedFrame = max(0, min(columns - 1, frameIndex))
        let x = CGFloat(clampedFrame) * cellSize.width
        let y = imageSize.height - (CGFloat(state.rowIndex + 1) * cellSize.height)
        return NSRect(x: x, y: y, width: cellSize.width, height: cellSize.height)
    }
}
