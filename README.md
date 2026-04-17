# Only Whisper

**Speak. Type. Done.**

Only Whisper is a macOS app that transcribes your voice and instantly pastes the text wherever your cursor is — in any app, any text field, anywhere on your Mac.

Press a hotkey → speak → release → your words appear. No switching apps, no copy-paste, no friction.

---

## Features

- **Global hotkey** — works in every app (browser, email, Slack, Notion, VS Code, anything)
- **Two recording modes**
  - **Push-to-talk** — hold ⌥ Option to record, release to transcribe
  - **Hands-free** — tap ⌃ Control to start, tap again to stop
- **OpenAI transcription** — powered by GPT-4o Transcribe, GPT-4o Mini Transcribe, or Whisper-1
- **Instant paste** — text appears at your cursor automatically
- **Custom instructions** — tell it to format as bullet points, use British English, always capitalize names, etc.
- **Visual feedback** — a small floating overlay shows recording state with animated sound bars
- **Local transcription log** — optionally save everything to a CSV for review or export
- **Microphone selector** — choose which mic to use
- **Zero cloud storage** — audio stays on your Mac; only the transcription request goes to OpenAI

---

## Download

**[Download Only Whisper v1.0.0 →](https://gumroad.com/l/only-whisper)**

Requires macOS 13 Ventura or later · Apple Silicon + Intel

---

## Setup (2 minutes)

1. **Download** the DMG and drag Only Whisper to `/Applications`
2. **Launch** Only Whisper — it lives in the menu bar area (no Dock icon)
3. **Grant permissions** when prompted:
   - **Microphone** — to capture audio
   - **Accessibility** — to detect the global hotkey and paste text
4. **Add your OpenAI API key** in the Settings tab
   - Get one at [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
   - Costs ~$0.006/minute of audio (GPT-4o Transcribe) or ~$0.003/min (GPT-4o Mini)
5. **Start talking** — hold ⌥ Option and speak, or tap ⌃ Control to toggle

That's it.

---

## Hotkeys

| Action | Default key | Mode |
|--------|------------|------|
| Record while held | ⌥ Option | Push-to-talk |
| Toggle recording | ⌃ Control | Hands-free |

Both hotkeys are fully customizable in Settings → Hotkeys.

---

## Privacy

- Audio is recorded locally and sent only to OpenAI for transcription
- Nothing is stored by Only Whisper on any server
- Optional local CSV log is stored only on your Mac at `~/Documents/Only Whisper/transcriptions.csv`
- Your API key is stored in macOS UserDefaults (local to your Mac)
- Only Whisper is **not sandboxed** — this is required for global hotkey detection (CGEvent tap) and cursor-position text injection, which the App Store sandbox prohibits

---

## Requirements

- macOS 13 Ventura or later
- Apple Silicon (M1/M2/M3/M4) or Intel
- An OpenAI API key ([get one here](https://platform.openai.com/api-keys))

---

## Pricing

Available on [Gumroad](https://gumroad.com/l/only-whisper). Pay once, use forever. Free updates for v1.x.

---

## FAQ

**Does it work offline?**
No — transcription requires an internet connection to reach the OpenAI API.

**How much does transcription cost?**
With the default GPT-4o Transcribe model: ~$0.006 per minute of audio. A typical 10-second voice note costs less than $0.001.

**Can I use my own Whisper model?**
The app supports OpenAI's three transcription models: GPT-4o Transcribe (best quality), GPT-4o Mini Transcribe (faster/cheaper), and Whisper-1 (legacy). You can switch in Settings.

**Why does it need Accessibility permission?**
macOS requires Accessibility access for apps to monitor global keyboard events and inject keystrokes into other apps. Only Whisper uses this to detect your hotkey from any app and to simulate Cmd+V to paste.

**Is my API key safe?**
Your key is stored in macOS UserDefaults, which is local to your Mac and your user account. It is never sent anywhere except directly to OpenAI as an Authorization header.

**The overlay appeared but nothing was pasted — what happened?**
Make sure Accessibility permission is granted in System Settings → Privacy & Security → Accessibility. Without it, the paste step is silently skipped.

**Can I change the hotkey?**
Yes — Settings → Hotkeys. You can set any key or modifier combination for both push-to-talk and hands-free modes.

---

## Building from Source

```bash
# Prerequisites: Xcode Command Line Tools or Xcode.app, macOS 13+

git clone https://github.com/yourusername/only-whisper
cd only-whisper

# Build and install locally (debug)
./scripts/build.sh

# Run tests (requires Xcode.app)
./scripts/test.sh

# Build distributable DMG (requires Developer ID certificate)
./scripts/release.sh --version 1.0.0
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for full development documentation.

---

## Architecture

```
Global hotkey press (CGEvent tap)
  → AppCoordinator (state machine: idle → recording → processing → pasting)
    → AudioRecordingService (AVFoundation → M4A)
      → OpenAIClient (multipart/form-data → Whisper API)
        → TextPastingService (NSPasteboard + simulated Cmd+V)
          → TranscriptionStorage (optional CSV log)
```

Swift 6.1 · SwiftUI + AppKit · Swift Package Manager · Zero external dependencies

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## License

© 2026 Abhishek Garg. All rights reserved.

This software is sold commercially. You may use it on any Mac you own. Redistribution, resale, or reverse engineering is not permitted.
