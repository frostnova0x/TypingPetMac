import AppKit
import ApplicationServices
import QuartzCore

/// Renders the current frame on a child CALayer so the bounce (a transform)
/// never triggers a redraw, and forwards input to the owning window.
final class PetContentView: NSView {
    let imageLayer = CALayer()
    weak var host: OverlayWindow?

    /// The image's resting position, inset within this view's (larger) bounds
    /// so the bounce transform has headroom above/below without clipping.
    var imageRect: NSRect = .zero {
        didSet { imageLayer.frame = imageRect }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
        imageLayer.contentsGravity = .resize
        imageLayer.actions = ["contents": NSNull(), "transform": NSNull(), "bounds": NSNull(), "position": NSNull()]
        layer?.addSublayer(imageLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func setImage(_ image: NSImage) {
        var rect = NSRect(origin: .zero, size: image.size)
        imageLayer.contents = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    func setShiftY(_ y: Double) {
        imageLayer.transform = CATransform3DMakeTranslation(0, CGFloat(-y), 0)
    }

    override func mouseDown(with event: NSEvent) { host?.handleMouseDown(event) }
    override func mouseDragged(with event: NSEvent) { host?.handleMouseDragged(event) }
    override func mouseUp(with event: NSEvent) { host?.handleMouseUp(event) }
    override func rightMouseDown(with event: NSEvent) { host?.showContextMenu(event) }
}

final class OverlayWindow: NSWindow {
    // Layout constants, ported from the original WPF overlay (800x500 design canvas).
    private static let boxW = 800.0
    private static let boxH = 500.0
    private static let bottomOverflow = 30.0
    private static let rightInset = 40.0

    // Spring-bounce constants, ported verbatim from OverlayWindow.cs.
    private static let impulse = 850.0
    private static let stiffness = 1500.0
    private static let damping = 30.0
    private static let subStep = 1.0 / 240.0
    private static let maxFrameDt = 0.25
    private static let settleLimit = 1.5
    private static let maxRise = 24.0
    private static let repeatWindow = 1.2
    private static let idleTick = 0.26

    private static func peakPerSpeed() -> Double {
        let wn = (stiffness).squareRoot()
        let zeta = damping / (2.0 * wn)
        let wd = wn * (1.0 - zeta * zeta).squareRoot()
        let tPeak = atan2(wd, zeta * wn) / wd
        return exp(-zeta * wn * tPeak) * sin(wd * tPeak) / wd
    }
    private static let maxKickSpeed = maxRise / peakPerSpeed()

    let settings: Settings
    private var basicImg: PetImage!
    private var leftImg: PetImage!
    private var rightImg: PetImage!
    private var current: PetImage!
    private var frameIndex = 0
    private var frameTimer: Timer?

    private let contentViewCustom: PetContentView
    private var displayedImageHeight: Double = 175.0

    private var nextIsLeft = true
    private var held: [UInt16: CFTimeInterval] = [:]
    private var idleTimer: Timer?
    private var physicsTimer: Timer?
    private var lastPhysicsTime: CFTimeInterval = 0
    private var y = 0.0
    private var vy = 0.0
    private var sinceKick = 0.0

    private var globalKeyMonitor: Any?
    private var dragStartScreenPoint = NSPoint.zero
    private var dragStartWindowOrigin = NSPoint.zero

    /// Strong references so NSMenuItem targets survive between menu popups.
    var menuActions: [MenuAction] = []

    init(settings: Settings) {
        self.settings = settings
        contentViewCustom = PetContentView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        super.init(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        applyTopMostWindowState(settings.topMostMode)

        contentViewCustom.host = self
        contentView = contentViewCustom

        loadImages()
        applyLayout(keepBottom: false)
        placeInitially()
        setImage(basicImg)

        installGlobalMonitor()
    }

    // MARK: - Images

    var usesPlaceholderArt: Bool {
        ImageStore.isPlaceholder("basic") && ImageStore.isPlaceholder("left") && ImageStore.isPlaceholder("right")
    }

    private func loadImages() {
        basicImg = ImageStore.load("basic")
        leftImg = ImageStore.load("left")
        rightImg = ImageStore.load("right")
    }

    /// Called after the settings window changes a custom image, mirroring the
    /// original's ImagesChanged().
    func imagesChanged() {
        loadImages()
        setImage(basicImg)
        applyLayout(keepBottom: true)
        savePosition()
    }

    private func setImage(_ image: PetImage) {
        current = image
        frameIndex = 0
        contentViewCustom.setImage(image.first)
        frameTimer?.invalidate()
        if image.animated {
            scheduleNextFrame()
        }
    }

    private func scheduleNextFrame() {
        let delay = Double(current.delaysMs[frameIndex]) / 1000.0
        frameTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.advanceFrame()
        }
        if let frameTimer { RunLoop.current.add(frameTimer, forMode: .common) }
    }

    private func advanceFrame() {
        guard let current, current.animated else { return }
        frameIndex = (frameIndex + 1) % current.frames.count
        contentViewCustom.setImage(current.frames[frameIndex])
        scheduleNextFrame()
    }

    // MARK: - Layout / positioning

    private func applyLayout(keepBottom: Bool) {
        let pixelW = Double(basicImg.first.size.width)
        let pixelH = Double(basicImg.first.size.height)
        let k = min(Self.boxW * settings.scale / pixelW, Self.boxH * settings.scale / pixelH)
        let imgW = pixelW * k
        let imgH = pixelH * k
        displayedImageHeight = imgH

        let newWidth = imgW + 4.0
        let newHeight = imgH + 80.0

        // origin.y is already the window's bottom edge in AppKit, so keeping
        // it unchanged on a resize is the "keep bottom" behavior for free.
        let origin = frame.origin
        setFrame(NSRect(x: origin.x, y: origin.y, width: newWidth, height: newHeight), display: true)
        contentViewCustom.frame = NSRect(x: 0, y: 0, width: newWidth, height: newHeight)
        contentViewCustom.imageRect = NSRect(x: 2, y: 40, width: imgW, height: imgH)
    }

    private func visibleFrame() -> NSRect {
        (screen ?? NSScreen.main)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private func defaultPosition() -> NSPoint {
        let v = visibleFrame()
        return NSPoint(x: v.maxX - frame.width - Self.rightInset, y: v.minY - Self.bottomOverflow)
    }

    private func placeInitially() {
        let v = visibleFrame()
        let left = settings.left
        let top = settings.top
        let fits = !left.isNaN && !top.isNaN
            && left > v.minX - frame.width + Self.rightInset && left < v.maxX - Self.rightInset
            && top > v.minY - frame.height + Self.rightInset && top < v.maxY - Self.rightInset
        let origin = fits ? NSPoint(x: left, y: top) : defaultPosition()
        setFrameOrigin(origin)
    }

    func resetPosition() {
        setFrameOrigin(defaultPosition())
        savePosition()
    }

    private func savePosition() {
        settings.left = frame.origin.x
        settings.top = frame.origin.y
        settings.save()
    }

    // MARK: - Dragging

    func handleMouseDown(_ event: NSEvent) {
        guard !settings.locked else { return }
        orderFrontRegardless()
        dragStartScreenPoint = NSEvent.mouseLocation
        dragStartWindowOrigin = frame.origin
    }

    func handleMouseDragged(_ event: NSEvent) {
        guard !settings.locked else { return }
        let current = NSEvent.mouseLocation
        let dx = current.x - dragStartScreenPoint.x
        let dy = current.y - dragStartScreenPoint.y
        setFrameOrigin(NSPoint(x: dragStartWindowOrigin.x + dx, y: dragStartWindowOrigin.y + dy))
    }

    func handleMouseUp(_ event: NSEvent) {
        guard !settings.locked else { return }
        savePosition()
    }

    // MARK: - Input monitoring (equivalent of the Windows low-level keyboard hook)

    private func installGlobalMonitor() {
        DebugLog.write("AXIsProcessTrusted() = \(AXIsProcessTrusted())")
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return }
            if event.type == .keyDown {
                self.onKeyDown(event)
            } else {
                self.onKeyUp(event)
            }
        }
    }

    private func onKeyDown(_ event: NSEvent) {
        guard !event.isARepeat else { return }
        held[event.keyCode] = CACurrentMediaTime()
        nextIsLeft.toggle()
        setImage(nextIsLeft ? leftImg : rightImg)
        kick()
        restartIdleTimer()
    }

    private func onKeyUp(_ event: NSEvent) {
        held.removeValue(forKey: event.keyCode)
        restartIdleTimer()
    }

    private func restartIdleTimer() {
        idleTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: Self.idleTick, repeats: true) { [weak self] _ in
            self?.onIdleTick()
        }
        RunLoop.current.add(timer, forMode: .common)
        idleTimer = timer
    }

    private func onIdleTick() {
        let now = CACurrentMediaTime()
        held = held.filter { now - $0.value < Self.repeatWindow }
        if held.isEmpty {
            idleTimer?.invalidate()
            idleTimer = nil
            setImage(basicImg)
        }
    }

    // MARK: - Bounce physics

    private func kick() {
        let factor = PetOptions.shakeFactors[max(0, min(PetOptions.shakeFactors.count - 1, settings.shake))]
        guard factor > 0 else { return }
        let speed = min(Self.impulse * factor * (displayedImageHeight / 175.0), Self.maxKickSpeed)
        vy = -speed
        sinceKick = 0
        ensurePhysicsTimerRunning()
    }

    /// The 120Hz physics timer only runs while a bounce is in flight, rather
    /// than for the whole process lifetime, so the pet is truly idle at rest.
    private func ensurePhysicsTimerRunning() {
        guard physicsTimer == nil else { return }
        lastPhysicsTime = CACurrentMediaTime()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            self?.tickPhysics()
        }
        RunLoop.current.add(timer, forMode: .common)
        physicsTimer = timer
    }

