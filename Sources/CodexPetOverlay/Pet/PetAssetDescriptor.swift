import Foundation

enum PetAssetKind: String {
    case overlayHighResAtlas = "codex-pet-overlay-highres-atlas"
    case codexCompatibleAtlas = "codex-compatible-atlas"

    var displayName: String {
        switch self {
        case .overlayHighResAtlas:
            return "Overlay high-res atlas"
        case .codexCompatibleAtlas:
            return "Codex-compatible atlas"
        }
    }
}

struct PetAssetDescriptor {
    let kind: PetAssetKind
    let spritesheetURL: URL
    let manifestURL: URL?
    let columns: Int
    let rows: Int
    let cellWidth: Int
    let cellHeight: Int
    let sourceScale: Double
    let defaultDisplayScale: Double
    let width: Int?
    let height: Int?
    let stateRowMap: [AnimationState: Int]?
    let frameCounts: [AnimationState: Int]
    let chromaKey: ChromaKey?
    let sourceName: String

    var expectedWidth: Int { width ?? columns * cellWidth }
    var expectedHeight: Int { height ?? rows * cellHeight }

    var displaySummary: String {
        "\(kind.displayName) - \(cellWidth)x\(cellHeight) cells, \(columns)x\(rows), source \(sourceScale)x, display \(defaultDisplayScale)x"
    }

    static func manifestKind(at manifestURL: URL) throws -> PetAssetKind? {
        let data = try Data(contentsOf: manifestURL)
        let probe = try JSONDecoder().decode(ManifestKindProbe.self, from: data)
        guard let kind = probe.kind else { return nil }
        return PetAssetKind(rawValue: kind)
    }

    static func overlayHighResAtlas(manifestURL: URL) throws -> PetAssetDescriptor {
        let manifest: OverlayHighResManifest
        do {
            let data = try Data(contentsOf: manifestURL)
            manifest = try JSONDecoder().decode(OverlayHighResManifest.self, from: data)
        } catch {
            throw PetLoadError.invalidManifest("Unable to read overlay manifest at \(manifestURL.path): \(error.localizedDescription)")
        }

        guard manifest.kind == PetAssetKind.overlayHighResAtlas.rawValue else {
            throw PetLoadError.invalidManifest("Unsupported overlay manifest kind at \(manifestURL.path): \(manifest.kind).")
        }

        try validatePositive("columns", manifest.columns, manifestURL: manifestURL)
        try validatePositive("rows", manifest.rows, manifestURL: manifestURL)
        try validatePositive("cellWidth", manifest.cellWidth, manifestURL: manifestURL)
        try validatePositive("cellHeight", manifest.cellHeight, manifestURL: manifestURL)
        try validatePositive("sourceScale", manifest.sourceScale, manifestURL: manifestURL)
        try validatePositive("defaultDisplayScale", manifest.defaultDisplayScale, manifestURL: manifestURL)

        guard !manifest.stateRowMap.isEmpty else {
            throw PetLoadError.invalidManifest("Overlay manifest must declare stateRowMap at \(manifestURL.path).")
        }

        var stateRows: [AnimationState: Int] = [:]
        for (rawState, row) in manifest.stateRowMap {
            guard row >= 0 && row < manifest.rows else {
                throw PetLoadError.invalidManifest("stateRowMap.\(rawState) row \(row) is outside 0..<\(manifest.rows) in \(manifestURL.path).")
            }
            guard let state = AnimationState(rawValue: rawState) else { continue }
            stateRows[state] = row
        }

        guard stateRows[.idle] != nil else {
            throw PetLoadError.invalidManifest("Overlay manifest must map the idle state at \(manifestURL.path).")
        }

        var frameCounts: [AnimationState: Int] = [:]
        for detail in manifest.rowsDetail ?? [] {
            guard let state = AnimationState(rawValue: detail.state) else { continue }
            if let mappedRow = stateRows[state], mappedRow != detail.row {
                throw PetLoadError.invalidManifest("rows_detail for \(detail.state) uses row \(detail.row), but stateRowMap uses row \(mappedRow) in \(manifestURL.path).")
            }
            frameCounts[state] = min(max(1, detail.frames), manifest.columns)
        }

        return PetAssetDescriptor(
            kind: .overlayHighResAtlas,
            spritesheetURL: resolveSpritesheetURL(manifest: manifest, manifestURL: manifestURL),
            manifestURL: manifestURL,
            columns: manifest.columns,
            rows: manifest.rows,
            cellWidth: manifest.cellWidth,
            cellHeight: manifest.cellHeight,
            sourceScale: manifest.sourceScale,
            defaultDisplayScale: manifest.defaultDisplayScale,
            width: manifest.width,
            height: manifest.height,
            stateRowMap: stateRows,
            frameCounts: frameCounts,
            chromaKey: try ChromaKey(manifest: manifest, manifestURL: manifestURL),
            sourceName: manifestURL.path
        )
    }

