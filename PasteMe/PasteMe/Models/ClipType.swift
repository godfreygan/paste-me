import Foundation

enum ClipType: String, Codable, CaseIterable {
    case text
    case image
    case file
    
    var displayName: String {
        switch self {
        case .text: return "文本"
        case .image: return "图片"
        case .file: return "文件"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "folder"
        }
    }
}
