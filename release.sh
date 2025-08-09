#!/bin/bash

# Detach App Release Script
# Packages the signed Xcode-built app into DMG and creates GitHub release

set -e  # Exit on any error

# Load configuration
source ./release-config.sh

APP_NAME="${APP_NAME:-Detach}"
VERSION="${APP_VERSION:-1.0.1}"
DMG_NAME="$APP_NAME-$VERSION.dmg"
TITLE="${RELEASE_TITLE:-$APP_NAME v$VERSION}"
NOTES="${RELEASE_NOTES:-Release notes for $APP_NAME v$VERSION}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting release process for $APP_NAME v$VERSION${NC}"

# Check if custom app path was provided
if [ -n "$CUSTOM_APP_PATH" ]; then
    if [ -d "$CUSTOM_APP_PATH" ]; then
        APP_PATH="$CUSTOM_APP_PATH"
        echo -e "${GREEN}✅ Using custom app path: $APP_PATH${NC}"
    else
        echo -e "${RED}❌ Error: Custom app path not found: $CUSTOM_APP_PATH${NC}"
        exit 1
    fi
else
    # Find the signed app in common locations
    APP_PATH=""
    SEARCH_LOCATIONS=(
        "./$APP_NAME.app"                           # Current directory
        "$HOME/Desktop/$APP_NAME.app"               # Desktop
        "$HOME/Downloads/$APP_NAME.app"             # Downloads
        "./build/$APP_NAME.app"                     # Build folder
        "./exported/$APP_NAME.app"                  # Exported folder
        "$HOME/Desktop/Apps/$APP_NAME.app"          # Desktop/Apps folder
    )
fi

# Only search if we don't have a custom path
if [ -z "$APP_PATH" ]; then
    echo -e "${BLUE}🔍 Looking for signed $APP_NAME.app...${NC}"

    for location in "${SEARCH_LOCATIONS[@]}"; do
        if [ -d "$location" ]; then
            APP_PATH="$location"
            echo -e "${GREEN}✅ Found signed app: $APP_PATH${NC}"
            break
        fi
    done

    if [ -z "$APP_PATH" ]; then
        echo -e "${RED}❌ Error: $APP_NAME.app not found in common locations${NC}"
        echo -e "${YELLOW}Searched in:${NC}"
        for location in "${SEARCH_LOCATIONS[@]}"; do
            echo -e "${YELLOW}  - $location${NC}"
        done
        echo ""
        echo -e "${YELLOW}💡 Solutions:${NC}"
        echo -e "${YELLOW}  1. Copy your exported Detach.app to: $(pwd)/${NC}"
        echo -e "${YELLOW}  2. Or use: ./release-with-app.sh /path/to/Detach.app${NC}"
        echo -e "${YELLOW}  3. Or drag the app into terminal to see its path${NC}"
        exit 1
    fi
fi

# Verify the app is signed
echo -e "${BLUE}🔐 Verifying code signature...${NC}"
if codesign -dv "$APP_PATH" 2>/dev/null; then
    echo -e "${GREEN}✅ App is properly signed${NC}"
else
    echo -e "${RED}❌ Warning: App may not be properly signed${NC}"
fi

# Clean up any existing DMG
echo -e "${BLUE}🧹 Cleaning up previous builds...${NC}"
rm -f "$DMG_NAME" *temp.dmg

# Create DMG
echo -e "${BLUE}📦 Creating DMG installer...${NC}"
DMG_TEMP="$APP_NAME-temp.dmg"

# Create temporary DMG
hdiutil create -size 50m -fs HFS+ -volname "$APP_NAME" "$DMG_TEMP"

# Mount the DMG
MOUNT_DIR=$(mktemp -d)
hdiutil attach "$DMG_TEMP" -mountpoint "$MOUNT_DIR" -nobrowse

# Copy app to DMG
cp -R "$APP_PATH" "$MOUNT_DIR/"

# Create Applications symlink for easy installation
ln -s /Applications "$MOUNT_DIR/Applications"

# Optional: Add a background image or custom layout
# (You can add this later if you want a custom DMG appearance)

# Unmount
hdiutil detach "$MOUNT_DIR"

# Convert to final compressed DMG
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_NAME"
rm "$DMG_TEMP"

echo -e "${GREEN}✅ DMG created: $DMG_NAME${NC}"

# Get DMG size
DMG_SIZE=$(du -h "$DMG_NAME" | cut -f1)
echo -e "${BLUE}📏 DMG size: $DMG_SIZE${NC}"

# Check if we have gh CLI installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found${NC}"
    echo -e "${YELLOW}To install: brew install gh${NC}"
    echo -e "${YELLOW}Then run: gh auth login${NC}"
    echo -e "${GREEN}✅ DMG ready for manual upload: $DMG_NAME${NC}"
    exit 0
fi

# Check if we're in a git repo and authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub CLI${NC}"
    echo -e "${YELLOW}Run: gh auth login${NC}"
    echo -e "${GREEN}✅ DMG ready for manual upload: $DMG_NAME${NC}"
    exit 0
fi

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️  Not in a git repository${NC}"
    echo -e "${YELLOW}Initialize with: git init && git remote add origin <your-repo-url>${NC}"
    echo -e "${GREEN}✅ DMG ready for manual upload: $DMG_NAME${NC}"
    exit 0
fi

# Get the repository name
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo -e "${YELLOW}⚠️  Could not determine repository${NC}"
    echo -e "${GREEN}✅ DMG ready for manual upload: $DMG_NAME${NC}"
    exit 0
fi

echo -e "${BLUE}📡 Repository: $REPO${NC}"

# Check if tag already exists
if git tag -l "v$VERSION" | grep -q "v$VERSION"; then
    echo -e "${YELLOW}⚠️  Tag v$VERSION already exists${NC}"
    echo -e "${YELLOW}Delete with: git tag -d v$VERSION && git push origin --delete v$VERSION${NC}"
    echo -e "${GREEN}✅ DMG ready for manual upload: $DMG_NAME${NC}"
    exit 0
fi

# Create and push tag
echo -e "${BLUE}🏷️  Creating and pushing tag v$VERSION...${NC}"
git tag "v$VERSION"
git push origin "v$VERSION"

# Create GitHub release
echo -e "${BLUE}🚀 Creating GitHub release...${NC}"
gh release create "v$VERSION" \
    --title "$TITLE" \
    --notes "$NOTES" \
    "$DMG_NAME"

echo -e "${GREEN}✅ Release created successfully!${NC}"
echo -e "${BLUE}🔗 View release: https://github.com/$REPO/releases/tag/v$VERSION${NC}"

# Cleanup
echo -e "${BLUE}🧹 Cleaning up temporary files...${NC}"
# Keep the DMG file for local use

echo -e "${GREEN}🎉 Release process complete!${NC}"
echo -e "${BLUE}📦 DMG: $DMG_NAME ($DMG_SIZE)${NC}"
echo -e "${BLUE}🔗 GitHub: https://github.com/$REPO/releases/tag/v$VERSION${NC}"