    static func codexCompatibleAtlas(imageURL: URL, sourceName: String) -> PetAssetDescriptor {
        PetAssetDescriptor(
            kind: .codexCompatibleAtlas,
            spritesheetURL: imageURL,
            manifestURL: nil,
            columns: PetAtlasValidator.columns,
            rows: PetAtlasValidator.rows,
            cellWidth: PetAtlasValidator.cellWidth,
            cellHeight: PetAtlasValidator.cellHeight,
            sourceScale: 1.0,
            defaultDisplayScale: 2.0,
            width: PetAtlasValidator.expectedWidth,
            height: PetAtlasValidator.expectedHeight,
            stateRowMap: nil,
            frameCounts: [:],
            chromaKey: nil,
            sourceName: sourceName
        )
    }

    func rowIndex(for state: AnimationState) -> Int {
        guard let stateRowMap else { return state.rowIndex }
        return stateRowMap[state] ?? stateRowMap[.idle] ?? 0
    }

    func frameCount(for state: AnimationState) -> Int {
        if stateRowMap?[state] == nil, let idleCount = frameCounts[.idle] {
            return idleCount
        }
        return frameCounts[state] ?? columns
    }

    private static func resolveSpritesheetURL(manifest: OverlayHighResManifest, manifestURL: URL) -> URL {
        let manifestDirectory = manifestURL.deletingLastPathComponent()
        var candidates: [URL] = []

        if let spritesheet = manifest.spritesheet {
            candidates.append(resolvePath(spritesheet, relativeTo: manifestDirectory))
        }
        candidates.append(manifestDirectory.appendingPathComponent("spritesheet.webp"))
        if let webp = manifest.outputs?.webp {
            candidates.append(resolvePath(webp, relativeTo: manifestDirectory))
        }
        if let png = manifest.outputs?.png {
            candidates.append(resolvePath(png, relativeTo: manifestDirectory))
        }

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
            ?? candidates[0]
    }

    private static func resolvePath(_ path: String, relativeTo baseURL: URL) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }
        return baseURL.appendingPathComponent(path)
    }

    private static func validatePositive(_ label: String, _ value: Int, manifestURL: URL) throws {
        guard value > 0 else {
            throw PetLoadError.invalidManifest("\(label) must be positive in \(manifestURL.path).")
        }
    }

    private static func validatePositive(_ label: String, _ value: Double, manifestURL: URL) throws {
        guard value.isFinite && value > 0 else {
            throw PetLoadError.invalidManifest("\(label) must be positive in \(manifestURL.path).")
        }
    }
}

struct ChromaKey {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let threshold: Int

    fileprivate init?(manifest: OverlayHighResManifest, manifestURL: URL) throws {
        guard let rawRGB = manifest.chromaKeyRGB else {
            return nil
        }

        guard rawRGB.count == 3 else {
            throw PetLoadError.invalidManifest("chroma_key_rgb must contain exactly three RGB values in \(manifestURL.path).")
        }

        let clampedRGB = try rawRGB.map { value -> UInt8 in
            guard (0...255).contains(value) else {
                throw PetLoadError.invalidManifest("chroma_key_rgb values must be between 0 and 255 in \(manifestURL.path).")
            }
            return UInt8(value)
        }

        guard let threshold = manifest.chromaThreshold else {
            return nil
        }

        guard threshold >= 0 else {
            throw PetLoadError.invalidManifest("chroma_threshold must be non-negative in \(manifestURL.path).")
        }

        self.red = clampedRGB[0]
        self.green = clampedRGB[1]
        self.blue = clampedRGB[2]
        self.threshold = threshold
    }
}

fileprivate struct ManifestKindProbe: Decodable {
    let kind: String?
}

fileprivate struct OverlayHighResManifest: Decodable {
    let kind: String
    let sourceScale: Double
    let defaultDisplayScale: Double
    let columns: Int
    let rows: Int
    let cellWidth: Int
    let cellHeight: Int
    let width: Int?
    let height: Int?
    let stateRowMap: [String: Int]
    let outputs: ManifestOutputs?
    let rowsDetail: [ManifestRowDetail]?
    let spritesheet: String?
    let chromaKeyRGB: [Int]?
    let chromaThreshold: Int?

    enum CodingKeys: String, CodingKey {
        case kind
        case sourceScale
        case defaultDisplayScale
        case columns
        case rows
        case cellWidth
        case cellHeight
        case width
        case height
        case stateRowMap
        case outputs
        case rowsDetail = "rows_detail"
        case spritesheet
        case chromaKeyRGB = "chroma_key_rgb"
        case chromaThreshold = "chroma_threshold"
    }
}

fileprivate struct ManifestOutputs: Decodable {
    let png: String?
    let webp: String?
}

fileprivate struct ManifestRowDetail: Decodable {
    let state: String
    let row: Int
    let frames: Int
}
