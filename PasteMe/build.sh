#!/bin/bash

# PasteMe Build Script

set -e

echo "=== PasteMe Build Script ==="
echo ""

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing via Homebrew..."
    brew install xcodegen
fi

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "Project generated successfully!"
echo ""
echo "Next steps:"
echo "  1. Open in Xcode: open PasteMe.xcodeproj"
echo "  2. Build and run with ⌘R"
echo ""
echo "Or build from command line:"
echo "  xcodebuild -project PasteMe.xcodeproj -scheme PasteMe -configuration Release build"
echo ""
