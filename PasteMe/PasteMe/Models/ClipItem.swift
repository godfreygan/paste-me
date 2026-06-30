import Foundation

struct ClipItem: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let imageData: Data?
    let type: ClipType
    let timestamp: Date
    var isPinned: Bool
    
    init(content: String, imageData: Data? = nil, type: ClipType, isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.imageData = imageData
        self.type = type
        self.timestamp = Date()
        self.isPinned = isPinned
    }
    
    static func == (lhs: ClipItem, rhs: ClipItem) -> Bool {
        lhs.id == rhs.id
    }
    
    var displayContent: String {
        switch type {
        case .text:
            return content.count > 100 ? String(content.prefix(100)) + "..." : content
        case .image:
            return "[图片] \(imageSizeDescription)"
        case .file:
            return (content as NSString).lastPathComponent
        }
    }
    
    var imageSizeDescription: String {
        guard let data = imageData else { return "" }
        let kb = Double(data.count) / 1024.0
        if kb > 1024 {
            return String(format: "%.1f MB", kb / 1024.0)
        }
        return String(format: "%.0f KB", kb)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(timestamp) {
            return "昨天"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: timestamp)
    }
}
