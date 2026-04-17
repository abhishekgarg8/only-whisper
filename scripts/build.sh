#!/bin/bash
# Build and install Only Whisper locally (development)
#
# Usage:
#   ./scripts/build.sh           # debug build → ~/Applications or /Applications
#   ./scripts/build.sh --release # release build (no install, used by release.sh)
#
# For a distributable DMG, use scripts/release.sh instead.

set -e

RELEASE_MODE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --release) RELEASE_MODE=1; shift ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

echo "🔨 Building Only Whisper..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CODEBASE_DIR="$SCRIPT_DIR/../codebase"
cd "$CODEBASE_DIR"

if [[ "$RELEASE_MODE" -eq 1 ]]; then
    echo "Building release configuration..."
    swift build -c release 2>&1 | grep -v "^warning:" || true
    BINARY_PATH=$(find .build -name "TypewriterEntry" -path "*/release/*" | head -1)
    [[ -n "$BINARY_PATH" ]] && echo "✅ Release binary: $BINARY_PATH" || echo "❌ Release binary not found"
    exit 0
fi

# Debug build + local install
echo "Building debug..."
swift build 2>&1 | grep -v "^warning:" | grep -v "error: error: accessing build database" || true

# Find binary — SPM executable target is named TypewriterEntry
BINARY_PATH=""
for candidate in \
    ".build/arm64-apple-macosx/debug/TypewriterEntry" \
    ".build/debug/TypewriterEntry" \
    ".build/arm64-apple-macosx/debug/OnlyWhisper" \
    ".build/debug/OnlyWhisper"; do
    if [[ -f "$candidate" ]]; then
        BINARY_PATH="$candidate"
        break
    fi
done

if [ -z "$BINARY_PATH" ]; then
    echo "❌ Error: Binary not found. Run 'swift build' manually to see errors."
    exit 1
fi

echo "📦 Creating app bundle..."

APP_NAME="Only Whisper.app"
BINARY_NAME="OnlyWhisper"

if [ -w "/Applications" ]; then
    APP_PATH="/Applications/$APP_NAME"
else
    APP_PATH="$HOME/Applications/$APP_NAME"
    mkdir -p "$HOME/Applications"
fi

BUNDLE_CONTENTS="$APP_PATH/Contents"
BUNDLE_MACOS="$BUNDLE_CONTENTS/MacOS"
BUNDLE_RESOURCES="$BUNDLE_CONTENTS/Resources"

if [ -d "$APP_PATH" ]; then
    echo "🗑️  Removing old installation..."
    rm -rf "$APP_PATH"
fi

mkdir -p "$BUNDLE_MACOS" "$BUNDLE_RESOURCES"

echo "📋 Copying binary..."
cp "$BINARY_PATH" "$BUNDLE_MACOS/$BINARY_NAME"
chmod +x "$BUNDLE_MACOS/$BINARY_NAME"

echo "📋 Copying Info.plist..."
cp TypewriterApp/Info.plist "$BUNDLE_CONTENTS/Info.plist"

echo "📋 Copying app icon..."
if [ -f "TypewriterApp/Resources/AppIcon.icns" ]; then
    cp "TypewriterApp/Resources/AppIcon.icns" "$BUNDLE_RESOURCES/AppIcon.icns"
fi

echo ""
echo "✅ Only Whisper installed successfully!"
echo ""
echo "📍 Location: $APP_PATH"
echo ""
echo "🚀 To launch:"
echo "   open -a 'Only Whisper'"
echo "   (or press ⌘+Space and type 'Only Whisper')"
echo ""
echo "⚙️  First-time setup:"
echo "   1. Grant Microphone and Accessibility permissions in Settings"
echo "   2. Enter your OpenAI API key in the Settings tab"
echo "   3. Default hotkeys: ⌥ (hold) = push-to-talk, ⌃ (tap) = hands-free toggle"
echo ""
