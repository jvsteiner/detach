# Detach - iMessage Cleaner

<div align="center">
  <img src="Detach/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" alt="Detach Icon" width="128" height="128">
  
  **Free up gigabytes of storage by cleaning old iMessage attachments**
  
  [![GitHub release](https://img.shields.io/github/release/jvsteiner/detach.svg)](https://github.com/jvsteiner/detach/releases)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
</div>

## What is Detach?

Detach is a native macOS utility that helps you **reclaim storage space** by cleaning up old iMessage attachments. Over time, photos, videos, and files shared through Messages can accumulate **gigabytes of hidden storage** in `~/Library/Messages/Attachments/`. Detach makes it easy to find, review, and safely delete these files.

### 🎯 Perfect For:
- **Photographers** sharing high-resolution images
- **Content creators** sending large video files  
- **Professionals** exchanging documents and presentations
- **Anyone** running low on Mac storage space

## ✨ Features

### 🔍 **Smart Scanning**
- Automatically discovers all iMessage attachments
- Organizes files by UUID folders (how macOS stores them)
- Shows total size and file count for each attachment group

### 📊 **Flexible Filtering**
- **Time-based filtering**: Find files older than custom periods
  - Days, months, or years
  - Examples: "3 months", "180 days", "2 years"
- **Size-based filtering**: Target large files wasting space
  - Custom sizes with KB/MB/GB units
  - Examples: "50 MB+", "2.5 GB+", "500 KB+"
- **File type filtering**: Focus on specific content
  - Images, videos, audio, documents, plugin data

### 🗂️ **Bulk Management**
- Select individual files or entire categories
- Preview file locations in Finder before deleting
- Safe deletion (files moved to Trash, recoverable)
- Real-time storage savings calculation

### 🔐 **Privacy & Security**
- **100% offline** - no internet connection required
- **No data collection** - your files stay on your device
- **Code signed** with Developer ID for security
- **Open source** - inspect the code yourself

## 📥 Installation

### Download Release (Recommended)
1. Download the latest `Detach-X.X.X.dmg` from [Releases](https://github.com/jvsteiner/detach/releases)
2. Open the DMG file
3. Drag `Detach.app` to your Applications folder
4. Launch from Applications or Spotlight

### Build from Source
```bash
git clone https://github.com/jvsteiner/detach.git
cd detach
open Detach.xcodeproj
# Build and run in Xcode
```

## 🚀 Usage

### First Launch
1. **Grant Full Disk Access**: macOS will prompt you to allow Detach to access your iMessage attachments
   - Go to **System Settings > Privacy & Security > Full Disk Access**
   - Click the **+** button and add Detach
   - Restart the app

2. **Scan Attachments**: Click "Scan Attachments" to analyze your iMessage storage

### Finding Files to Delete
3. **Apply Filters**: Use the filter dropdowns to narrow down results
   - **"Older than"**: Select preset periods or choose "Custom" for exact days/months/years
   - **"Larger than"**: Select preset sizes or choose "Custom" for exact KB/MB/GB amounts
   - **"File type"**: Focus on images, videos, documents, etc.

4. **Review Results**: Browse the filtered list showing:
   - File names and types
   - File sizes and modification dates
   - Total storage impact

### Cleaning Up Storage  
5. **Select Files**: Click checkboxes or use "Select All" for bulk operations

6. **Preview (Optional)**: Click "Preview Folders" to see selected files in Finder

7. **Delete Safely**: Click "Move to Trash" to free up storage
   - Files are moved to Trash (not permanently deleted)
   - Can be recovered if needed
   - Real-time storage savings displayed

## 💾 System Requirements

- **macOS 13.0** or later
- **Full Disk Access** permission
- **~10 MB** of disk space for the app

## 🛡️ Privacy

Detach respects your privacy:

- ✅ **No network access** - works completely offline
- ✅ **No data collection** - nothing is tracked or sent anywhere  
- ✅ **Local processing only** - all scanning happens on your Mac
- ✅ **No file access** beyond iMessage attachments directory
- ✅ **Transparent code** - open source for full inspection

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup
1. Clone the repository
2. Open `Detach.xcodeproj` in Xcode 15+
3. Build and run the project
4. Make your changes and submit a PR

### Reporting Issues
Found a bug or have a feature request? Please [open an issue](https://github.com/jvsteiner/detach/issues).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with **SwiftUI** for native macOS performance
- Icon designed with care for the macOS ecosystem
- Inspired by the need to reclaim storage space on modern Macs

---

<div align="center">
  <strong>Free up space. Keep what matters. Delete what doesn't.</strong>
  <br><br>
  Made with ❤️ for the macOS community
</div>