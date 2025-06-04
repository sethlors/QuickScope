#!/bin/bash

# QuickScope Test Script
# Tests the Quick Look extension with various folder types

echo "🧪 Testing QuickScope Extension..."

# Test folders
TEST_FOLDERS=(
    "/Applications"
    "/Users/Shared"
    "/System/Library"
    "$HOME/Documents"
    "$HOME/Desktop"
)

echo "Available test folders:"
for i in "${!TEST_FOLDERS[@]}"; do
    folder="${TEST_FOLDERS[$i]}"
    if [ -d "$folder" ]; then
        echo "  $((i+1)). $folder ✅"
    else
        echo "  $((i+1)). $folder ❌ (not found)"
    fi
done

echo ""
echo "To test manually:"
echo "1. Build and run QuickScope in Xcode"
echo "2. In Finder, navigate to any folder above"
echo "3. Select the folder and press spacebar"
echo "4. You should see the QuickScope preview"

echo ""
echo "To test from command line:"
echo "  qlmanage -p /path/to/folder"

echo ""
echo "To reset Quick Look cache:"
echo "  qlmanage -r"
echo "  qlmanage -r cache"
