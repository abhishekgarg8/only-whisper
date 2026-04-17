# Changelog

All notable changes to Only Whisper are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2026-04-15

### Initial release

**Core features**
- Global hotkey recording from any macOS app via CGEvent tap
- Two recording modes: push-to-talk (hold key) and hands-free (toggle)
- Default hotkeys: ⌥ Option (push-to-talk) and ⌃ Control (hands-free)
- Fully customizable hotkeys via Settings → Hotkeys

**Transcription**
- OpenAI GPT-4o Transcribe (default — best accuracy)
- OpenAI GPT-4o Mini Transcribe (faster, lower cost)
- OpenAI Whisper-1 (legacy)
- Custom instructions: format, style, language hints sent with every request

**User experience**
- Floating overlay pill showing recording / processing / done / error states
- Animated sound bars visualizer during recording (driven by real mic levels)
- Text pasted automatically at cursor position via NSPasteboard + simulated Cmd+V
- 5-minute maximum recording limit with 30-second warning
- Microphone disconnect detection with graceful error recovery

**Settings**
- OpenAI API key entry with live connection test
- Microphone selector (all connected audio input devices)
- Optional local transcription log (CSV at ~/Documents/Only Whisper/transcriptions.csv)
- Transcriptions tab with newest-first list, swipe-to-delete, delete all

**Permissions**
- In-app permission status for Microphone and Accessibility
- Grant buttons linked to System Settings
- Hotkeys automatically re-register when Accessibility is granted

**Distribution**
- Notarized DMG for direct (non-App Store) distribution
- Hardened Runtime entitlements (no sandbox — required for CGEvent tap + paste)
- Apple Silicon + Intel universal binary

---

<!-- Future releases will be prepended above this line -->
