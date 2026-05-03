import AppKit
import Foundation
import ImageIO

struct SpriteAtlas {
    let descriptor: PetAssetDescriptor
    let imageSize: CGSize
    let columns: Int
    let rows: Int
    let cellSize: CGSize
    private let frameImages: [[CGImage]]

    var assetInfo: String { descriptor.displaySummary }
    var defaultDisplayScale: Double { descriptor.defaultDisplayScale }

    init(descriptor: PetAssetDescriptor) throws {
        guard FileManager.default.fileExists(atPath: descriptor.spritesheetURL.path) else {
            throw PetLoadError.missingSpritesheet(descriptor.spritesheetURL.path)
        }

        let validation = PetAtlasValidator.validate(imageURL: descriptor.spritesheetURL, descriptor: descriptor)
        guard validation.isValid else {
            throw PetLoadError.invalidAtlas(validation.message)
        }

        guard let imageSource = CGImageSourceCreateWithURL(descriptor.spritesheetURL as CFURL, nil),
              let decodedImage = CGImageSourceCreateImageAtIndex(imageSource, 0, [
                kCGImageSourceShouldCache: true
              ] as CFDictionary) else {
            throw PetLoadError.unreadableImage(descriptor.spritesheetURL.path)
        }
        let image = try Self.prepareImage(decodedImage, descriptor: descriptor)

        self.descriptor = descriptor
        self.imageSize = CGSize(width: validation.width, height: validation.height)
        self.columns = descriptor.columns
        self.rows = descriptor.rows
        self.cellSize = CGSize(width: descriptor.cellWidth, height: descriptor.cellHeight)

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
                    throw PetLoadError.unreadableImage(descriptor.spritesheetURL.path)
                }
                rowFrames.append(frame)
            }
            frames.append(rowFrames)
        }
        self.frameImages = frames
    }

    func frameImage(state: AnimationState, frameIndex: Int) -> CGImage {
        let rowIndex = max(0, min(rows - 1, descriptor.rowIndex(for: state)))
        let rowFrames = frameImages[rowIndex]
        let frameCount = max(1, min(rowFrames.count, descriptor.frameCount(for: state)))
        let clampedFrame = max(0, min(frameCount - 1, frameIndex))
        return rowFrames[clampedFrame]
    }

    private static func prepareImage(_ image: CGImage, descriptor: PetAssetDescriptor) throws -> CGImage {
        guard descriptor.kind == .overlayHighResAtlas,
              let chromaKey = descriptor.chromaKey else {
            return image
        }
        return try applyingChromaKey(chromaKey, to: image, imagePath: descriptor.spritesheetURL.path)
    }

    private static func applyingChromaKey(_ chromaKey: ChromaKey, to image: CGImage, imagePath: String) throws -> CGImage {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw PetLoadError.unreadableImage(imagePath)
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let thresholdSquared = chromaKey.threshold * chromaKey.threshold
        for offset in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let red = Int(pixels[offset])
            let green = Int(pixels[offset + 1])
            let blue = Int(pixels[offset + 2])
            let redDelta = red - Int(chromaKey.red)
            let greenDelta = green - Int(chromaKey.green)
            let blueDelta = blue - Int(chromaKey.blue)
            let distanceSquared = redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta
            let isNearManifestKey = distanceSquared <= thresholdSquared
            let isDominantGreenKey = green >= 150 && red <= 100 && blue <= 100 && green - max(red, blue) >= 80
            guard isNearManifestKey || isDominantGreenKey else { continue }

            pixels[offset] = 0
            pixels[offset + 1] = 0
            pixels[offset + 2] = 0
            pixels[offset + 3] = 0
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let keyedImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            throw PetLoadError.unreadableImage(imagePath)
        }

        return keyedImage
    }
}
