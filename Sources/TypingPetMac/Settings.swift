import Foundation

enum PetOptions {
    static let scales: [Double] = [0.25, 0.35, 0.5, 0.7]
    static let shakeFactors: [Double] = [0.0, 0.4, 0.7, 1.0]
}

enum TopMostMode: Int, Codable, CaseIterable, Hashable {
    case off = 0
    case on = 1
    case onIncludingFullscreen = 2

    var label: String {
        switch self {
        case .off: return "Off"
        case .on: return "On"
        case .onIncludingFullscreen: return "On (Include Fullscreen)"
        }
    }
}

final class Settings: Codable {
    var left: Double = .nan
    var top: Double = .nan
    var scale: Double = 0.35
    var topMostMode: TopMostMode = .on
    var locked: Bool = false
    var shake: Int = 3
    var showInDock: Bool = false
    var welcomed: Bool = false

    init() {}

    static var dataDir: URL {
        if let override = ProcessInfo.processInfo.environment["TYPINGPET_DATA"] {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("TypingPetMac", isDirectory: true)
    }

    private static var filePath: URL { dataDir.appendingPathComponent("settings.json") }

    // Manual Codable conformance: every field is decoded with a fallback
    // default, so adding a new setting later never invalidates an existing
    // settings.json (synthesized Codable would fail the whole decode, and
    // therefore silently reset every saved preference, if a single key were
    // missing from an older file).
    private enum CodingKeys: String, CodingKey {
        case left, top, scale, topMostMode, locked, shake, showInDock, welcomed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Settings.defaults
        left = try c.decodeIfPresent(Double.self, forKey: .left) ?? defaults.left
        top = try c.decodeIfPresent(Double.self, forKey: .top) ?? defaults.top
        scale = try c.decodeIfPresent(Double.self, forKey: .scale) ?? defaults.scale
        topMostMode = try c.decodeIfPresent(TopMostMode.self, forKey: .topMostMode) ?? defaults.topMostMode
        locked = try c.decodeIfPresent(Bool.self, forKey: .locked) ?? defaults.locked
        shake = try c.decodeIfPresent(Int.self, forKey: .shake) ?? defaults.shake
        showInDock = try c.decodeIfPresent(Bool.self, forKey: .showInDock) ?? defaults.showInDock
        welcomed = try c.decodeIfPresent(Bool.self, forKey: .welcomed) ?? defaults.welcomed
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(left, forKey: .left)
        try c.encode(top, forKey: .top)
        try c.encode(scale, forKey: .scale)
        try c.encode(topMostMode, forKey: .topMostMode)
        try c.encode(locked, forKey: .locked)
        try c.encode(shake, forKey: .shake)
        try c.encode(showInDock, forKey: .showInDock)
        try c.encode(welcomed, forKey: .welcomed)
    }

    private static let defaults = Settings()

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return encoder
    }

    static func load() -> Settings {
        guard let data = try? Data(contentsOf: filePath),
              let settings = try? makeDecoder().decode(Settings.self, from: data) else {
            return Settings()
        }
        settings.shake = max(0, min(PetOptions.shakeFactors.count - 1, settings.shake))
        return settings
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: Settings.dataDir, withIntermediateDirectories: true)
            let data = try Settings.makeEncoder().encode(self)
            try data.write(to: Settings.filePath, options: .atomic)
        } catch {
            // best-effort persistence, matches original silent-failure behavior
        }
    }
}
