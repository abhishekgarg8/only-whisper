# Key Technical Decisions - Typewriter App

This document tracks major technical decisions, their rationale, and alternatives considered.

---

## D1: Native macOS vs Cross-Platform

**Decision**: Build as native macOS app using Swift/SwiftUI

**Why**:
- Global hotkey requires deep system integration (Carbon/CGEvent APIs)
- Accessibility features for text pasting work better with native APIs
- Audio recording with AVFoundation provides best quality and device control
- PRD specifies "minimalist Apple-like design" → SwiftUI is ideal
- Better performance and system resource usage
- Smaller app bundle size

**Alternatives Considered**:
- **Electron + React**: Easier cross-platform, but poor performance, large bundle (~200MB), limited system API access
- **React Native macOS**: Limited macOS API support, less mature ecosystem
- **Flutter**: Better than Electron, but still lacks deep macOS integration

**Trade-offs**:
- Pro: Best user experience, native feel, optimal performance
- Con: macOS-only (no Windows/Linux), requires Swift knowledge

**Status**: ✅ Decided

---

## D2: Audio Format for Recording

**Decision**: M4A (AAC codec) for in-memory recording

**Why**:
- OpenAI Whisper API accepts M4A format
- Smaller file size vs WAV (10x compression)
- Good quality at 64kbps bitrate
- Native support in AVFoundation
- Fast encoding/decoding

**Alternatives Considered**:
- **WAV**: Lossless, but huge files (~10MB per minute)
- **MP3**: Patent concerns, not natively supported in AVFoundation
- **Opus**: Better compression, but requires external library

**Trade-offs**:
- Pro: Good balance of quality, size, and compatibility
- Con: Lossy compression (but acceptable for speech)

**Status**: ✅ Decided

---

## D3: Global Hotkey Implementation

**Decision**: Use CGEvent tap API for global hotkey monitoring

**Why**:
- Modern API (recommended by Apple)
- Works on macOS 10.15+
- Better permission model (Accessibility)
- More reliable than Carbon Event Manager

**Alternatives Considered**:
- **Carbon Event Manager**: Deprecated, legacy API
- **NSEvent addGlobalMonitorForEvents**: Doesn't work when app is inactive
- **Third-party library** (e.g., MASShortcut): Adds dependency

**Trade-offs**:
- Pro: Official API, future-proof, reliable
- Con: Requires Accessibility permission (user must enable)

**Implementation Notes**:
- Register event tap with `.defaultTap` location
- Filter for key down events with configured modifiers
- Handle permission denied gracefully

**Status**: ✅ Decided

---

## D4: Text Pasting Mechanism

**Decision**: Clipboard injection + simulated Cmd+V (Approach 1)

**Why**:
- Most reliable across all applications
- Works with apps that don't support Accessibility API text insertion
- Simple implementation
- Preserves existing clipboard (save/restore pattern)

**Alternatives Considered**:
- **Accessibility API direct text insertion**: Unreliable, many apps don't support
- **AppleScript**: Slow, limited app support, security issues
- **Keyboard simulation** (typing each character): Very slow for long text

**Trade-offs**:
- Pro: Universal compatibility, fast, reliable
- Con: Briefly overwrites clipboard (mitigated by save/restore)

**Implementation**:
```swift
1. Save current clipboard content
2. Copy transcription to clipboard
3. Simulate Cmd+V via CGEvent
4. Wait 500ms
5. Restore original clipboard content
```

**Status**: ✅ Decided

---

## D5: API Key Storage

**Decision**: Store in macOS Keychain (production), UserDefaults (MVP)

**Why**:
- **Keychain**: Encrypted, secure, Apple-recommended for secrets
- **UserDefaults (MVP)**: Fast development iteration, acceptable for initial testing

**Alternatives Considered**:
- **Plain text file**: Insecure, easy to accidentally commit
- **Environment variables**: Not persistent across launches
- **Third-party secret managers**: Adds dependency

