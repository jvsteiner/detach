import SwiftUI

struct ContentView: View {
  @StateObject private var scanner = AttachmentScanner()
  @State private var selectedTimeframe: FilterTimeframe = .month
  @State private var selectedFileSize: FilterFileSize = .medium
  @State private var selectedFileType: FileTypeCategory = .all
  @State private var selectedAttachments: Set<AttachmentItem> = []
  @State private var showingDeleteConfirmation = false
  @State private var showingCopyConfirmation = false
  @State private var selectedDestinationURL: URL?
  
  // Custom filter inputs
  @State private var customTimeframeValue: String = "3"
  @State private var customTimeframeUnit: TimeUnit = .months
  @State private var customFileSize: String = "7.5"
  @State private var customFileSizeUnit: FileSizeUnit = .mb
  
  private var filteredAttachments: [AttachmentItem] {
    // Calculate custom values
    let customDays = selectedTimeframe == .custom ? 
      (Int(customTimeframeValue) ?? 0) * customTimeframeUnit.dayMultiplier : nil
    let customSizeBytes = selectedFileSize == .custom ? 
      (Double(customFileSize) ?? 0) * Double(customFileSizeUnit.multiplier) : nil
    
    return scanner.filteredAttachments(
      timeframe: selectedTimeframe,
      customTimeframeDays: customDays,
      fileSize: selectedFileSize,
      customFileSizeBytes: Int64(customSizeBytes ?? 0),
      fileType: selectedFileType
    )
  }
  
  private var totalSelectedSize: Int64 {
    scanner.totalSize(of: Array(selectedAttachments))
  }
  
  var body: some View {
    VStack(spacing: 20) {
      // Header
      VStack(spacing: 10) {
        Text("iMessage Attachment Cleaner")
          .font(.title)
          .fontWeight(.semibold)
        
        Text("~/Library/Messages/Attachments")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      // Scan Button
      Button(action: {
        scanner.scanAttachments()
      }) {
        HStack {
          if scanner.isScanning {
            ProgressView()
              .scaleEffect(0.8)
          } else {
            Image(systemName: "magnifyingglass")
          }
          Text(scanner.isScanning ? "Scanning..." : "Scan Attachments")
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(scanner.isScanning)
      
      // Progress Bar
      if scanner.isScanning {
        VStack(spacing: 5) {
          ProgressView(value: scanner.scanProgress)
          Text(scanner.scanStatus)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      // Filters
      if !scanner.attachments.isEmpty {
        GroupBox("Filters") {
          VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
              HStack {
                Label("Older than:", systemImage: "calendar")
                  .frame(width: 100, alignment: .leading)
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                  ForEach(FilterTimeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                  }
                }
                .pickerStyle(.menu)
              }
              
              // Custom timeframe input
              if selectedTimeframe == .custom {
                HStack {
                  Spacer().frame(width: 100)
                  TextField("Value", text: $customTimeframeValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                  
                  Picker("Unit", selection: $customTimeframeUnit) {
                    ForEach(TimeUnit.allCases, id: \.self) { unit in
                      Text(unit.rawValue).tag(unit)
                    }
                  }
                  .pickerStyle(.menu)
                  .frame(width: 90)
                  
                  Spacer()
                }
              }
            }
            
            VStack(alignment: .leading, spacing: 5) {
              HStack {
                Label("Larger than:", systemImage: "internaldrive")
                  .frame(width: 100, alignment: .leading)
                
                Picker("File Size", selection: $selectedFileSize) {
                  ForEach(FilterFileSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                  }
                }
                .pickerStyle(.menu)
              }
              
              // Custom file size input
              if selectedFileSize == .custom {
                HStack {
                  Spacer().frame(width: 100)
                  TextField("Size", text: $customFileSize)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                  
                  Picker("Unit", selection: $customFileSizeUnit) {
                    ForEach(FileSizeUnit.allCases, id: \.self) { unit in
                      Text(unit.rawValue).tag(unit)
                    }
                  }
                  .pickerStyle(.menu)
                  .frame(width: 90)
                  
                  Spacer()
                }
              }
            }
            
            HStack {
              Label("File type:", systemImage: "doc")
                .frame(width: 100, alignment: .leading)
              
              Picker("File Type", selection: $selectedFileType) {
                ForEach(FileTypeCategory.allCases, id: \.self) { type in
                  Label(type.rawValue, systemImage: type.icon).tag(type)
                }
              }
              .pickerStyle(.menu)
            }
          }
        }
        .padding(.horizontal)
      }
      
      // Results
      if !filteredAttachments.isEmpty {
        VStack(spacing: 10) {
          HStack {
            Text("Results (\(filteredAttachments.count) files)")
              .font(.headline)
            
            Spacer()
            
            Button(selectedAttachments.count == filteredAttachments.count ? "Deselect All" : "Select All") {
              if selectedAttachments.count == filteredAttachments.count {
                selectedAttachments.removeAll()
              } else {
                selectedAttachments = Set(filteredAttachments)
              }
            }
            .buttonStyle(.borderless)
          }
          .padding(.horizontal)
          
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(filteredAttachments) { attachment in
                AttachmentRowView(
                  attachment: attachment,
                  isSelected: selectedAttachments.contains(attachment)
                ) { isSelected in
                  if isSelected {
                    selectedAttachments.insert(attachment)
                  } else {
                    selectedAttachments.remove(attachment)
                  }
                }
                
                if attachment != filteredAttachments.last {
                  Divider()
                    .padding(.leading, 50)
                }
              }
            }
          }
          .frame(maxHeight: 300)
          .background(Color(NSColor.controlBackgroundColor))
          .cornerRadius(8)
        }
      } else if !scanner.attachments.isEmpty {
        Text("No attachments match your filters")
          .foregroundColor(.secondary)
          .padding()
      }
      
      // Selection Summary and Actions
      if !selectedAttachments.isEmpty {
        VStack(spacing: 10) {
          HStack {
            Image(systemName: "externaldrive")
              .foregroundColor(.orange)
            Text("Selected: \(selectedAttachments.count) files (\(ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)))")
              .font(.headline)
            Spacer()
          }
          
          HStack(spacing: 15) {
            Button("Preview Folders") {
              // Open first few UUID folders in Finder for preview
              let urls = Array(selectedAttachments.prefix(5)).map { URL(filePath: $0.path) }
              NSWorkspace.shared.activateFileViewerSelecting(urls)
            }
            .buttonStyle(.bordered)
            
            Button("Copy to Folder") {
              showFolderPicker()
            }
            .buttonStyle(.bordered)
            
            Button("Move to Trash") {
              showingDeleteConfirmation = true
            }
            .buttonStyle(.borderedProminent)
          }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
      }
      
      Spacer()
    }
    .padding()
    .frame(width: 600, height: 700)
    .confirmationDialog(
      "Move \(selectedAttachments.count) attachments to Trash?",
      isPresented: $showingDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Move to Trash", role: .destructive) {
        let result = scanner.deleteAttachments(Array(selectedAttachments))
        selectedAttachments.removeAll()
        
        // Could show an alert with results here
        print("Deleted: \(result.success), Failed: \(result.failed)")
      }
      
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This will free up \(ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)) of disk space. Attachments can be restored from Trash.")
    }
    .confirmationDialog(
      "Copy \(selectedAttachments.count) attachments to selected folder?",
      isPresented: $showingCopyConfirmation,
      titleVisibility: .visible
    ) {
      Button("Copy to Folder") {
        if let destinationURL = selectedDestinationURL {
          let result = scanner.copyAttachments(Array(selectedAttachments), to: destinationURL)
          selectedAttachments.removeAll()
          selectedDestinationURL = nil
          
          // Could show an alert with results here
          print("Copied: \(result.success), Failed: \(result.failed)")
        }
      }
      
      Button("Cancel", role: .cancel) { 
        selectedDestinationURL = nil
      }
    } message: {
      if let destinationURL = selectedDestinationURL {
        Text("This will copy \(ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)) to:\n\(destinationURL.path)")
      }
    }
  }
  
