#!/bin/bash
# =============================================================================
# Only Whisper — Release & Distribution Script (Option B: Direct / Gumroad)
#
# Usage:
#   ./scripts/release.sh [--version 1.0.0] [--identity "Developer ID Application: ..."]
#
# Prerequisites:
#   1. Xcode Command Line Tools (or Xcode.app) installed
#   2. Apple Developer account with a Developer ID Application certificate
#   3. App-specific password stored in Keychain:
#        xcrun notarytool store-credentials "onlywhisper-notarytool" \
#          --apple-id YOUR@EMAIL.COM \
#          --team-id YOURTEAMID \
#          --password xxxx-xxxx-xxxx-xxxx   # app-specific password
#   4. Run this script from the repository root
#
# What it does:
#   1. Builds a release binary (swift build -c release)
#   2. Creates "Only Whisper.app" bundle
#   3. Code-signs with Hardened Runtime + entitlements
#   4. Notarizes with Apple
#   5. Staples the notarization ticket to the app
#   6. Creates a distributable DMG (with /Applications symlink)
#   7. Notarizes the DMG
#   8. Staples the DMG
#
# Output:
#   dist/OnlyWhisper-<version>.dmg  — ready to upload to Gumroad
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — override via CLI args or environment variables
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEBASE_DIR="$REPO_ROOT/codebase"

APP_NAME="Only Whisper"        # Display name (with space) — used for .app and DMG volume
BINARY_NAME="OnlyWhisper"      # Executable name inside Contents/MacOS/
BUNDLE_ID="com.onlywhisper.app"
VERSION="${ONLYWHISPER_VERSION:-1.0.0}"
BUILD_NUMBER="${ONLYWHISPER_BUILD:-1}"

# Developer ID certificate — set via env or --identity flag
SIGNING_IDENTITY="${ONLYWHISPER_SIGNING_IDENTITY:-}"

# Notarization keychain profile created via notarytool store-credentials
NOTARYTOOL_PROFILE="${ONLYWHISPER_NOTARYTOOL_PROFILE:-onlywhisper-notarytool}"

DIST_DIR="$REPO_ROOT/dist"
APP_PATH="$DIST_DIR/${APP_NAME}.app"
DMG_PATH="$DIST_DIR/${BINARY_NAME}-${VERSION}.dmg"
ENTITLEMENTS="$CODEBASE_DIR/TypewriterApp.entitlements"

# ---------------------------------------------------------------------------
# Parse CLI arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --identity) SIGNING_IDENTITY="$2"; shift 2 ;;
        --profile) NOTARYTOOL_PROFILE="$2"; shift 2 ;;
        --skip-notarize) SKIP_NOTARIZE=1; shift ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

SKIP_NOTARIZE="${SKIP_NOTARIZE:-0}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo ""; echo "▶  $*"; }
ok()   { echo "   ✅ $*"; }
err()  { echo ""; echo "   ❌ $*"; exit 1; }
warn() { echo "   ⚠️  $*"; }

require_cmd() {
    command -v "$1" &>/dev/null || err "Required command not found: $1"
}

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
log "Preflight checks"

require_cmd swift
require_cmd codesign
require_cmd hdiutil
require_cmd xcrun

if [[ -z "$SIGNING_IDENTITY" ]]; then
    warn "ONLYWHISPER_SIGNING_IDENTITY not set — trying to auto-detect Developer ID..."
    SIGNING_IDENTITY="$(security find-identity -v -p codesigning \
        | grep "Developer ID Application" \
        | head -1 \
        | sed 's/.*"\(.*\)"/\1/')"
    if [[ -z "$SIGNING_IDENTITY" ]]; then
        err "No 'Developer ID Application' certificate found in Keychain.\n\nSet ONLYWHISPER_SIGNING_IDENTITY or pass --identity \"Developer ID Application: Your Name (TEAMID)\""
    fi
    ok "Auto-detected: $SIGNING_IDENTITY"
else
    ok "Signing identity: $SIGNING_IDENTITY"
fi

[[ -f "$ENTITLEMENTS" ]] || err "Entitlements file not found: $ENTITLEMENTS"
ok "Entitlements: $ENTITLEMENTS"

# ---------------------------------------------------------------------------
# Step 1: Clean build
# ---------------------------------------------------------------------------
log "Step 1/8 — Building release binary"

cd "$CODEBASE_DIR"

# Clean previous build artifacts
rm -rf .build/release 2>/dev/null || true

swift build -c release --arch arm64 --arch x86_64 2>&1 | grep -v "^warning:" || true

# SPM names binary after the executable target (TypewriterEntry)
BINARY_PATH=""
for candidate in \
    ".build/apple/Products/Release/TypewriterEntry" \
    ".build/release/TypewriterEntry" \
    ".build/arm64-apple-macosx/release/TypewriterEntry" \
    ".build/x86_64-apple-macosx/release/TypewriterEntry" \
    ".build/apple/Products/Release/OnlyWhisper" \
    ".build/release/OnlyWhisper"; do
    if [[ -f "$candidate" ]]; then
        BINARY_PATH="$candidate"
        break
    fi
done

[[ -n "$BINARY_PATH" ]] || err "Release binary not found. Run 'swift build -c release' manually to diagnose."
ok "Binary: $BINARY_PATH"

# ---------------------------------------------------------------------------
# Step 2: Assemble .app bundle
# ---------------------------------------------------------------------------
log "Step 2/8 — Assembling '${APP_NAME}.app' bundle"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

BUNDLE_CONTENTS="$APP_PATH/Contents"
BUNDLE_MACOS="$BUNDLE_CONTENTS/MacOS"
BUNDLE_RESOURCES="$BUNDLE_CONTENTS/Resources"

