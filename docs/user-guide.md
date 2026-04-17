# Typewriter User Guide

Welcome to Typewriter! This guide will help you get started with voice-to-text transcription on macOS.

## Table of Contents

1. [Installation](#installation)
2. [Initial Setup](#initial-setup)
3. [Basic Usage](#basic-usage)
4. [Settings](#settings)
5. [Troubleshooting](#troubleshooting)
6. [Tips & Best Practices](#tips--best-practices)

---

## Installation

### Requirements

- macOS 13.0 (Ventura) or later
- Microphone (built-in or external)
- Internet connection
- OpenAI API key ([Get one here](https://platform.openai.com/api-keys))

### Steps

1. Download the latest release from [GitHub Releases](https://github.com)
2. Open the `.dmg` file
3. Drag Typewriter to your Applications folder
4. Launch Typewriter from Applications

---

## Initial Setup

### 1. Grant Permissions

When you first launch Typewriter, you'll need to grant two permissions:

#### Microphone Permission
- Required to record your voice
- Click **"Grant"** in the Permissions section
- macOS will show a system dialog
- Click **"OK"** to allow

#### Accessibility Permission
- Required for global hotkey and auto-pasting
- Click **"Grant"** in the Permissions section
- macOS will open System Preferences
- Find Typewriter in the list and enable the checkbox
- You may need to restart Typewriter after granting

### 2. Enter Your OpenAI API Key

1. Go to the **Settings** tab
2. Enter your OpenAI API key in the **"OpenAI API Key"** field
   - Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
   - Keys start with `sk-`
3. Click **"Test API Connection"** to verify it works
   - ✅ Green checkmark = Success
   - ❌ Red X = Check your key

### 3. Configure Hotkey (Optional)

The default hotkey is **⌘⇧Space** (Command + Shift + Space).

To change it:
1. Click the hotkey display in Settings
2. Press your desired key combination
   - Must include at least one modifier (⌘, ⇧, ⌥, or ⌃)
   - Example: ⌘⌥T (Command + Option + T)

---

## Basic Usage

### Recording and Transcribing

1. **Start Recording**
   - Press your hotkey (default: ⌘⇧Space)
   - A small overlay appears with pulsating sound bars
   - Speak clearly into your microphone

2. **Stop Recording**
   - Press the hotkey again
   - The overlay shows "processing" with a spinner
   - Wait for transcription (usually 2-5 seconds)

3. **Text Pasted**
   - Transcribed text automatically appears at your cursor
   - The overlay shows "done" and disappears
   - Continue typing or working!

### Visual Feedback

The overlay shows different states:

- **Pulsating bars** = Recording in progress
- **"processing"** = Sending to OpenAI
- **"done"** ✓ = Success! Text pasted
- **"error"** ✗ = Something went wrong

---

## Settings

### API Configuration

**OpenAI API Key**
- Your personal API key from OpenAI
- Required for transcription
- Pay-per-use pricing (you control costs)

**API Model**
- Currently supports Whisper-1
- More models may be added in future updates

**Test API Connection**
- Verifies your API key works
- Shows success/error status
- Use before your first transcription

### Transcription Settings

**Custom Instructions**
- Add formatting preferences
- Examples:
  - "Format as bullet points"
  - "Use formal language"
  - "Add punctuation"
- Sent with every transcription

### Audio Input

**Microphone**
- Select which microphone to use
- Options include:
  - Built-in microphone
  - External USB microphones
  - Bluetooth headsets
- Falls back to system default if device disconnected

### Storage

**Save transcriptions locally**
- Toggle ON to keep a history
- Saved as CSV file in Documents/Typewriter/
- Toggle OFF to delete after each session

**Location**
- View where transcriptions are saved
- CSV format for easy import to Excel/Sheets

### Hotkey

**Global Hotkey**
- Keyboard shortcut to start/stop recording
- Works from any application
- Click to change the combination

---

## Troubleshooting

### Common Issues

#### "Microphone permission denied"

**Solution:**
1. Open System Preferences → Privacy & Security
2. Click **Microphone** in the left sidebar
3. Find Typewriter and enable the checkbox
4. Restart Typewriter

#### "Invalid API key"

**Solutions:**
- Check that key starts with `sk-`
- Verify you copied the entire key
- Check [OpenAI Platform](https://platform.openai.com/account/api-keys) for valid keys
- Ensure you have API credits available

#### Hotkey doesn't work

**Solutions:**
1. Check Accessibility permission is granted
2. Verify hotkey doesn't conflict with system shortcuts
3. Try a different key combination
4. Restart Typewriter after granting permissions

#### No audio recorded / silence

**Solutions:**
- Check microphone is selected correctly
- Verify microphone works in other apps
- Check system microphone volume
- Try speaking louder or closer to mic
- Grant microphone permission if prompted

#### Text doesn't paste

**Solutions:**
- Ensure Accessibility permission is granted
- Try clicking in a text field before recording
- Check that the target app accepts text input
- Some apps (like system dialogs) may block pasting

#### "Rate limit exceeded"

**Solution:**
- OpenAI limits requests per minute
- Wait 60 seconds and try again
- Check your API plan limits

---

## Tips & Best Practices

### For Best Transcription Quality

1. **Speak Clearly**
   - Enunciate words
   - Maintain steady pace
   - Avoid mumbling

2. **Quiet Environment**
   - Minimize background noise
   - Close windows if outside noise
   - Mute notifications during recording

3. **Good Microphone Position**
   - 6-12 inches from your mouth
   - Slightly off to the side (avoid plosives)
   - Use external mic for better quality

4. **Use Custom Instructions**
   - "Add punctuation and capitalize sentences"
   - "Use technical terminology"
   - "Format as a list with bullet points"

### Productivity Tips

1. **Learn the Hotkey**
   - Practice until it's muscle memory
   - Choose a combination that's easy to reach
   - Don't conflict with your other shortcuts

2. **Draft First, Edit Later**
   - Speak your thoughts quickly
   - Don't worry about perfect grammar
   - Edit the transcribed text afterward

3. **Use in Different Apps**
   - Email clients (Mail, Gmail)
   - Messaging apps (Slack, Messages)
   - Note-taking (Notes, Notion, Obsidian)
   - Code comments (Xcode, VS Code)
   - Documents (Word, Google Docs)

4. **Save Transcriptions**
   - Enable local storage for important recordings
   - Review history in Transcriptions tab
   - Export CSV for backup

### Cost Management

1. **Monitor Usage**
   - Check OpenAI dashboard for costs
   - Whisper API is very affordable (~$0.006 per minute)
   - Set up billing alerts in OpenAI

2. **Optimize Recordings**
   - Keep recordings concise
   - Pause between thoughts
   - Don't record silence

3. **API Key Security**
   - Don't share your API key
   - Regenerate if compromised
   - Use spending limits in OpenAI dashboard

---

## Keyboard Shortcuts

| Action | Default Shortcut | Customizable |
|--------|-----------------|--------------|
| Start/Stop Recording | ⌘⇧Space | ✓ Yes |
| Open Settings | ⌘, | ✗ No |
| Close Window | ⌘W | ✗ No |
| Quit App | ⌘Q | ✗ No |

---

## Data & Privacy

- **Audio is NOT stored**: Audio recordings are immediately discarded after transcription
- **Transcriptions**: Only saved locally if you enable the option
- **API Key**: Stored securely in macOS Keychain
- **OpenAI**: Audio is sent to OpenAI's Whisper API for processing (see [OpenAI Privacy Policy](https://openai.com/privacy))

---

## Getting Help

### Support Resources

- **Documentation**: [GitHub Wiki](https://github.com)
- **Issues**: [GitHub Issues](https://github.com)
- **Discussions**: [GitHub Discussions](https://github.com)

### Before Asking for Help

1. Check this guide's Troubleshooting section
2. Verify all permissions are granted
3. Test API connection in Settings
4. Check OpenAI dashboard for API issues
5. Try restarting the app

### Reporting Bugs

Include:
- macOS version
- Typewriter version
- Steps to reproduce
- Error messages (if any)
- Console logs (if applicable)

---

## What's Next?

- Explore custom instructions for your workflow
- Try using Typewriter in different applications
- Save useful transcriptions for later reference
- Share Typewriter with colleagues who type a lot!

**Happy transcribing! 🎤→📝**
