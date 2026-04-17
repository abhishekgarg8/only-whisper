# Technical Architecture - Typewriter App

## Technology Stack

### Platform & Framework
- **macOS Native**: Swift 5.9+, SwiftUI for UI
- **Target**: macOS 13.0+ (Ventura and above)
- **Build System**: Xcode 15+, SPM (Swift Package Manager)

### Core Technologies
- **Audio Recording**: AVFoundation (AVAudioEngine, AVAudioRecorder)
- **Global Hotkey**: Carbon Event Manager or CGEvent APIs
- **Clipboard/Paste**: NSPasteboard + Accessibility APIs for injection
- **HTTP Client**: URLSession for OpenAI API calls
- **Persistence**: UserDefaults for settings, FileManager for CSV transcriptions
- **UI**: SwiftUI for main window, NSPanel for overlay

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Typewriter App                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐    ┌──────────────┐   ┌───────────┐  │
│  │   Main UI    │    │   Overlay    │   │  Hotkey   │  │
│  │   Window     │    │    Panel     │   │  Monitor  │  │
│  │ (SwiftUI)    │    │  (NSPanel)   │   │ (Global)  │  │
│  └──────┬───────┘    └──────┬───────┘   └─────┬─────┘  │
│         │                   │                  │        │
│  ┌──────┴───────────────────┴──────────────────┴─────┐  │
│  │           Application Coordinator                 │  │
│  │         (State Management & Orchestration)        │  │
│  └──────┬────────────────┬─────────────────┬─────────┘  │
│         │                │                 │            │
│  ┌──────┴──────┐  ┌──────┴─────┐  ┌───────┴────────┐   │
│  │   Audio     │  │  OpenAI    │  │   Settings     │   │
│  │  Recording  │  │   Client   │  │   Manager      │   │
│  │  Service    │  │            │  │                │   │
│  └──────┬──────┘  └──────┬─────┘  └───────┬────────┘   │
│         │                │                 │            │
│  ┌──────┴──────┐  ┌──────┴─────┐  ┌───────┴────────┐   │
│  │ AVFoundation│  │ URLSession │  │  UserDefaults  │   │
│  │   (Apple)   │  │   (Apple)  │  │    (Apple)     │   │
│  └─────────────┘  └────────────┘  └────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Application Coordinator
**What**: Central state manager and orchestrator for the entire app lifecycle.

**Why**: Single source of truth for app state, coordinates between UI, services, and system events.

**How**:
- Implements `ObservableObject` for SwiftUI reactivity
- Manages app states: `.idle`, `.recording`, `.processing`, `.pasting`, `.error`
- Coordinates hotkey events → audio recording → API calls → text pasting
- Handles permissions checking and requesting

**Key Properties**:
```swift
@Published var appState: AppState
@Published var currentRecording: AudioRecording?
@Published var errorMessage: String?
let settingsManager: SettingsManager
let audioService: AudioRecordingService
let openAIClient: OpenAIClient
let hotkeyMonitor: GlobalHotkeyMonitor
```

### 2. Global Hotkey Monitor
**What**: System-wide keyboard event listener for hotkey detection.

**Why**: Must work from any application, not just when Typewriter is active.

**How**:
- Use CGEvent tap or Carbon Event Manager
- Register global event handler for configured key combination
- Convert key codes to hotkey configuration (modifiers + key)
- Trigger coordinator callback on hotkey press

**Approach**:
```swift
class GlobalHotkeyMonitor {
    private var eventTap: CFMachPort?
    var onHotkeyPressed: (() -> Void)?

    func register(hotkey: HotkeyConfiguration)
    func unregister()
}
```

### 3. Audio Recording Service
**What**: Manages audio input device selection, recording, and audio buffer management.

**Why**: Core functionality - must capture high-quality audio for transcription.

**How**:
- Use AVAudioEngine for flexible audio routing
- Enumerate available input devices via AVCaptureDevice
- Record to in-memory buffer (WAV/M4A format)
- Monitor audio levels for visual feedback (sound bars)
- Implement smart mic switching (detect silence, switch to alternate)

**Key Methods**:
```swift
class AudioRecordingService {
    func listAvailableDevices() -> [AudioDevice]
    func startRecording(device: AudioDevice) throws
    func stopRecording() -> AudioData
    func getCurrentAudioLevel() -> Float // For visualizer
    func switchToDevice(device: AudioDevice)
}
```

