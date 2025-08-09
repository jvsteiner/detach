import SwiftUI

struct ContentView: View {
  @StateObject private var scanner = AttachmentScanner()
  @State private var selectedTimeframe: FilterTimeframe = .month
  @State private var selectedFileSize: FilterFileSize = .medium
  @State private var selectedFileType: FileTypeCategory = .all
  @State private var selectedAttachments: Set<AttachmentItem> = []
  @State private var showingDeleteConfirmation = false
  
  private var filteredAttachments: [AttachmentItem] {
    scanner.filteredAttachments(
      timeframe: selectedTimeframe,
      fileSize: selectedFileSize,
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

#Preview {
    ContentView()
}