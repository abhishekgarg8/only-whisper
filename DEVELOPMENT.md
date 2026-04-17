# DEVELOPMENT.md

This file provides guidance for working with this repository.

## Project Overview

**Typewriter App** — A macOS native app (Swift/SwiftUI) that records audio via global hotkey from any app, transcribes it via OpenAI's Whisper API, and pastes the result at the cursor position.

**Current State**: Phases 0–4 complete. Core services and UI are implemented. Phase 5 (full end-to-end integration) and beyond are pending.

## Common Commands

All commands run from the repo root or `codebase/` as noted:

```bash
# Build & run (development)
cd codebase && swift build
cd codebase && swift run

# Build app bundle (installs to ~/Applications)
./scripts/build.sh

# Run all unit tests
./scripts/test.sh
# or directly:
cd codebase && swift test

# Run a single test class
cd codebase && swift test --filter TypewriterAppTests.SettingsManagerTests

# Lint
./scripts/lint.sh
```

> The app requires **Accessibility permission** (for CGEvent global hotkey) and **Microphone permission**. If Accessibility is denied at launch, the hotkey is silently disabled.

## Architecture

Swift Package Manager project (`codebase/Package.swift`), macOS 13.0+, **zero external dependencies** — Apple frameworks only.

### Core Pipeline

```
Global hotkey press
  → GlobalHotkeyMonitor (CGEvent tap)
    → AppCoordinator (state machine)
      → AudioRecordingService (AVFoundation → AudioData)
        → OpenAIClient (multipart upload → Whisper API)
          → TextPastingService (NSPasteboard + Cmd+V)
            → TranscriptionStorage (append-only CSV, optional)
```

### Key Components

**`AppCoordinator`** (`Coordinators/AppCoordinator.swift`) — The central `@MainActor ObservableObject`. Owns all services, manages the state machine (`idle → recording → processing → pasting → error`), and orchestrates the full transcription pipeline. All component wiring lives here.

**Services** (`Services/`):
- `AudioRecordingService` — AVFoundation capture; M4A format; emits `AudioData` (raw bytes + duration)
- `GlobalHotkeyMonitor` — CGEvent tap; two independent hotkey bindings: push-to-talk (hold) and hands-free (toggle)
- `OpenAIClient` — async/await URLSession; multipart/form-data to Whisper endpoint
- `TextPastingService` — saves clipboard → writes text → simulates Cmd+V → restores original clipboard
- `SettingsManager` — UserDefaults-backed `AppSettings` (Codable); API key stored in UserDefaults for MVP (Keychain planned for Phase 6)
- `TranscriptionStorage` — append-only CSV at `~/Library/Application Support/Typewriter/transcriptions.csv`

**Views** (`Views/`): `MainWindowView` is a 3-tab container (Settings, Transcriptions, About). `OverlayController` manages a floating `NSPanel` (~2" × 0.5" pill) showing recording/processing/done/error states. `SoundBarsView` renders the animated audio visualizer.

**`PermissionsManager`** (singleton) — handles Accessibility (checked at startup; gates hotkey registration) and Microphone (requested lazily before first recording).

## Development Methodology (Gargagents)

Defined in `agents.md`:
- **Plan before coding**: write what/why/how in `plan/` first
- **Two-agent review**: Worker drafts plan, Expert Reviewer iterates 3× before coding begins
- **Tests outside codebase**: `tests/` (manual test cases) is separate from `codebase/Tests/` (XCTest unit tests)
- **Append-only logs**: never rewrite `logs/` or `history/` entries

## Key Documents

- `requirements/prd.md` — authoritative product requirements
- `plan/10-architecture.md` — detailed component design and data flows
- `plan/20-roadmap.md` — 8-phase roadmap with current status
- `plan/30-decisions.md` — 18 technical decisions with rationale
- `TESTING.md` — manual testing checklist and troubleshooting guide

## Important Principles

1. **Requirements authority**: Only `requirements/` is authoritative for product decisions
2. **Tests outside code**: keep `tests/` separate from `codebase/`
3. **Append-only logs**: never rewrite history in `logs/` or `history/`
4. **Always plan first**: write and review a plan before implementing new features
