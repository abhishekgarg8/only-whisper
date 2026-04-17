# Testing Typewriter Locally

## Prerequisites

1. **macOS 13.0+** (Ventura or later)
2. **Swift 5.9+** (comes with Xcode Command Line Tools)
3. **OpenAI API Key** - Get one from [OpenAI Platform](https://platform.openai.com/api-keys)

## Option 1: Run from Terminal (Simplest)

### Step 1: Build the App

```bash
cd /Users/abhishekgarg/Desktop/AI Projects/only-whisper/codebase
swift build
```

Build output will be at:
```
.build/arm64-apple-macosx/debug/Typewriter
```

### Step 2: Run the App

**Important**: The app requires a GUI environment and won't run from pure terminal.

```bash
# This will try to launch but may fail without proper GUI context
./.build/arm64-apple-macosx/debug/Typewriter
```

**Better approach**: Use Xcode or create an app bundle (see Option 2 below)

---

## Option 2: Create App Bundle (Recommended for Testing)

Since SwiftUI apps need to run as proper macOS applications, create an app bundle:

### Step 1: Build Release Version

```bash
cd /Users/abhishekgarg/Desktop/AI Projects/only-whisper/codebase
swift build -c release
```

### Step 2: Create App Bundle Structure

```bash
# Create app bundle structure
mkdir -p ~/Desktop/Typewriter.app/Contents/MacOS
mkdir -p ~/Desktop/Typewriter.app/Contents/Resources

# Copy binary
cp .build/arm64-apple-macosx/release/Typewriter ~/Desktop/Typewriter.app/Contents/MacOS/

# Copy Info.plist
cp TypewriterApp/Info.plist ~/Desktop/Typewriter.app/Contents/Info.plist
```

### Step 3: Make Binary Executable

```bash
chmod +x ~/Desktop/Typewriter.app/Contents/MacOS/Typewriter
```

### Step 4: Launch the App

```bash
# Open from Finder
open ~/Desktop/Typewriter.app

# Or from terminal
open -a ~/Desktop/Typewriter.app
```

---

## Option 3: Use Xcode (Best for Development)

### Step 1: Open in Xcode

```bash
cd /Users/abhishekgarg/Desktop/AI Projects/only-whisper/codebase
open Package.swift
```

This will open the project in Xcode.

### Step 2: Configure Scheme

1. In Xcode, select **Product > Scheme > Edit Scheme**
2. Ensure "Typewriter" is selected
3. Under "Run" → "Info", check that the executable is set to "Typewriter"

### Step 3: Run

Press **⌘R** or click the Play button in Xcode.

The app will launch in a simulator or directly on your Mac.

---

## Initial Setup After Launch

### 1. Grant Permissions

When you first launch, you'll see the **Settings** tab with permission status:

#### Microphone Permission
1. Click the **"Grant"** button next to Microphone
2. macOS will show a system dialog
3. Click **"OK"** to allow

#### Accessibility Permission
1. Click the **"Grant"** button next to Accessibility
2. macOS will open **System Preferences**
3. Navigate to **Privacy & Security** → **Accessibility**
4. Find **Typewriter** in the list
5. Enable the checkbox
6. **Restart Typewriter** after granting

### 2. Enter Your OpenAI API Key

1. In the **Settings** tab, find **API Configuration**
2. Paste your OpenAI API key in the **"OpenAI API Key"** field
   - Get a key from: https://platform.openai.com/api-keys
   - Keys start with `sk-`
3. Click **"Test API Connection"** to verify
   - ✅ Green checkmark = Success!
   - ❌ Red X = Check your key

### 3. Configure Hotkey (Optional)

The default hotkey is **⌘⇧Space** (Command + Shift + Space).

To change:
1. Click the hotkey display
2. Click "Press keys..."
3. Press your desired combination (must include a modifier)

---

## Testing the App

### Basic Test: Record and Transcribe

1. **Open a text editor** (Notes, TextEdit, VS Code, etc.)
2. **Click in a text field** to place your cursor
3. **Press the hotkey** (⌘⇧Space by default)
   - You should see a small overlay with pulsating sound bars
4. **Speak clearly** into your microphone:
   - Try: "Hello, this is a test of the Typewriter app."
5. **Press the hotkey again** to stop recording
   - Overlay shows "processing"
   - Wait 2-5 seconds
   - Overlay shows "done"
6. **Check the text field** - your transcription should appear!

### Expected Behavior

**Visual Feedback**:
- **Recording**: Overlay with blue pulsating bars
- **Processing**: Overlay with spinner + "processing" text
- **Success**: Green checkmark + "done" text (1 second)
- **Error**: Red X + error message (3 seconds)

**Audio Flow**:
1. Hotkey press → Recording starts
2. Speak → Audio captured
3. Hotkey press → Recording stops, processing begins
4. API call → OpenAI transcribes
5. Text paste → Appears at cursor
6. Done → Overlay disappears

### Test Different Applications

Try recording in various apps:
- **Notes.app**: ✓ Should work
- **TextEdit**: ✓ Should work
- **Google Chrome** (Gmail, Google Docs): ✓ Should work
- **Slack**: ✓ Should work
- **VS Code**: ✓ Should work
- **Terminal**: ✓ Should work (try in vim or nano)

### Check Transcription History

If you enabled "Save transcriptions locally":

1. Go to the **Transcriptions** tab
2. You should see your recordings listed
3. Search works in the search bar
4. Click a transcription to see details

---

## Troubleshooting

### App Won't Launch

**Issue**: Binary won't run from terminal

**Solution**:
```bash
# Check if it's executable
ls -la .build/arm64-apple-macosx/debug/Typewriter

# Make executable if needed
chmod +x .build/arm64-apple-macosx/debug/Typewriter
```

**Issue**: "App is damaged and can't be opened"

**Solution**:
```bash
# Remove quarantine attribute
xattr -cr ~/Desktop/Typewriter.app
```

### Hotkey Doesn't Work

**Checklist**:
- [ ] Accessibility permission granted?
- [ ] App restarted after granting permission?
- [ ] Hotkey conflict with system shortcut?
- [ ] Try different key combination

**Check Permissions**:
```bash
# Open System Preferences
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

### No Audio Recorded

**Checklist**:
- [ ] Microphone permission granted?
- [ ] Correct microphone selected in Settings?
- [ ] Microphone working in other apps (Photo Booth)?
- [ ] Speak closer to microphone

**Test Microphone**:
1. Open **System Preferences** → **Sound** → **Input**
2. Speak and watch the input level bars
3. Ensure level is moving

### API Errors

**"Invalid API key"**:
- Verify key starts with `sk-`
- Check you copied the entire key
- Verify key is active in OpenAI dashboard

**"Rate limit exceeded"**:
- Wait 60 seconds
- Check your OpenAI plan limits
- Verify you have API credits

**"Network error"**:
- Check internet connection
- Try: `curl https://api.openai.com` to test connectivity

### Text Doesn't Paste

**Checklist**:
- [ ] Accessibility permission granted?
- [ ] Cursor was in a text field?
- [ ] Target app accepts text input?

**Note**: Some apps block automated pasting (e.g., password fields, some system dialogs)

---

## Running Unit Tests

```bash
cd /Users/abhishekgarg/Desktop/AI Projects/only-whisper/codebase

# Run all tests
swift test

# Run specific test file
swift test --filter SettingsManagerTests

# Verbose output
swift test --verbose
```

Expected output:
```
Test Suite 'All tests' started at ...
Test Suite 'SettingsManagerTests' started at ...
Test Case '-[SettingsManagerTests testDefaultSettings]' passed (0.001 seconds).
Test Case '-[SettingsManagerTests testSaveAndLoadSettings]' passed (0.002 seconds).
...
Test Suite 'All tests' passed at ...
     Executed 17 tests, with 0 failures (0 unexpected)
```

---

## Debugging

### Enable Debug Logging

The app prints debug info to Console.app:

1. Open **Console.app** (in /Applications/Utilities/)
2. Filter for "Typewriter" in the search bar
3. Run the app and watch for logs

### Check for Crashes

```bash
# View crash reports
open ~/Library/Logs/DiagnosticReports/
```

Look for `Typewriter-*.crash` files.

### Common Debug Messages

- `"⚠️ Accessibility permission not granted - hotkey disabled"` → Grant permission
- `"Testing API connection..."` → API test in progress
- Error logs will show in red in Console

---

## Performance Testing

### Test Audio Conversion Speed

1. Record 30 seconds of audio
2. Note the time from "processing" to "done"
3. Should be < 5 seconds total

### Test Memory Usage

```bash
# While app is running
ps aux | grep Typewriter

# Or use Activity Monitor
open -a "Activity Monitor"
```

Memory usage should be < 100MB during recording.

---

## Next Steps After Testing

### If Everything Works:

1. Test with longer recordings (1-2 minutes)
2. Test with different accents/voices
3. Test custom instructions feature
4. Test transcription history
5. Try different microphones

### If Issues Found:

1. Check Console.app for error logs
2. Verify all permissions granted
3. Test with minimal API call (just "test")
4. Report issues with:
   - macOS version
   - Steps to reproduce
   - Console logs
   - Screenshots if relevant

---

## Cleanup (When Done Testing)

```bash
# Remove app bundle
rm -rf ~/Desktop/Typewriter.app

# Clean build artifacts
cd /Users/abhishekgarg/Desktop/AI Projects/only-whisper/codebase
rm -rf .build

# Remove saved transcriptions (optional)
rm -rf ~/Documents/Typewriter/
```

---

## Quick Reference

**Build**: `swift build`
**Run Tests**: `swift test`
**Create App Bundle**: Copy to `~/Desktop/Typewriter.app/Contents/MacOS/`
**Launch**: `open ~/Desktop/Typewriter.app`
**Default Hotkey**: ⌘⇧Space

**Need Help?**
- Check `docs/user-guide.md` for detailed usage
- Check `docs/developer-guide.md` for technical details
- Check Console.app for debug logs
