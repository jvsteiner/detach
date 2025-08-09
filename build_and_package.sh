#!/bin/bash

# Detach App Build and Package Script
# Builds and packages the app for distribution without Xcode

set -e  # Exit on any error

APP_NAME="Detach"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME-1.0.0.dmg"

# Code signing configuration
DEVELOPER_ID="Apple Distribution: Jamie Steiner (X3U2KY97YV)"
TEAM_ID="X3U2KY97YV"

echo "🚀 Building and packaging $APP_NAME..."

# Clean up previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$APP_BUNDLE" build/ "$DMG_NAME" *temp.dmg

# Create app bundle structure
echo "📦 Creating app bundle structure..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Detach - iMessage Cleaner</string>
	<key>CFBundleExecutable</key>
	<string>Detach</string>
	<key>CFBundleIdentifier</key>
	<string>com.detachapp.detach</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>NSRequiresAquaSystemAppearance</key>
	<false/>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Detach</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2025 Detach. All rights reserved.</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSSupportsAutomaticTermination</key>
	<true/>
	<key>NSSupportsSuddenTermination</key>
	<true/>
</dict>
</plist>
EOF

# Compile Swift code
echo "🔨 Compiling Swift code..."
swiftc -target arm64-apple-macos13.0 \
       Detach/App.swift \
       Detach/ContentView.swift \
       Detach/AttachmentModel.swift \
       Detach/AttachmentScanner.swift \
       -o "$APP_BUNDLE/Contents/MacOS/Detach" \
       -framework SwiftUI \
       -framework Foundation \
       -framework AppKit

# Make executable
chmod +x "$APP_BUNDLE/Contents/MacOS/Detach"

# Sign the application
echo "🔐 Signing application with Developer ID..."
codesign --deep --force --options runtime --timestamp --entitlements Detach.entitlements --sign "$DEVELOPER_ID" "$APP_BUNDLE"

# Verify signing
echo "✅ Verifying code signature..."
codesign --verify --verbose=2 "$APP_BUNDLE"

# Copy resources if they exist
if [ -d "Detach/Assets.xcassets" ]; then
    echo "📁 Copying resources..."
    cp -R Detach/Assets.xcassets "$APP_BUNDLE/Contents/Resources/"
fi

echo "📦 Creating DMG installer..."
DMG_TEMP="$APP_NAME-temp.dmg"

# Create temporary DMG
hdiutil create -size 50m -fs HFS+ -volname "$APP_NAME" "$DMG_TEMP"

# Mount the DMG
MOUNT_DIR=$(mktemp -d)
hdiutil attach "$DMG_TEMP" -mountpoint "$MOUNT_DIR" -nobrowse

# Copy app to DMG
cp -R "$APP_BUNDLE" "$MOUNT_DIR/"

# Create Applications symlink for easy installation
ln -s /Applications "$MOUNT_DIR/Applications"

# Unmount
hdiutil detach "$MOUNT_DIR"

# Convert to final compressed DMG
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_NAME"
rm "$DMG_TEMP"

# Sign the DMG
echo "🔐 Signing DMG installer..."
codesign --timestamp --sign "$DEVELOPER_ID" "$DMG_NAME"

# Notarization (automatic if credentials are set up)
echo "🍎 Attempting notarization..."
if xcrun notarytool submit "$DMG_NAME" --keychain-profile "notarytool-password" --wait 2>/dev/null; then
  echo "✅ Notarization successful! Stapling ticket..."
  xcrun stapler staple "$DMG_NAME"
  echo "✅ DMG is now notarized and ready for distribution!"
else
  echo "⚠️  Notarization failed or not configured. DMG is signed but not notarized."
  echo ""
  echo "📋 To enable notarization for future builds:"
  echo "1. Create app-specific password at appleid.apple.com"
  echo "2. Run: xcrun notarytool store-credentials --team-id $TEAM_ID"
  echo "3. When prompted, use profile name: notarytool-password"
  echo "4. Rebuild with: ./build_and_package.sh"
  echo ""
  echo "🔧 Users can still install by right-clicking DMG > Open"
fi

echo "✅ Build complete!"
echo "📍 App bundle: $APP_BUNDLE"
echo "📍 DMG installer: $DMG_NAME"
echo ""
echo "To install:"
echo "1. Open $DMG_NAME"
echo "2. Drag $APP_NAME.app to Applications folder"
echo "3. Run from Applications or Spotlight"
echo ""
echo "To test locally:"
echo "open $APP_BUNDLE"