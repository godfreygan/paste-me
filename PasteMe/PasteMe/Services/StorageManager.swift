import Foundation
import AppKit

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var clips: [ClipItem] = []
    @Published var pinnedClips: [ClipItem] = []
    @Published var settings: AppSettings = .default
    
    private let appSupportURL: URL
    private let clipsURL: URL
    private let pinnedURL: URL
    private let settingsURL: URL
    private let imagesURL: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = appSupport.appendingPathComponent("PasteMe")
        clipsURL = appSupportURL.appendingPathComponent("clips.json")
        pinnedURL = appSupportURL.appendingPathComponent("pinned.json")
        settingsURL = appSupportURL.appendingPathComponent("settings.json")
        imagesURL = appSupportURL.appendingPathComponent("images")
        
        createDirectoriesIfNeeded()
        loadData()
    }
    
    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Load Data
    
    func loadData() {
        loadSettings()
        loadClips()
        loadPinnedClips()
    }
    
    private func loadSettings() {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            self.settings = .default
            saveSettings()
            return
        }
        self.settings = settings
    }
    
    private func loadClips() {
        guard let data = try? Data(contentsOf: clipsURL),
              let clips = try? JSONDecoder().decode([ClipItem].self, from: data) else {
            self.clips = []
            return
        }
        self.clips = clips
    }
    
    private func loadPinnedClips() {
        guard let data = try? Data(contentsOf: pinnedURL),
              let pinned = try? JSONDecoder().decode([ClipItem].self, from: data) else {
            self.pinnedClips = []
            return
        }
        self.pinnedClips = pinned
    }
    
    // MARK: - Save Data
    
    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: settingsURL)
    }
    
    func saveClips() {
        guard let data = try? JSONEncoder().encode(clips) else { return }
        try? data.write(to: clipsURL)
    }
    
    func savePinnedClips() {
        guard let data = try? JSONEncoder().encode(pinnedClips) else { return }
        try? data.write(to: pinnedURL)
    }
    
    // MARK: - Add New Clip
    
    func addClip(_ item: ClipItem) {
        // Check for duplicate content (skip if same content exists at top)
        if let first = clips.first, first.content == item.content && first.type == item.type {
            return
        }
        
        // Remove duplicate if exists elsewhere
        clips.removeAll { $0.content == item.content && $0.type == item.type && !$0.isPinned }
        
        // Insert at top
        clips.insert(item, at: 0)
        
        // Save image if needed
        if item.type == .image, let imageData = item.imageData {
            saveImage(data: imageData, id: item.id)
        }
        
        // Enforce max history limit (only on non-pinned items)
        enforceHistoryLimit()
        
        saveClips()
    }
    
    // MARK: - Enforce History Limit
    
    private func enforceHistoryLimit() {
        let nonPinnedClips = clips.filter { !$0.isPinned }
        
        if nonPinnedClips.count > settings.maxHistoryCount {
            // Find clips to remove (oldest non-pinned)
            let excessCount = nonPinnedClips.count - settings.maxHistoryCount
            let sortedNonPinned = nonPinnedClips.sorted { $0.timestamp < $1.timestamp }
            let clipsToRemove = Array(sortedNonPinned.prefix(excessCount))
            
            for clipToRemove in clipsToRemove {
                // Delete image file if exists
                if clipToRemove.type == .image {
                    deleteImage(id: clipToRemove.id)
                }
                // Remove from array
                clips.removeAll { $0.id == clipToRemove.id }
            }
        }
    }
    
    // MARK: - Pin / Unpin
    
    func togglePin(_ item: ClipItem) {
        if let index = clips.firstIndex(where: { $0.id == item.id }) {
            clips[index].isPinned.toggle()
            
            if clips[index].isPinned {
                pinnedClips.insert(clips[index], at: 0)
            } else {
                pinnedClips.removeAll { $0.id == item.id }
            }
            
            saveClips()
            savePinnedClips()
        }
    }
    
    // MARK: - Delete
    
    func deleteClip(_ item: ClipItem) {
        clips.removeAll { $0.id == item.id }
        pinnedClips.removeAll { $0.id == item.id }
        
        if item.type == .image {
            deleteImage(id: item.id)
        }
        
        saveClips()
        savePinnedClips()
    }
    
    func clearAllHistory() {
        // Delete all image files
        for clip in clips where clip.type == .image && !clip.isPinned {
            deleteImage(id: clip.id)
        }
        
        // Keep pinned items
        clips = clips.filter { $0.isPinned }
        saveClips()
    }
    
    // MARK: - Image Storage
    
    private func saveImage(data: Data, id: UUID) {
        let imageURL = imagesURL.appendingPathComponent("\(id.uuidString).png")
        try? data.write(to: imageURL)
    }
    
    private func deleteImage(id: UUID) {
        let imageURL = imagesURL.appendingPathComponent("\(id.uuidString).png")
        try? FileManager.default.removeItem(at: imageURL)
    }
    
    func loadImage(id: UUID) -> NSImage? {
        let imageURL = imagesURL.appendingPathComponent("\(id.uuidString).png")
        guard let data = try? Data(contentsOf: imageURL) else { return nil }
        return NSImage(data: data)
    }
    
    // MARK: - Update Settings
    
    func updateMaxHistoryCount(_ count: Int) {
        let clampedCount = Swift.max(AppSettings.maxHistoryRange.lowerBound,
                                     Swift.min(count, AppSettings.maxHistoryRange.upperBound))
        settings.maxHistoryCount = clampedCount
        saveSettings()
        enforceHistoryLimit()
        saveClips()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        settings.launchAtLogin = enabled
        LaunchAtLoginHelper.setEnabled(enabled)
        saveSettings()
    }

    func setPlaySoundOnCopy(_ enabled: Bool) {
        settings.playSoundOnCopy = enabled
        saveSettings()
    }

    func updateHotkey(keyCode: UInt32, modifiers: UInt32, keyLabel: String) {
        settings.hotkeyKeyCode = keyCode
        settings.hotkeyModifiers = modifiers
        settings.hotkeyKeyLabel = keyLabel
        saveSettings()
    }
}
