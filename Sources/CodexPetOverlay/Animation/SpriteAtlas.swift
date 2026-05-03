import AppKit
import Foundation
import ImageIO

struct SpriteAtlas {
    let imageSize: CGSize
    let columns: Int = 8
    let rows: Int = 9
    let cellSize = CGSize(width: 192, height: 208)
    private let frameImages: [[CGImage]]

    init(imageURL: URL) throws {
        let validation = PetAtlasValidator.validate(imageURL: imageURL)
        guard validation.isValid else {
            throw PetLoadError.invalidAtlas(validation.message)
        }
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, [
                kCGImageSourceShouldCache: true
              ] as CFDictionary) else {
            throw PetLoadError.unreadableImage(imageURL.path)
        }
        self.imageSize = CGSize(width: validation.width, height: validation.height)

        var frames: [[CGImage]] = []
        for row in 0..<rows {
            var rowFrames: [CGImage] = []
            for column in 0..<columns {
                let cropRect = CGRect(
                    x: CGFloat(column) * cellSize.width,
                    y: CGFloat(row) * cellSize.height,
                    width: cellSize.width,
                    height: cellSize.height
                )
                guard let frame = image.cropping(to: cropRect) else {
                    throw PetLoadError.unreadableImage(imageURL.path)
                }
                rowFrames.append(frame)
            }
            frames.append(rowFrames)
        }
        self.frameImages = frames
    }

    func frameImage(state: AnimationState, frameIndex: Int) -> CGImage {
        let clampedFrame = max(0, min(columns - 1, frameIndex))
        return frameImages[state.rowIndex][clampedFrame]
    }
}
