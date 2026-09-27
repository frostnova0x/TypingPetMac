import AppKit
import ImageIO
import UniformTypeIdentifiers

final class PetImage {
    let frames: [NSImage]
    let delaysMs: [Int]

    var animated: Bool { frames.count > 1 }
    var first: NSImage { frames[0] }

    init(single: NSImage) {
        frames = [single]
        delaysMs = [100]
    }

    init(frames: [NSImage], delaysMs: [Int]) {
        self.frames = frames
        self.delaysMs = delaysMs
    }

    private static func normalizeDelay(_ ms: Int) -> Int {
        ms <= 10 ? 100 : ms
    }

    /// Shown when neither a custom image nor a bundled default exists, so the
    /// app never crashes and the person has something to click "Choose Image" on.
    static func placeholder() -> PetImage {
        let size = NSSize(width: 400, height: 400)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.controlBackgroundColor.setFill()
        let bg = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 40, yRadius: 40)
        bg.fill()
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 160, weight: .regular)
        if let symbol = NSImage(systemSymbolName: "photo.badge.plus", accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfig) {
            let rect = NSRect(x: (size.width - 180) / 2, y: (size.height - 180) / 2, width: 180, height: 180)
            NSColor.tertiaryLabelColor.set()
            symbol.isTemplate = true
            symbol.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        image.unlockFocus()
        return PetImage(single: image)
    }

    /// Decodes still images, animated GIF and animated PNG (APNG) via ImageIO,
    /// which natively understands per-frame delays for both formats.
    static func decode(_ data: Data) -> PetImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return PetImage(single: NSImage(data: data) ?? NSImage())
        }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else {
            return PetImage(single: NSImage(data: data) ?? NSImage())
        }

        let type = CGImageSourceGetType(source) as String?
        var images: [NSImage] = []
        var delays: [Int] = []
        images.reserveCapacity(count)
        delays.reserveCapacity(count)

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let size = NSSize(width: cgImage.width, height: cgImage.height)
            images.append(NSImage(cgImage: cgImage, size: size))
            delays.append(normalizeDelay(Int((frameDelay(source, index: i, type: type) * 1000).rounded())))
        }

        guard images.count > 1 else {
            return PetImage(single: NSImage(data: data) ?? NSImage())
        }
        return PetImage(frames: images, delaysMs: delays)
    }

    private static func frameDelay(_ source: CGImageSource, index: Int, type: String?) -> Double {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else {
            return 0.1
        }
        if let gif = props[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
            if let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclamped > 0 {
                return unclamped
            }
            if let delay = gif[kCGImagePropertyGIFDelayTime] as? Double, delay > 0 {
                return delay
            }
        }
        if let png = props[kCGImagePropertyPNGDictionary] as? [CFString: Any] {
            if let unclamped = png[kCGImagePropertyAPNGUnclampedDelayTime] as? Double, unclamped > 0 {
                return unclamped
            }
            if let delay = png[kCGImagePropertyAPNGDelayTime] as? Double, delay > 0 {
                return delay
            }
        }
        return 0.1
    }
}
