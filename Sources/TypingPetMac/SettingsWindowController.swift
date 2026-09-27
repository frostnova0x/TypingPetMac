import AppKit
import SwiftUI
import UniformTypeIdentifiers

private let imageSlots: [(key: String, label: String)] = [
    ("basic", "Idle"),
    ("left", "Typing 1"),
    ("right", "Typing 2"),
]

final class SettingsViewModel: ObservableObject {
    weak var window: OverlayWindow?

    @Published var scale: Double
    @Published var shake: Int
    @Published var topMostMode: TopMostMode
    @Published var locked: Bool
    @Published var showInDock: Bool
    @Published var thumbnails: [String: NSImage] = [:]
    @Published var hasCustom: [String: Bool] = [:]

    init(window: OverlayWindow) {
        self.window = window
        scale = window.settings.scale
        shake = window.settings.shake
        topMostMode = window.settings.topMostMode
        locked = window.settings.locked
        showInDock = window.settings.showInDock
        refreshThumbnails()
    }

    func commitScale(_ v: Double) { scale = v; window?.applyScale(v) }
    func commitShake(_ v: Int) { shake = v; window?.applyShake(v) }
    func commitTopMost(_ v: TopMostMode) { topMostMode = v; window?.applyTopMost(v) }
    func commitLocked(_ v: Bool) { locked = v; window?.applyLocked(v) }
    func commitShowInDock(_ v: Bool) { showInDock = v; window?.applyShowInDock(v) }
    func resetPosition() { window?.resetPosition() }

    func refreshThumbnails() {
        for (key, _) in imageSlots {
            if let data = ImageStore.currentBytes(key), let image = NSImage(data: data) {
                thumbnails[key] = image
            } else {
                thumbnails[key] = nil
            }
            hasCustom[key] = ImageStore.hasCustom(key)
        }
    }

    func chooseImage(for slot: String) {
        let panel = NSOpenPanel()
        panel.title = "Choose \(imageSlots.first { $0.key == slot }?.label ?? slot) Image"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.png, .jpeg, .gif]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        setImage(for: slot, from: url)
    }

    func setImage(for slot: String, from url: URL) {
        do {
            try ImageStore.setCustom(slot, sourceFile: url)
            refreshThumbnails()
            window?.imagesChanged()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't load that image"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    func resetImage(_ slot: String) {
        ImageStore.clearCustom(slot)
        refreshThumbnails()
        window?.imagesChanged()
    }
}

struct ImageDropTarget: DropDelegate {
    let slot: String
    let model: SettingsViewModel

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.fileURL]).first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            DispatchQueue.main.async { model.setImage(for: slot, from: url) }
        }
        return true
    }
}

struct ImageSlotRow: View {
    @ObservedObject var model: SettingsViewModel
    let slot: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                if let thumb = model.thumbnails[slot] {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                }
            }
            .frame(width: 72, height: 54)
            .onDrop(of: [.fileURL], delegate: ImageDropTarget(slot: slot, model: model))

            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.headline)
                Text("Drag an image here, or choose a file. PNG, JPG or animated GIF.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 6) {
                Button("Choose…") { model.chooseImage(for: slot) }
                if model.hasCustom[slot] == true {
                    Button("Reset") { model.resetImage(slot) }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ImagesTabView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(imageSlots, id: \.key) { slot in
                ImageSlotRow(model: model, slot: slot.key, label: slot.label)
                if slot.key != imageSlots.last?.key {
                    Divider()
                }
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

struct GeneralTabView: View {
    @ObservedObject var model: SettingsViewModel
    private let sizeLabels = ["Small", "Normal", "Large", "Extra Large"]
    private let shakeLabels = ["None", "Level 1", "Level 2", "Level 3"]

    var body: some View {
        Form {
            Picker("Size", selection: Binding(
                get: { model.scale },
                set: { model.commitScale($0) }
            )) {
                ForEach(Array(zip(PetOptions.scales, sizeLabels)), id: \.0) { scale, label in
                    Text(label).tag(scale)
                }
            }
            .pickerStyle(.segmented)

            Picker("Bounce", selection: Binding(
                get: { model.shake },
                set: { model.commitShake($0) }
            )) {
                ForEach(Array(shakeLabels.enumerated()), id: \.offset) { index, label in
                    Text(label).tag(index)
                }
            }
            .pickerStyle(.segmented)

            Picker("Always on Top", selection: Binding(
                get: { model.topMostMode },
                set: { model.commitTopMost($0) }
            )) {
                ForEach(TopMostMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            Toggle("Lock Position", isOn: Binding(
                get: { model.locked },
                set: { model.commitLocked($0) }
            ))
            Toggle("Show in Dock", isOn: Binding(
                get: { model.showInDock },
                set: { model.commitShowInDock($0) }
            ))

            Button("Reset Position") { model.resetPosition() }
        }
        .padding(20)
        .frame(width: 340)
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        TabView {
            GeneralTabView(model: model)
                .tabItem { Label("General", systemImage: "gearshape") }
            ImagesTabView(model: model)
                .tabItem { Label("Images", systemImage: "photo") }
        }
        .frame(width: 440)
    }
}

final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var nsWindow: NSWindow?
    private var model: SettingsViewModel?

    func show(for window: OverlayWindow) {
        if let existing = nsWindow {
            model = SettingsViewModel(window: window)
            existing.contentView = NSHostingView(rootView: SettingsView(model: model!))
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let vm = SettingsViewModel(window: window)
        model = vm
        let hosting = NSHostingView(rootView: SettingsView(model: vm))
        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Typing Pet Settings"
        panel.contentView = hosting
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.center()
        nsWindow = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
