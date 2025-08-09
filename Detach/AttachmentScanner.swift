import Foundation
import AppKit

@MainActor
class AttachmentScanner: ObservableObject {
  @Published var attachments: [AttachmentItem] = []
  @Published var isScanning = false
  @Published var scanProgress: Double = 0.0
  @Published var scanStatus = "Ready to scan"
  
  private let iMessageAttachmentsPath: String = {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
    return homeDirectory.appendingPathComponent("Library/Messages/Attachments").path(percentEncoded: false)
  }()
  
  func scanAttachments() {
    Task {
      print("🔍 Starting scan...")
      isScanning = true
      scanProgress = 0.0
      scanStatus = "Checking permissions..."
      
      let fileManager = FileManager.default
      print("📁 Checking path: \(iMessageAttachmentsPath)")
      
      // Check if directory exists and we have permission to read it
      guard fileManager.fileExists(atPath: iMessageAttachmentsPath) else {
        print("❌ Directory not found")
        scanStatus = "iMessage attachments directory not found"
        isScanning = false
        return
      }
      
      print("✅ Directory exists, checking permissions...")
      
      // Try to read the directory to check permissions
      do {
        let contents = try fileManager.contentsOfDirectory(atPath: iMessageAttachmentsPath)
        print("✅ Permission check passed! Found \(contents.count) items")
      } catch {
        print("❌ Permission denied: \(error)")
        showPermissionAlert()
        scanStatus = "Permission denied. Please grant Full Disk Access and try again."
        isScanning = false
        return
      }
      
      scanStatus = "Scanning attachments..."
      var foundAttachments: [AttachmentItem] = []
      
      do {
        let hexFolders = try fileManager.contentsOfDirectory(atPath: iMessageAttachmentsPath)
        let totalFolders = hexFolders.count
        
        for (index, hexFolder) in hexFolders.enumerated() {
          let hexPath = "\(iMessageAttachmentsPath)/\(hexFolder)"
          
          // Update progress
          scanProgress = Double(index) / Double(totalFolders)
          scanStatus = "Scanning \(hexFolder)..."
          
          // Skip if not a directory
          var isDirectory: ObjCBool = false
          guard fileManager.fileExists(atPath: hexPath, isDirectory: &isDirectory),
                isDirectory.boolValue else { continue }
          
          // Scan subfolders within hex folder
          let subfolders = try fileManager.contentsOfDirectory(atPath: hexPath)
          
          for subfolder in subfolders {
            let subfolderPath = "\(hexPath)/\(subfolder)"
            
            guard fileManager.fileExists(atPath: subfolderPath, isDirectory: &isDirectory),
                  isDirectory.boolValue else { continue }
            
            // Scan UUID folders within subfolder
            let uuidFolders = try fileManager.contentsOfDirectory(atPath: subfolderPath)
            
            for uuidFolder in uuidFolders {
              let uuidPath = "\(subfolderPath)/\(uuidFolder)"
              
              guard fileManager.fileExists(atPath: uuidPath, isDirectory: &isDirectory),
                    isDirectory.boolValue else { continue }
              
              // Scan files within UUID folder and calculate total folder info
              let files = try fileManager.contentsOfDirectory(atPath: uuidPath)
              
              // Skip empty UUID folders
              let actualFiles = files.filter { !$0.hasPrefix(".") }
              guard !actualFiles.isEmpty else { continue }
              
              // Calculate total size and find the primary file info
              var totalSize: Int64 = 0
              var latestDate = Date.distantPast
              var primaryFile = ""
              var primaryExtension = ""
              
              for file in actualFiles {
                let filePath = "\(uuidPath)/\(file)"
                
                // Skip directories
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory),
                      !isDirectory.boolValue else { continue }
                
                // Get file attributes
                let attributes = try fileManager.attributesOfItem(atPath: filePath)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let fileDate = attributes[.modificationDate] as? Date ?? Date.distantPast
                
                totalSize += fileSize
                
                // Use the newest file as the primary file for display
                if fileDate > latestDate {
                  latestDate = fileDate
                  primaryFile = file
                  primaryExtension = (file as NSString).pathExtension
                }
              }
              
              // Create attachment item representing the entire UUID folder
              if !primaryFile.isEmpty {
                let attachment = AttachmentItem(
                  path: uuidPath,  // Store UUID folder path, not individual file path
                  filename: primaryFile,  // Display name of primary file
                  size: totalSize,  // Total size of all files in folder
                  dateModified: latestDate,
                  fileExtension: primaryExtension
                )
                
                foundAttachments.append(attachment)
              }
            }
          }
        }
        
        attachments = foundAttachments.sorted { $0.dateModified > $1.dateModified }
        scanStatus = "Found \(attachments.count) attachments"
        
      } catch {
        scanStatus = "Error scanning: \(error.localizedDescription)"
      }
      
      scanProgress = 1.0
      isScanning = false
    }
  }
  
  func filteredAttachments(
    timeframe: FilterTimeframe,
    customTimeframeDays: Int? = nil,
    fileSize: FilterFileSize,
    customFileSizeBytes: Int64 = 0,
    fileType: FileTypeCategory
  ) -> [AttachmentItem] {
    return attachments.filter { attachment in
      // Filter by timeframe
      let daysToCheck: Int?
      if timeframe == .custom {
        daysToCheck = customTimeframeDays
      } else {
        daysToCheck = timeframe.days
      }
      
      if let days = daysToCheck {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        if attachment.dateModified > cutoffDate {
          return false
        }
      }
      
      // Filter by file size
      let minSize: Int64?
      if fileSize == .custom {
        minSize = customFileSizeBytes > 0 ? customFileSizeBytes : nil
      } else {
        minSize = fileSize.bytes
      }
      
      if let minSizeValue = minSize {
        if attachment.size < minSizeValue {
          return false
        }
      }
      
      // Filter by file type
      if fileType != .all && attachment.typeCategory != fileType {
        return false
      }
      
      return true
    }
  }
  
  func deleteAttachments(_ attachments: [AttachmentItem]) -> (success: Int, failed: Int) {
    let fileManager = FileManager.default
    var successCount = 0
    var failedCount = 0
    
    for attachment in attachments {
      do {
        // Delete the entire UUID folder (attachment.path is now the folder path)
        try fileManager.trashItem(at: URL(filePath: attachment.path), resultingItemURL: nil)
        print("🗑️ Deleted folder: \(attachment.path)")
        successCount += 1
      } catch {
        print("❌ Failed to delete folder: \(attachment.path) - \(error)")
        failedCount += 1
      }
    }
    
    // Refresh the attachments list
    Task {
      scanAttachments()
    }
    
    return (successCount, failedCount)
  }
  
  func totalSize(of attachments: [AttachmentItem]) -> Int64 {
    attachments.reduce(0) { $0 + $1.size }
  }
  
  func copyAttachments(_ attachments: [AttachmentItem], to destinationURL: URL) -> (success: Int, failed: Int) {
    let fileManager = FileManager.default
    var successCount = 0
    var failedCount = 0
    
    for attachment in attachments {
      do {
        let sourceURL = URL(filePath: attachment.path)
        let destinationFolderURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent)
        
        // Check if destination already exists
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: destinationFolderURL.path, isDirectory: &isDirectory) {
          // If it exists, create a unique name
          var counter = 1
          var uniqueURL = destinationURL.appendingPathComponent("\(sourceURL.lastPathComponent)_\(counter)")
          
          while fileManager.fileExists(atPath: uniqueURL.path) {
            counter += 1
            uniqueURL = destinationURL.appendingPathComponent("\(sourceURL.lastPathComponent)_\(counter)")
          }
          
          try fileManager.copyItem(at: sourceURL, to: uniqueURL)
          print("📁 Copied folder to: \(uniqueURL.path)")
        } else {
          try fileManager.copyItem(at: sourceURL, to: destinationFolderURL)
          print("📁 Copied folder to: \(destinationFolderURL.path)")
        }
        
        successCount += 1
      } catch {
        print("❌ Failed to copy folder: \(attachment.path) - \(error)")
        failedCount += 1
      }
    }
    
    return (successCount, failedCount)
  }
  
  @MainActor
  private func showPermissionAlert() {
    let alert = NSAlert()
    alert.messageText = "Permission Required"
    alert.informativeText = """
    Detach needs Full Disk Access to scan your iMessage attachments.
    
    Please:
    1. Open System Settings > Privacy & Security
    2. Click "Full Disk Access"
    3. Click the + button and add this app
    4. Restart the app
    
    Would you like to open System Settings now?
    """
    alert.addButton(withTitle: "Open System Settings")
    alert.addButton(withTitle: "Cancel")
    alert.alertStyle = .informational
    
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
      // Open System Settings to Privacy & Security
      if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
        NSWorkspace.shared.open(url)
      }
    }
  }
}