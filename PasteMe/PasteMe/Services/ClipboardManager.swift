import AppKit
import Combine

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var ignoreNextClipboardChange = false
    private let storage = StorageManager.shared
    
    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }
    
    func startMonitoring() {
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        // .common keeps polling while the user interacts with other apps (menu bar apps).
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }

        if ignoreNextClipboardChange {
            lastChangeCount = currentChangeCount
            ignoreNextClipboardChange = false
            return
        }

        lastChangeCount = currentChangeCount
        
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            handleImage(image)
        } else if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            handleFiles(urls)
        } else if let string = readText(from: pasteboard) {
            handleText(string)
        }
    }

    private func readText(from pasteboard: NSPasteboard) -> String? {
        let types: [NSPasteboard.PasteboardType] = [
            .string,
            NSPasteboard.PasteboardType("public.utf8-plain-text"),
            NSPasteboard.PasteboardType("public.plain-text"),
            NSPasteboard.PasteboardType("NSStringPboardType"),
        ]
        for type in types {
            if let string = pasteboard.string(forType: type), !string.isEmpty {
                return string
            }
        }
        return nil
    }
    
    private func handleText(_ text: String) {
        let item = ClipItem(content: text, type: .text)
        DispatchQueue.main.async { self.storage.addClip(item) }
    }
    
    private func handleImage(_ image: NSImage) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return
        }
        let item = ClipItem(content: "[图片]", imageData: pngData, type: .image)
        DispatchQueue.main.async { self.storage.addClip(item) }
    }
    
    private func handleFiles(_ urls: [URL]) {
        for url in urls {
            let path = url.path
            let item = ClipItem(content: path, type: .file)
            DispatchQueue.main.async { self.storage.addClip(item) }
        }
    }
    
    // MARK: - Copy to Clipboard

    /// 写入系统剪贴板，并忽略下一次监听回调，避免重复写入历史。
    func copyToClipboard(_ item: ClipItem) {
        ignoreNextClipboardChange = true

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text:
            pasteboard.setString(item.content, forType: .string)
        case .image:
            if let image = storage.loadImage(id: item.id) {
                pasteboard.writeObjects([image])
            }
        case .file:
            let url = URL(fileURLWithPath: item.content)
            pasteboard.writeObjects([url as NSPasteboardWriting])
        }

        lastChangeCount = pasteboard.changeCount
    }

    func copyAndPaste(_ item: ClipItem) {
        PasteSimulator.performPaste {
            self.copyToClipboard(item)
        }
    }
}
