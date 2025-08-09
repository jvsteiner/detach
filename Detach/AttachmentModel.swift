import Foundation

struct AttachmentItem: Identifiable, Hashable {
  let id = UUID()
  let path: String
  let filename: String
  let size: Int64
  let dateModified: Date
  let fileExtension: String
  var isSelected: Bool = false
  
  var sizeString: String {
    ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
  }
  
  var dateString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: dateModified)
  }
  
  var typeCategory: FileTypeCategory {
    switch fileExtension.lowercased() {
    case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic":
      return .image
    case "mov", "mp4", "avi", "mkv", "wmv", "flv", "webm":
      return .video
    case "mp3", "wav", "aac", "flac", "m4a":
      return .audio
    case "pdf", "doc", "docx", "txt", "rtf":
      return .document
    case "pluginpayloadattachment":
      return .plugin
    default:
      return .other
    }
  }
}

enum FileTypeCategory: String, CaseIterable {
  case all = "All"
  case image = "Images"
  case video = "Videos"
  case audio = "Audio"
  case document = "Documents"
  case plugin = "Plugin Data"
  case other = "Other"
  
  var icon: String {
    switch self {
    case .all: return "doc.on.doc"
    case .image: return "photo"
    case .video: return "video"
    case .audio: return "music.note"
    case .document: return "doc.text"
    case .plugin: return "puzzlepiece.extension"
    case .other: return "questionmark.circle"
    }
  }
}

enum FilterTimeframe: String, CaseIterable {
  case all = "All Time"
  case week = "1 Week"
  case month = "1 Month"
  case threeMonths = "3 Months"
  case sixMonths = "6 Months"
  case year = "1 Year"
  
  var days: Int? {
    switch self {
    case .all: return nil
    case .week: return 7
    case .month: return 30
    case .threeMonths: return 90
    case .sixMonths: return 180
    case .year: return 365
    }
  }
}

enum FilterFileSize: String, CaseIterable {
  case all = "All Sizes"
  case small = "1 MB+"
  case medium = "10 MB+"
  case large = "50 MB+"
  case xlarge = "100 MB+"
  
  var bytes: Int64? {
    switch self {
    case .all: return nil
    case .small: return 1_000_000
    case .medium: return 10_000_000
    case .large: return 50_000_000
    case .xlarge: return 100_000_000
    }
  }
}