### 4. OpenAI Client
**What**: HTTP client for OpenAI Whisper/Transcription API.

**Why**: External dependency for speech-to-text conversion.

**How**:
- Use URLSession for async/await HTTP requests
- Implement multipart/form-data upload for audio files
- Support multiple OpenAI API endpoints (Whisper v1, future versions)
- Include custom instructions in API payload
- Handle rate limits, timeouts, network errors

**API Contract**:
```swift
class OpenAIClient {
    func transcribe(
        audio: Data,
        apiKey: String,
        customInstructions: String?,
        model: OpenAIModel
    ) async throws -> TranscriptionResponse
}
```

**OpenAI API Format**:
```
POST https://api.openai.com/v1/audio/transcriptions
Headers:
  Authorization: Bearer {api_key}
  Content-Type: multipart/form-data

Body:
  file: audio.m4a
  model: whisper-1
  prompt: {custom_instructions}
```

### 5. Settings Manager
**What**: Persistent storage for user preferences and configuration.

**Why**: Settings must persist across app launches.

**How**:
- Use UserDefaults for lightweight settings (API key, hotkey, preferences)
- Implement Codable models for type-safe storage
- Provide reactive updates via Combine publishers
- Secure API key storage (consider Keychain for production)

**Settings Schema**:
```swift
struct AppSettings: Codable {
    var hotkeyConfiguration: HotkeyConfiguration
    var openAIApiKey: String
    var customInstructions: String
    var selectedMicrophone: String // Device ID
    var selectedAPIModel: OpenAIModel
    var saveTranscriptionsLocally: Bool
    var transcriptionStoragePath: URL
}
```

### 6. Transcription Storage
**What**: CSV-based append-only database for local transcription history.

**Why**: Users want to retrieve past transcriptions.

**How**:
- Store as CSV: timestamp, audio_duration, transcribed_text, custom_instructions
- Append new rows after each successful transcription
- Load into memory for Transcriptions tab display
- Implement search/filter functionality
- Optional: Delete on session end if setting disabled

**CSV Format**:
```csv
timestamp,duration_seconds,text,instructions
2026-02-28T10:30:00Z,15.3,"Hello world example",""
```

### 7. Main Window UI
**What**: Primary application window with 3 tabs.

**Why**: Central hub for settings and transcription history.

**How**:
- SwiftUI TabView with 3 tabs
- **Settings Tab**: Form with all user preferences
- **Transcriptions Tab**: List/table of saved transcriptions
- **About Tab**: App info, version, links

**Settings Tab Components**:
- Hotkey recorder button (shows current, allows change)
- API key secure text field
- Custom instructions multi-line text editor
- Microphone dropdown picker
- API model dropdown picker
- Toggle for local storage
- "Test API" button

### 8. Overlay Panel
**What**: Floating, always-on-top pill-shaped UI with visual feedback.

**Why**: User needs real-time feedback without switching apps.

**How**:
- Use NSPanel with `.hudWindow` or custom borderless window
- Set window level to `.floating` (always on top)
- Position near cursor or center of screen
- States:
  - **Recording**: Pulsating sound bars (animated based on audio levels)
  - **Processing**: Spinning indicator + "processing" text
  - **Done**: Checkmark + "done" text (dismisses after 1s)
  - **Error**: X icon + "error" text (dismisses after 3s)

**Visual Design**:
- Size: ~200pt width × 50pt height
- Corner radius: 25pt (pill shape)
- Backdrop: Frosted glass effect (`.ultraThinMaterial`)
- Colors: System adaptive (white/black based on appearance)
- Animation: Smooth spring animations

### 9. Text Pasting Service
**What**: Injects transcribed text at cursor position in active application.

**Why**: Core value prop - automatic pasting without manual action.

**How**:
- **Approach 1**: Copy to clipboard + simulate Cmd+V via CGEvent
- **Approach 2**: Use Accessibility API to insert text directly (requires permission)
- Recommended: Approach 1 (more reliable, less intrusive)

**Implementation**:
```swift
class TextPastingService {
    func pasteText(_ text: String) {
        // 1. Save current clipboard
        let savedClipboard = NSPasteboard.general.string(forType: .string)

        // 2. Copy transcription to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        // 3. Simulate Cmd+V
        simulateKeyPress(key: .v, modifiers: .command)

        // 4. Restore clipboard after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSPasteboard.general.setString(savedClipboard ?? "", forType: .string)
        }
    }
}
```

