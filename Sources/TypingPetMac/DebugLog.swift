import Foundation

/// Temporary diagnostic logger — writes to Application Support so we can
/// tail it regardless of whether the app was launched via `open` or Finder.
enum DebugLog {
    private static let path = Settings.dataDir.appendingPathComponent("debug.log")

    static func write(_ message: String) {
        try? FileManager.default.createDirectory(at: Settings.dataDir, withIntermediateDirectories: true)
        let line = "\(Date()) \(message)\n"
        if let handle = try? FileHandle(forWritingTo: path) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            try? handle.close()
        } else {
            try? line.data(using: .utf8)!.write(to: path)
        }
    }
}
