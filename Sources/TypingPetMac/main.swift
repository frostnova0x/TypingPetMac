import AppKit
import Foundation

func acquireSingleInstanceLockOrExit() {
    try? FileManager.default.createDirectory(at: Settings.dataDir, withIntermediateDirectories: true)
    let lockPath = Settings.dataDir.appendingPathComponent(".instance.lock").path
    let fd = open(lockPath, O_CREAT | O_RDWR, 0o644)
    guard fd >= 0 else { return }
    if flock(fd, LOCK_EX | LOCK_NB) != 0 {
        FileHandle.standardError.write("Typing Pet is already running.\n".data(using: .utf8)!)
        exit(1)
    }
    // Intentionally leak the fd for the process lifetime; the OS releases the
    // lock automatically on exit.
}

acquireSingleInstanceLockOrExit()

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
