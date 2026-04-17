# Plan Overview - Typewriter App

## What We're Building

A native macOS application that converts speech to text using OpenAI's transcription API, invokable via global hotkey from any application, with automatic text pasting at cursor position.

## Why

**Problem**: Knowledge workers waste 30-60 minutes daily typing, causing finger strain and reducing productivity.

**Opportunity**: Each minute saved is worth $1-5 per worker. A 20-minute daily savings = 2x productivity boost.

**Solution Value**:
- Zero context switching (global hotkey invocation)
- Zero editing needed (custom formatting instructions)
- Pay-per-use model (user's own OpenAI API key)
- Real-time visual feedback (pulsating sound bars overlay)

## How - Core User Flow

1. **Invocation**: User presses configured hotkey (e.g., Cmd+Shift+Space)
2. **Recording Start**: Small pill-shaped overlay appears with pulsating sound bars
3. **Recording Stop**: User presses hotkey again
4. **Processing**: Overlay shows spinning animation with "processing" text
5. **Transcription**: Audio sent to OpenAI API with custom instructions
6. **Paste**: Transcribed text automatically pasted at cursor position
7. **Completion**: Overlay shows "done" and disappears (or "error" if failed)

## Success Criteria

- Global hotkey works from any macOS application
- Recording → transcription → paste completes in <5 seconds for 30-second audio
- Overlay provides clear visual feedback for all states (recording, processing, done, error)
- Zero manual setup after initial API key entry
- Settings persist across sessions
- Transcriptions optionally saved locally for retrieval

## Constraints & Requirements

**Technical**:
- macOS native application (Swift/SwiftUI)
- Requires permissions: Accessibility, Microphone
- Must work with multiple audio input devices
- Must handle API failures gracefully

**Design**:
- Minimalist Apple-like aesthetic
- Small main window with 3 tabs: Settings, Transcriptions, About
- Pill-shaped overlay (~2" × 0.5")
- Artisanal, beautiful design craft

**User Experience**:
- Hotkey configurable in Settings
- Custom instructions field for formatting
- API key field (user provides own key)
- Microphone selector dropdown
- API type selector (OpenAI options)
- Optional local transcription storage (CSV)
- Smart mic switching if no audio detected
