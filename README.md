# Detach - iMessage Cleaner

A macOS utility app to clean up old iMessage attachments and free up disk space.

## Features

- Scans your iMessage attachments directory
- Shows file sizes and modification dates
- Allows bulk deletion of old attachments
- Clean, native macOS interface

## Building

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Developer ID certificate (for distribution)

### Development Build
```bash
# Open in Xcode
open Detach.xcodeproj

# Or build from command line
xcodebuild -project Detach.xcodeproj -scheme Detach -configuration Debug
```

### Distribution Build
```bash
# Use the build script to create a distributable package
./build_and_package.sh
```

This will create:
- `build/export/Detach.app` - The signed application
- `Detach-1.0.0.dmg` - DMG installer for distribution

## Installation

1. Download or build the app
2. Open the DMG file
3. Drag Detach.app to your Applications folder
4. Launch from Applications or Spotlight

**Security Note**: On first launch, macOS may show a security warning. Go to System Preferences > Privacy & Security and click "Open Anyway" to allow the app to run.

## Usage

1. Launch the app
2. Click "Scan Attachments" to analyze your iMessage attachments
3. Review the list of files and their sizes
4. Select files you want to delete
5. Click "Delete Selected" to free up space

## How It Works

Detach scans the `~/Library/Messages/Attachments` directory where macOS stores all iMessage attachments. It organizes files by their UUID folders and calculates total sizes, making it easy to identify and remove large or old attachments.

## Privacy

This app:
- Only accesses your local iMessage attachments directory
- Does not connect to the internet
- Does not collect or transmit any data
- Runs entirely on your device

## License

Copyright © 2025 Detach. All rights reserved.