## Data Flow

### Happy Path: User Transcription Flow

1. **User presses hotkey** (e.g., Cmd+Shift+Space)
   - GlobalHotkeyMonitor detects event
   - Calls coordinator.handleHotkeyPress()

2. **Coordinator starts recording**
   - Changes state to `.recording`
   - Calls audioService.startRecording(device: selectedMic)
   - Shows overlay panel in "recording" state

3. **User speaks, audio captured**
   - AudioService streams audio to buffer
   - Calculates audio levels for visualizer
   - Overlay sound bars pulsate based on levels

4. **User presses hotkey again**
   - GlobalHotkeyMonitor detects event
   - Calls coordinator.handleHotkeyPress()
   - Coordinator stops recording

5. **Processing begins**
   - Changes state to `.processing`
   - Overlay switches to "processing" animation
   - Calls audioService.stopRecording() → returns AudioData
   - Calls openAIClient.transcribe(audio, apiKey, instructions, model)

6. **API returns transcription**
   - Receives TranscriptionResponse with text
   - Saves to CSV if setting enabled
   - Calls textPastingService.pasteText(transcription)

7. **Text pasted**
   - Changes state to `.idle`
   - Overlay shows "done" for 1 second
   - Overlay dismisses

### Error Handling

**Microphone Permission Denied**:
- Show alert with instructions to enable in System Preferences
- Disable recording functionality

**No Audio Detected**:
- After 2 seconds of silence during recording, show warning
- Attempt smart mic switch to alternate device
- If still no audio, prompt user to check mic selection

**API Key Invalid/Missing**:
- Before recording, validate API key exists
- On API error 401, show "Invalid API key" in overlay
- Prompt user to check Settings

**Network Error**:
- Retry once with exponential backoff
- If fails, show "Network error" in overlay for 3 seconds
- Keep audio buffer in case user wants to retry

**API Rate Limit**:
- Show "Rate limit exceeded" in overlay
- Suggest waiting or checking OpenAI dashboard

## Performance Considerations

**Audio Buffer Management**:
- Limit recording to 5 minutes max (prevent memory issues)
- Use compressed format (M4A) for API upload

**API Call Optimization**:
- Stream audio in chunks if possible (check OpenAI API support)
- Show progress indicator for long recordings

**UI Responsiveness**:
- All API calls async/await on background threads
- Update UI only on main thread via @MainActor
- Debounce audio level updates (30fps max)

**Memory**:
- Clear audio buffers after transcription
- Limit CSV file size (rotate/archive after 10,000 entries)

## Security & Privacy

**API Key Storage**:
- Store in Keychain (not UserDefaults) for production
- Never log API keys

**Audio Data**:
- Never persist audio files (only in-memory)
- Delete immediately after transcription
- If local storage enabled, only save text (not audio)

**Permissions**:
- Request permissions with clear explanations
- Gracefully degrade if permissions denied
- Show permission status in Settings

## Testing Strategy

**Unit Tests**:
- AudioRecordingService: Mock AVAudioEngine
- OpenAIClient: Mock URLSession responses
- SettingsManager: Test persistence logic
- TextPastingService: Verify clipboard operations

**Integration Tests**:
- End-to-end flow: Hotkey → Record → Transcribe → Paste
- Permission handling flows
- Error recovery scenarios

**Manual Testing**:
- Test on multiple macOS versions (13.0, 14.0)
- Test with different microphones (built-in, USB, Bluetooth)
- Test from different apps (Chrome, Slack, Notes, Terminal)
- Test with various audio lengths (5s, 30s, 2min)

## Dependencies

**Swift Packages**:
- None required (use native Apple frameworks)
- Optional: KeychainAccess for secure API key storage

**Apple Frameworks**:
- SwiftUI (UI)
- AVFoundation (Audio)
- Carbon/CoreGraphics (Hotkeys, Events)
- AppKit (NSPanel, NSPasteboard)
- Combine (Reactive programming)

## Build & Deployment

**Development**:
- Xcode project with app target
- Code signing with development certificate
- Local testing with personal API key

**Distribution**:
- Notarized .dmg for macOS Gatekeeper
- Alternatively: Mac App Store (requires sandbox compatibility review)
- GitHub releases for versioning