    private func tickPhysics() {
        let now = CACurrentMediaTime()
        let dt = min(now - lastPhysicsTime, Self.maxFrameDt)
        lastPhysicsTime = now
        guard dt > 0 else { return }

        let steps = Int(ceil(dt / Self.subStep))
        let h = dt / Double(steps)
        for _ in 0..<steps {
            vy += (-Self.stiffness * y - Self.damping * vy) * h
            y += vy * h
            if y > Self.maxRise {
                y = Self.maxRise
                if vy > 0 { vy = 0 }
            } else if y < -Self.maxRise {
                y = -Self.maxRise
                if vy < 0 { vy = 0 }
            }
        }
        sinceKick += dt
        if sinceKick >= Self.settleLimit || (abs(y) < 0.05 && abs(vy) < 1.0) {
            y = 0
            vy = 0
        }
        contentViewCustom.setShiftY(y)

        if y == 0, vy == 0 {
            physicsTimer?.invalidate()
            physicsTimer = nil
        }
    }

    // MARK: - Menu / lifecycle

    func showContextMenu(_ event: NSEvent) {
        let menu = MenuBuilder.makeMenu(for: self)
        menu.popUp(positioning: nil, at: event.locationInWindow, in: contentViewCustom)
    }

    func applyScale(_ scale: Double) {
        settings.scale = scale
        applyLayout(keepBottom: true)
        savePosition()
        settings.save()
    }