  private func showFolderPicker() {
    let panel = NSOpenPanel()
    panel.message = "Select destination folder for attachments"
    panel.prompt = "Select Folder"
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.canCreateDirectories = true
    
    panel.begin { response in
      if response == .OK, let url = panel.url {
        selectedDestinationURL = url
        showingCopyConfirmation = true
      }
    }
  }
}

struct AttachmentRowView: View {
  let attachment: AttachmentItem
  let isSelected: Bool
  let onSelectionChanged: (Bool) -> Void
  
  var body: some View {
    HStack(spacing: 12) {
      Button(action: {
        onSelectionChanged(!isSelected)
      }) {
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
          .foregroundColor(isSelected ? .accentColor : .secondary)
      }
      .buttonStyle(.plain)
      
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Image(systemName: attachment.typeCategory.icon)
            .foregroundColor(.accentColor)
          
          Text(attachment.filename)
            .lineLimit(1)
            .truncationMode(.middle)
          
          Spacer()
          
          Text(attachment.sizeString)
            .foregroundColor(.secondary)
            .font(.caption)
        }
        
        Text(attachment.dateString)
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .contentShape(Rectangle())
    .onTapGesture {
      onSelectionChanged(!isSelected)
    }
  }
}

enum FileSizeUnit: String, CaseIterable {
  case kb = "KB"
  case mb = "MB"
  case gb = "GB"
  
  var multiplier: Int64 {
    switch self {
    case .kb: return 1_000
    case .mb: return 1_000_000
    case .gb: return 1_000_000_000
    }
  }
}

enum TimeUnit: String, CaseIterable {
  case days = "Days"
  case months = "Months"
  case years = "Years"
  
  var dayMultiplier: Int {
    switch self {
    case .days: return 1
    case .months: return 30
    case .years: return 365
    }
  }
}

#Preview {
    ContentView()
}