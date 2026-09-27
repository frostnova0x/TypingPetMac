import Foundation

enum ImageStore {
    static let maxPatterns = 10

    private static func customPath(_ slot: String) -> URL {
        Settings.dataDir.appendingPathComponent("custom/\(slot).png")
    }

    static func hasCustom(_ slot: String) -> Bool {
        FileManager.default.fileExists(atPath: customPath(slot).path)
    }

    static func hasBundledDefault(_ slot: String) -> Bool {
        Bundle.module.url(forResource: slot, withExtension: "png", subdirectory: "images") != nil
    }

    /// Returns nil when the public build ships with no bundled character art
    /// and the person hasn't picked their own images yet.
    static func defaultBytes(_ slot: String) -> Data? {
        guard let url = Bundle.module.url(forResource: slot, withExtension: "png", subdirectory: "images") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    static func currentBytes(_ slot: String) -> Data? {
        if hasCustom(slot), let data = try? Data(contentsOf: customPath(slot)) {
            return data
        }
        return defaultBytes(slot)
    }

    /// Falls back to a generated placeholder when neither a custom image nor
    /// a bundled default exists, so the app always has something to show.
    static func load(_ slot: String) -> PetImage {
        guard let bytes = currentBytes(slot) else {
            return PetImage.placeholder()
        }
        return PetImage.decode(bytes)
    }

    static func isPlaceholder(_ slot: String) -> Bool {
        !hasCustom(slot) && !hasBundledDefault(slot)
    }

    static func setCustom(_ slot: String, sourceFile: URL) throws {
        let data = try Data(contentsOf: sourceFile)
        try FileManager.default.createDirectory(at: customPath(slot).deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: customPath(slot), options: .atomic)
    }

    static func clearCustom(_ slot: String) {
        try? FileManager.default.removeItem(at: customPath(slot))
    }

    private static func patternCustomPath(_ index: Int) -> URL {
        Settings.dataDir.appendingPathComponent("custom/pattern\(index).png")
    }

    static func hasCustomPattern(_ index: Int) -> Bool {
        FileManager.default.fileExists(atPath: patternCustomPath(index).path)
    }

    static func patternDefaultBytes(_ index: Int) -> Data? {
        let slot = "pattern\(index + 1)"
        return defaultBytes(slot) ?? defaultBytes("pattern1")
    }

    static func patternCurrentBytes(_ index: Int) -> Data? {
        if hasCustomPattern(index), let data = try? Data(contentsOf: patternCustomPath(index)) {
            return data
        }
        return patternDefaultBytes(index)
    }

    static func loadPattern(_ index: Int) -> PetImage {
        guard let bytes = patternCurrentBytes(index) else { return PetImage.placeholder() }
        return PetImage.decode(bytes)
    }

    static func setCustomPattern(_ index: Int, sourceFile: URL) throws {
        let data = try Data(contentsOf: sourceFile)
        try FileManager.default.createDirectory(at: patternCustomPath(index).deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: patternCustomPath(index), options: .atomic)
    }

    static func clearCustomPattern(_ index: Int) {
        try? FileManager.default.removeItem(at: patternCustomPath(index))
    }
}