    func applyTopMost(_ mode: TopMostMode) {
        settings.topMostMode = mode
        applyTopMostWindowState(mode)
        settings.save()
    }

    /// `.fullScreenAuxiliary` is what lets the window appear over a
    /// fullscreen app's dedicated Space -- independent of `level`, and is
    /// its own tier rather than something a plain on/off toggle can express:
    /// "float above normal windows" and "show over fullscreen apps" are two
    /// separate, independently useful behaviors.
    private func applyTopMostWindowState(_ mode: TopMostMode) {
        switch mode {
        case .off:
            level = .normal
            collectionBehavior = [.managed]
        case .on:
            level = .floating
            collectionBehavior = [.canJoinAllSpaces, .fullScreenNone]
        case .onIncludingFullscreen:
            level = .floating
            collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
    }

    func applyLocked(_ locked: Bool) {
        settings.locked = locked
        settings.save()
    }

    func applyShake(_ level: Int) {
        settings.shake = level
        settings.save()
    }

    func applyShowInDock(_ on: Bool) {
        settings.showInDock = on
        settings.save()
        NSApp.setActivationPolicy(on ? .regular : .accessory)
    }

    func quit() {
        savePosition()
        globalKeyMonitor.map(NSEvent.removeMonitor)
        NSApp.terminate(nil)
    }
}