**Trade-offs**:
- Pro (Keychain): Secure, encrypted at rest, survives app deletion
- Con (Keychain): Slightly more complex API
- Pro (UserDefaults): Simple, fast to implement
- Con (UserDefaults): Not encrypted (acceptable for user's own API key)

**Migration Plan**:
- Phase 1 (MVP): Use UserDefaults for speed
- Phase 6 (Polish): Migrate to Keychain before release
- Provide migration path (auto-move from UserDefaults to Keychain)

**Status**: ✅ Decided (staged approach)

---

## D6: Transcription Storage Format

**Decision**: CSV file as append-only database

**Why**:
- Simple, human-readable format
- Easy to import into Excel/Google Sheets
- Low memory footprint (stream parsing)
- No external dependencies (use Foundation's CSV parsing)

**Alternatives Considered**:
- **SQLite**: Overkill for simple data, requires schema management
- **JSON**: Requires loading entire file into memory for append
- **Core Data**: Too heavy, unnecessary complexity
- **Plain text**: Harder to parse, no structure

**Trade-offs**:
- Pro: Simple, portable, human-readable, efficient
- Con: Limited querying (must load into memory for search)

**CSV Schema**:
```csv
timestamp,duration_seconds,text,instructions
2026-02-28T10:30:00Z,15.3,"Hello world",""
```

**File Rotation**: After 10,000 entries, archive to `transcriptions-YYYY-MM-DD.csv`

**Status**: ✅ Decided

---

## D7: UI Framework

**Decision**: SwiftUI for all UI components

**Why**:
- Modern, declarative, reactive
- Perfect for macOS 13.0+ target
- Built-in support for dark mode, accessibility
- Minimal boilerplate vs AppKit
- Easier to achieve minimalist design

**Alternatives Considered**:
- **AppKit (Storyboards)**: Legacy, more verbose, harder to maintain
- **AppKit (programmatic)**: More control, but more code

**Trade-offs**:
- Pro: Modern, clean code, easy animations, reactive
- Con: Some advanced features require AppKit bridging (NSPanel for overlay)

**Hybrid Approach**:
- Use SwiftUI for main window, settings, transcriptions
- Use NSPanel for overlay (wrapped in SwiftUI via NSViewRepresentable)

**Status**: ✅ Decided

---

## D8: State Management

**Decision**: Single AppCoordinator as ObservableObject

**Why**:
- Single source of truth for app state
- Simple, no external dependencies
- Works seamlessly with SwiftUI via @Published
- Easy to test and debug

**Alternatives Considered**:
- **Redux-like architecture**: Overkill for small app
- **Multiple ViewModels**: Harder to coordinate state across components
- **Combine publishers**: More complex than necessary

**State Machine**:
```swift
enum AppState {
    case idle
    case recording
    case processing
    case pasting
    case error(message: String)
}
```

**Status**: ✅ Decided

---

## D9: Audio Level Visualization

**Decision**: Real-time sound bars in overlay (30fps updates)

**Why**:
- PRD requirement: "pulsating sound bars showing input of mic recording"
- Provides visual feedback that app is listening
- Helps user confirm microphone is working

**Implementation**:
- Use AVAudioEngine's `installTap` to get audio buffer
- Calculate RMS (Root Mean Square) of audio samples
- Update sound bar heights based on RMS level
- Debounce updates to 30fps (every ~33ms)

**Visual Design**:
- 5-7 vertical bars
- Heights animate smoothly (spring animation)
- Color: accent color (blue) or green for active recording

**Trade-offs**:
- Pro: Engaging UX, confirms recording active
- Con: Requires real-time audio processing (minimal CPU impact)

**Status**: ✅ Decided

---

## D10: OpenAI API Model Selection

**Decision**: Support multiple Whisper models via dropdown

**Why**:
- PRD requirement: "choose which API to use so I can control costs"
- Different models have different pricing and capabilities
- Future-proof for new models

**Supported Models (initial)**:
- `whisper-1` (default)
- Future: `gpt-4-audio`, `whisper-large-v3` as they become available

**Settings UI**:
- Dropdown in Settings tab
- Show pricing info in tooltip (link to OpenAI pricing page)

**Status**: ✅ Decided

---

## D11: Error Handling Strategy

**Decision**: User-friendly error messages in overlay + detailed logs

**Why**:
- Non-technical users need clear guidance
- Developers need detailed logs for debugging
- Errors should never crash the app

**Error Categories**:
1. **User Errors**: Invalid API key, no mic selected
   - Show in overlay: "Check your API key in Settings"
   - Auto-recover to idle state

2. **Network Errors**: Timeout, rate limit, API down
   - Show in overlay: "Network error. Try again."
   - Offer retry option

3. **Permission Errors**: Mic or Accessibility denied
   - Show alert with system preferences link
   - Disable affected functionality

4. **System Errors**: Out of memory, disk full
   - Show generic error, log details
   - Attempt graceful degradation

**Logging**:
- Use `os_log` for system integration
- Log levels: debug, info, error
- Never log API keys or sensitive data

**Status**: ✅ Decided

---

## D12: Permission Request Flow

**Decision**: Request permissions on-demand, not at launch

**Why**:
- Better UX (contextual permission requests)
- Apple Human Interface Guidelines recommendation
- Users understand why permission is needed

**Flow**:
1. **Microphone**: Request when user first presses hotkey to record
   - If denied: Show alert with instructions

2. **Accessibility**: Request when app first launches
   - Show onboarding screen explaining need
   - Provide "Open System Preferences" button

**Permission Status Display**:
- Settings tab shows current status (✅ Granted / ❌ Denied)
- "Request Again" button if denied

**Status**: ✅ Decided

---

## D13: Smart Microphone Switching

**Decision**: Implement as P1 (post-MVP) feature

**Why**:
- PRD: "P1, It should also smartly switch mic to other mic if no audio is received"
- Not critical for MVP
- Requires additional complexity (silence detection, device enumeration)

**Implementation Plan**:
- Detect silence: No audio above threshold for 2 seconds
- Enumerate available devices
- Try next device in list
- Show notification in overlay: "Switched to [device name]"
- Log switch event

**Threshold**: -50 dBFS (decibels relative to full scale)

**Status**: ⏳ Deferred to Phase 5.3

---

## D14: Overlay Positioning

**Decision**: Center of screen (fixed position)

**Why**:
- Always visible regardless of cursor position
- Simpler implementation than cursor-following
- Doesn't obstruct active work area (user can still type/click)

**Alternatives Considered**:
- **Near cursor**: Complex, may obstruct text field
- **Top-right corner**: Less visible, easy to miss
- **Menu bar**: Requires separate menu bar app

**Future Enhancement**: Add setting to choose position

**Status**: ✅ Decided (center), open to future enhancement

---

## D15: Dependency Management

**Decision**: Zero external dependencies (use Apple frameworks only)

**Why**:
- Smaller app bundle
- No supply chain security risks
- Faster build times
- Simpler distribution

**Apple Frameworks Used**:
- SwiftUI (UI)
- AVFoundation (audio)
- AppKit (NSPanel, NSPasteboard)
- Combine (reactive)
- Foundation (networking, persistence)
- Carbon/CoreGraphics (events, hotkeys)

**Exception**: May add KeychainAccess library if Keychain API proves complex

**Status**: ✅ Decided

---

## D16: Build & Distribution

**Decision**: Distribute via .dmg (notarized), not Mac App Store

**Why**:
- Faster iteration (no App Store review)
- No sandbox restrictions (required for Accessibility API)
- Free to users (no App Store fee)
- Direct control over updates

**Notarization**: Required for macOS Gatekeeper
- Use `xcrun notarytool` for automated notarization
- Store credentials in Keychain

**Alternatives Considered**:
- **Mac App Store**: Sandbox incompatible with Accessibility features
- **Homebrew Cask**: Less discoverable for non-developers
- **TestFlight**: Beta only, not for production

**Status**: ✅ Decided

---

## D17: Testing Strategy

**Decision**: Unit tests for services, integration test for flow, manual for UI

**Why**:
- Services are pure logic (easy to unit test)
- Full flow requires integration testing (mock API)
- SwiftUI UI testing is verbose and brittle
- Manual testing ensures real-world usability

**Test Coverage Goals**:
- Unit tests: >80% coverage for services
- Integration: Full happy path + 10 error scenarios
- Manual: 20+ test cases across different apps and devices

**Tools**:
- XCTest (built-in)
- Mock URLSession for OpenAI client
- Mock AVFoundation for audio service

**Status**: ✅ Decided

---

## D18: Versioning & Updates

**Decision**: Semantic versioning (SemVer), GitHub releases

**Why**:
- Clear version numbers (1.0.0 → 1.1.0 → 2.0.0)
- GitHub releases provide changelog and download links
- Users can manually check for updates

**Version Format**: `MAJOR.MINOR.PATCH`
- MAJOR: Breaking changes (rare)
- MINOR: New features
- PATCH: Bug fixes

**Future Enhancement**: Auto-update using Sparkle framework

**Status**: ✅ Decided

---

## Open Decisions (To Be Resolved)

### OD1: Haptic Feedback on Hotkey
**Question**: Should app provide haptic feedback when hotkey is pressed?

**Considerations**:
- Pro: Tactile confirmation
- Con: MacBook trackpad only, not all Macs support
- PRD: Not mentioned

**Recommendation**: Add as optional setting (disabled by default)

**Status**: ⏳ To be decided in Phase 6

---

### OD2: Sound Effects
**Question**: Should app play sound on transcription complete?

**Considerations**:
- Pro: Audio confirmation (accessibility)
- Con: May be annoying in quiet environments
- PRD: Not mentioned

**Recommendation**: Add as optional setting (disabled by default)

**Status**: ⏳ To be decided in Phase 6

---

### OD3: Recording Duration Limit
**Question**: What's the maximum recording duration?

**Considerations**:
- OpenAI API: 25MB file size limit (~25 minutes at 64kbps)
- Memory: 5 minutes = ~2.4MB in memory
- UX: Most transcriptions <1 minute

**Recommendation**: 5-minute hard limit, show warning at 4 minutes

**Status**: ⏳ To be decided in Phase 1.2

---

### OD4: Multiple Language Support
**Question**: Should app support non-English transcription?

**Considerations**:
- OpenAI Whisper supports 99+ languages
- PRD: Not mentioned
- Implementation: Just pass language code to API

**Recommendation**: Support via API (automatic detection), add language selector in Phase 2+

**Status**: ⏳ To be decided (likely post-MVP)

---

## Decision Log Format

For future decisions, use this template:

```markdown
## DXX: [Decision Title]

**Decision**: [What we decided]

**Why**: [Rationale]

**Alternatives Considered**:
- **Option A**: [Why not chosen]
- **Option B**: [Why not chosen]

**Trade-offs**:
- Pro: [Benefits]
- Con: [Drawbacks]

**Status**: ✅ Decided / ⏳ Pending / ❌ Rejected
```

---

## Decision Review Schedule

Review all decisions at:
- End of Phase 5 (MVP Complete)
- Before Phase 8 (Distribution)
- Every major version release

Update this document when decisions change.
