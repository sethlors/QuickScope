#!/bin/bash

# QuickScope Build Script
# This script builds the app and creates a DMG for distribution

set -e

PROJECT_NAME="QuickScope"
BUILD_DIR="build"
DIST_DIR="dist"
DMG_STAGING="dmg-staging"
DMG_NAME="QuickScope-1.0.dmg"
VERSION="1.0"

echo "🔨 Building QuickScope..."

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
rm -rf "$DMG_STAGING"
rm -f "$DMG_NAME"

# Build the project
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
           -scheme "$PROJECT_NAME" \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           build

echo "📦 Creating distribution package..."

# Create directories
mkdir -p "$DIST_DIR"
mkdir -p "$DMG_STAGING"

# Copy built app
APP_PATH="$BUILD_DIR/Build/Products/Release/$PROJECT_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Built app not found at $APP_PATH"
    exit 1
fi

cp -R "$APP_PATH" "$DIST_DIR/"
cp -R "$APP_PATH" "$DMG_STAGING/"

# Create Applications symlink for easy installation
ln -s /Applications "$DMG_STAGING/Applications"

# Create DMG
echo "💿 Creating DMG..."
# Create temporary DMG
hdiutil create -srcfolder "$DMG_STAGING" -volname "$PROJECT_NAME" -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" -format UDRW -size 50000k "temp-$DMG_NAME"

# Mount the temporary DMG
device=$(hdiutil attach -readwrite -noverify -noautoopen "temp-$DMG_NAME" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')

# Set DMG window properties
echo "🎨 Styling DMG..."
sleep 2
echo '
   tell application "Finder"
     tell disk "'$PROJECT_NAME'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 900, 400}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set position of item "'$PROJECT_NAME'.app" of container window to {150, 200}
           set position of item "Applications" of container window to {350, 200}
           close
           open
           update without registering applications
           delay 3
     end tell
   end tell
' | osascript

# Unmount and convert to read-only
hdiutil detach $device
hdiutil convert "temp-$DMG_NAME" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"
rm -f "temp-$DMG_NAME"

echo "✅ Build complete! DMG created: $DMG_NAME"
echo "📍 App location: $DIST_DIR/$PROJECT_NAME.app"
echo "💿 DMG file: $DMG_NAME"
echo ""
echo "To install:"
echo "1. Double-click $DMG_NAME"
echo "2. Drag QuickScope.app to Applications folder"
echo "3. Run QuickScope once to register the extension"
echo "4. Use spacebar on folders in Finder!"

# Clean up staging
rm -rf "$DMG_STAGING"