mkdir -p "$BUNDLE_MACOS" "$BUNDLE_RESOURCES"

# Copy binary — name it BINARY_NAME (no space) to match CFBundleExecutable
cp "$BINARY_PATH" "$BUNDLE_MACOS/$BINARY_NAME"
chmod +x "$BUNDLE_MACOS/$BINARY_NAME"

# Copy Info.plist
cp "$CODEBASE_DIR/TypewriterApp/Info.plist" "$BUNDLE_CONTENTS/Info.plist"

# Inject version into Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$BUNDLE_CONTENTS/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$BUNDLE_CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$BUNDLE_CONTENTS/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$BUNDLE_CONTENTS/Info.plist"

# Copy app icon
if [[ -f "$CODEBASE_DIR/TypewriterApp/Resources/AppIcon.icns" ]]; then
    cp "$CODEBASE_DIR/TypewriterApp/Resources/AppIcon.icns" "$BUNDLE_RESOURCES/AppIcon.icns"
    ok "App icon included"
fi

ok "Bundle assembled at $APP_PATH"

# ---------------------------------------------------------------------------
# Step 3: Code-sign with Hardened Runtime
# ---------------------------------------------------------------------------
log "Step 3/8 — Code-signing with Hardened Runtime"

# Sign the binary itself first
codesign \
    --force \
    --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGNING_IDENTITY" \
    --timestamp \
    "$BUNDLE_MACOS/$BINARY_NAME"

# Sign the .app bundle
codesign \
    --force \
    --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGNING_IDENTITY" \
    --timestamp \
    "$APP_PATH"

ok "Code-signed successfully"

# Verify
codesign --verify --deep --strict --verbose=2 "$APP_PATH" 2>&1 | grep -E "(valid|satisfies)" || true
spctl --assess --type execute --verbose "$APP_PATH" 2>&1 || warn "spctl assess failed — notarization will fix this"

# ---------------------------------------------------------------------------
# Step 4: Notarize the .app
# ---------------------------------------------------------------------------
if [[ "$SKIP_NOTARIZE" -eq 1 ]]; then
    warn "Skipping notarization (--skip-notarize flag set)"
else
    log "Step 4/8 — Notarizing '${APP_NAME}.app'"

    # Zip the app for submission (notarytool prefers zip for .app)
    ZIP_PATH="$DIST_DIR/${BINARY_NAME}-${VERSION}-notarize.zip"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$NOTARYTOOL_PROFILE" \
        --wait \
        --timeout 30m

    ok "Notarization complete"
    rm -f "$ZIP_PATH"

    # ---------------------------------------------------------------------------
    # Step 5: Staple the app
    # ---------------------------------------------------------------------------
    log "Step 5/8 — Stapling notarization ticket to '${APP_NAME}.app'"
    xcrun stapler staple "$APP_PATH"
    ok "Stapled"
fi

# ---------------------------------------------------------------------------
# Step 6: Create DMG
# ---------------------------------------------------------------------------
log "Step 6/8 — Creating DMG"

DMG_STAGING="$DIST_DIR/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# Copy app into staging
cp -R "$APP_PATH" "$DMG_STAGING/"

# Add symlink to /Applications
ln -s /Applications "$DMG_STAGING/Applications"

# Create temporary uncompressed DMG
TEMP_DMG="$DIST_DIR/${BINARY_NAME}-temp.dmg"
hdiutil create \
    -volname "${APP_NAME} ${VERSION}" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDRW \
    "$TEMP_DMG"

# Convert to compressed, read-only DMG
rm -f "$DMG_PATH"
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

rm -f "$TEMP_DMG"
rm -rf "$DMG_STAGING"

ok "DMG created: $DMG_PATH"

# ---------------------------------------------------------------------------
# Step 7: Code-sign the DMG
# ---------------------------------------------------------------------------
log "Step 7/8 — Signing DMG"
codesign \
    --force \
    --sign "$SIGNING_IDENTITY" \
    --timestamp \
    "$DMG_PATH"
ok "DMG signed"

# ---------------------------------------------------------------------------
# Step 8: Notarize the DMG
# ---------------------------------------------------------------------------
if [[ "$SKIP_NOTARIZE" -eq 1 ]]; then
    warn "Skipping DMG notarization (--skip-notarize flag set)"
else
    log "Step 8/8 — Notarizing DMG"
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARYTOOL_PROFILE" \
        --wait \
        --timeout 30m
    ok "DMG notarized"

    xcrun stapler staple "$DMG_PATH"
    ok "DMG stapled"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
DMG_SIZE=$(du -sh "$DMG_PATH" | cut -f1)

echo ""
echo "══════════════════════════════════════════════════════"
echo " ✅  Only Whisper v${VERSION} — Release Complete"
echo "══════════════════════════════════════════════════════"
echo ""
echo "  DMG:  $DMG_PATH"
echo "  Size: $DMG_SIZE"
echo ""
echo "  Next steps:"
echo "    1. Test the DMG on a clean Mac (or another user account)"
echo "    2. Upload $DMG_PATH to Gumroad as the product file"
echo "    3. Set your price and publish on Gumroad"
echo "    4. git tag v${VERSION} && git push --tags"
echo ""
echo "  Gumroad checklist:"
echo "    □ Product name: Only Whisper"
echo "    □ Price: \$X (your choice)"
echo "    □ File: $(basename "$DMG_PATH")"
echo "    □ Description: paste from README.md"
echo "    □ Cover image: add a screenshot"
echo "    □ Publish!"
echo ""
