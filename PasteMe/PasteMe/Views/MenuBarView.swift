import SwiftUI
import AppKit

struct MenuBarView: View {
    var onPaste: ((ClipItem) -> Void)? = nil

    @ObservedObject private var storage = StorageManager.shared
    @State private var searchText = ""
    
    var filteredClips: [ClipItem] {
        if searchText.isEmpty {
            return storage.clips
        }
        return storage.clips.filter { clip in
            clip.content.localizedCaseInsensitiveContains(searchText) ||
            clip.type.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var pinnedItems: [ClipItem] {
        filteredClips.filter { $0.isPinned }
    }
    
    var recentItems: [ClipItem] {
        filteredClips.filter { !$0.isPinned }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(12)
            
            Divider()
            
            // Clip List
            ScrollView {
                VStack(spacing: 0) {
                    // Pinned Section
                    if !pinnedItems.isEmpty {
                        SectionHeader(title: "置顶", icon: "pin.fill", color: .orange)
                        
                        ForEach(pinnedItems) { item in
                            ClipItemRow(
                                item: item,
                                onCopy: { pasteItem(item) },
                                onPin: { storage.togglePin(item) },
                                onDelete: { storage.deleteClip(item) }
                            )
                            .id(item.id)
                        }
                    }
                    
                    // Recent Section
                    if !recentItems.isEmpty {
                        SectionHeader(title: "最近复制", icon: "clock", color: .blue)
                        
                        ForEach(recentItems) { item in
                            ClipItemRow(
                                item: item,
                                onCopy: { pasteItem(item) },
                                onPin: { storage.togglePin(item) },
                                onDelete: { storage.deleteClip(item) }
                            )
                            .id(item.id)
                        }
                    }
                    
                    // Empty State
                    if filteredClips.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clipboard")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text(searchText.isEmpty ? "暂无复制记录" : "未找到匹配内容")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                    }
                }
            }
        }
        .frame(width: 320, height: 450)
    }
    
    private func pasteItem(_ item: ClipItem) {
        if let onPaste {
            onPaste(item)
        } else {
            ClipboardManager.shared.copyAndPaste(item)
        }

        if storage.settings.playSoundOnCopy {
            NSSound(named: NSSound.Name("Pop"))?.play()
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
