# Typewriter Developer Guide

Technical documentation for developers working on or extending Typewriter.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Key Components](#key-components)
4. [Development Setup](#development-setup)
5. [Building & Testing](#building--testing)
6. [Contributing](#contributing)
7. [API Reference](#api-reference)

---

## Architecture Overview

### Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Build System**: Swift Package Manager
- **Minimum macOS**: 13.0 (Ventura)
- **Dependencies**: None (uses Apple frameworks only)

### Design Pattern

**MVVM + Coordinator**
- Models: Data structures (AppSettings, Transcription, etc.)
- Views: SwiftUI views
- Coordinators: AppCoordinator (orchestrates services and state)
- Services: Business logic (AudioRecording, OpenAI, Storage, etc.)

### State Management

**Single AppCoordinator** with state machine:
```swift
enum AppState {
    case idle
    case recording
    case processing
    case pasting
    case error(message: String)
}
```

Transitions: `idle → recording → processing → pasting → idle`

---

## Project Structure

```
codebase/
├── Package.swift              # SPM manifest
├── TypewriterApp/
│   ├── TypewriterApp.swift    # App entry point
│   ├── Info.plist             # Permissions, bundle config
│   ├── Models/                # Data structures
│   │   ├── AppSettings.swift
│   │   ├── AudioData.swift
│   │   ├── AudioDevice.swift
│   │   ├── OpenAIModels.swift
│   │   ├── OverlayState.swift
│   │   └── Transcription.swift
│   ├── Services/              # Business logic
│   │   ├── AudioRecordingService.swift
│   │   ├── GlobalHotkeyMonitor.swift
│   │   ├── OpenAIClient.swift
│   │   ├── SettingsManager.swift
│   │   ├── TextPastingService.swift
│   │   └── TranscriptionStorage.swift
│   ├── Coordinators/
│   │   └── AppCoordinator.swift
│   ├── Views/                 # UI components
│   │   ├── MainWindowView.swift
│   │   ├── SettingsView.swift
│   │   ├── TranscriptionsView.swift
│   │   ├── AboutView.swift
│   │   ├── HotkeyRecorderView.swift
│   │   ├── OverlayController.swift
│   │   ├── OverlayContentView.swift
│   │   └── SoundBarsView.swift
│   └── Utilities/             # Helpers
│       ├── PermissionsManager.swift
│       └── Validator.swift
└── Tests/
    └── TypewriterAppTests/    # Unit tests
```

---

## Key Components

### 1. AppCoordinator

**Purpose**: Orchestrates all services and manages application state

**Key Responsibilities**:
- Handle hotkey press events
- Coordinate recording → transcription → pasting flow
- Manage overlay state transitions
- Error handling and recovery

**Code Location**: `TypewriterApp/Coordinators/AppCoordinator.swift`

**Key Methods**:
```swift
func handleHotkeyPress()
private func startRecording() async
private func stopRecordingAndTranscribe() async
private func pasteText(_ text: String) async
```

### 2. AudioRecordingService

**Purpose**: Capture audio from microphone and convert to M4A

**Key Features**:
- Device enumeration (AVCaptureDevice)
- Real-time recording (AVAudioEngine)
- Buffer collection and management
- M4A conversion (AVAssetWriter with MPEG4 AAC)

**Code Location**: `TypewriterApp/Services/AudioRecordingService.swift`

**Audio Pipeline**:
```
Microphone → AVAudioEngine → PCM Buffers → AVAssetWriter → M4A Data
```

**Key Methods**:
```swift
func listAvailableDevices() -> [AudioDevice]
func startRecording(device: AudioDevice) throws
func stopRecording() -> AudioData
private func convertBufferToM4A() -> Data
```

### 3. OpenAIClient

**Purpose**: HTTP client for OpenAI Whisper API

**Implementation**:
- URLSession with async/await
- Multipart/form-data file upload
- Error handling (401, 429, 5xx)
- Custom instructions via prompt parameter

**Code Location**: `TypewriterApp/Services/OpenAIClient.swift`

**API Endpoint**:
```
POST https://api.openai.com/v1/audio/transcriptions
```

**Request Format**:
```swift
multipart/form-data {
    file: audio.m4a (binary)
    model: "whisper-1"
    prompt: custom_instructions (optional)
}
```

### 4. GlobalHotkeyMonitor

**Purpose**: Detect system-wide keyboard events

**Implementation**:
- CGEvent tap (requires Accessibility permission)
- Event filtering for configured hotkey
- Callback-based notification

**Code Location**: `TypewriterApp/Services/GlobalHotkeyMonitor.swift`

**Key Methods**:
```swift
func register(hotkey: HotkeyConfiguration)
func unregister()
var onHotkeyPressed: (() -> Void)?
```

### 5. OverlayController

**Purpose**: Manage floating overlay window

**Implementation**:
- NSPanel with borderless style
- SwiftUI content (OverlayContentView)
- Always-on-top (NSWindow.Level.floating)
- Auto-centered on screen

**Code Location**: `TypewriterApp/Views/OverlayController.swift`

**States**: hidden, recording, processing, done, error

### 6. TextPastingService

**Purpose**: Inject transcribed text at cursor

**Implementation**:
- Save current clipboard (NSPasteboard)
- Copy transcription to clipboard
- Simulate Cmd+V (CGEvent)
- Restore clipboard after delay

**Code Location**: `TypewriterApp/Services/TextPastingService.swift`

### 7. SettingsManager

**Purpose**: Persist user preferences

**Storage**: UserDefaults (JSON encoded)

**Key**: `com.typewriter.app.settings`

**Code Location**: `TypewriterApp/Services/SettingsManager.swift`

### 8. TranscriptionStorage

**Purpose**: Save transcription history as CSV

**Format**:
```csv
timestamp,duration_seconds,text,instructions
2026-02-28T10:30:00Z,15.3,"Hello world",""
```

**Location**: `~/Documents/Typewriter/transcriptions.csv`

**Code Location**: `TypewriterApp/Services/TranscriptionStorage.swift`

---

## Development Setup

### Prerequisites

1. **Xcode** (optional, for GUI development)
2. **Swift 5.9+** (comes with Xcode or Command Line Tools)
3. **macOS 13.0+**

### Clone & Build

```bash
git clone https://github.com/your-repo/typewriter.git
cd typewriter/codebase

# Build debug
swift build

# Build release
swift build -c release

# Run tests
swift test
```

### Project Scripts

```bash
# Development build
./scripts/dev.sh

# Production build
./scripts/build.sh

# Run tests
./scripts/test.sh

# Lint (placeholder)
./scripts/lint.sh
```

### Running from Xcode

1. Open `Package.swift` in Xcode
2. Select "Typewriter" scheme
3. Run (⌘R)

---

## Building & Testing

### Build Configuration

**Debug Build**:
```bash
swift build
# Output: .build/arm64-apple-macosx/debug/Typewriter
```

**Release Build**:
```bash
swift build -c release
# Output: .build/arm64-apple-macosx/release/Typewriter
```

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter SettingsManagerTests

# Verbose output
swift test --verbose
```

### Test Coverage

```bash
swift test --enable-code-coverage
xcrun llvm-cov report .build/debug/TypewriterPackageTests.xctest/Contents/MacOS/TypewriterPackageTests
```

### Performance Testing

**Audio Conversion Benchmark**:
- 30 seconds of audio should convert in <1 second
- M4A file size should be ~200KB per minute

**API Latency**:
- Typical: 2-5 seconds for 30-second audio
- Depends on network and OpenAI load

---

## Contributing

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint (future: add .swiftlint.yml)
- Document public APIs with `///` comments
- Keep functions under 50 lines
- One class/struct per file

### Git Workflow

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and commit
3. Write tests for new functionality
4. Ensure all tests pass: `swift test`
5. Create pull request

### Commit Messages

Format:
```
<type>: <subject>

<body>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Example:
```
feat: add smart microphone switching

Automatically switch to alternate microphone if no audio
detected after 2 seconds of recording.
```

### Adding New Features

1. **Update Plan**: Document in `plan/` directory
2. **Write Tests**: Add to `Tests/TypewriterAppTests/`
3. **Implement**: Add code to appropriate directory
4. **Update Docs**: Update user-guide.md and developer-guide.md
5. **Build & Test**: Ensure everything works

---

## API Reference

### AppCoordinator

```swift
@MainActor
class AppCoordinator: ObservableObject {
    @Published var appState: AppState
    @Published var currentRecording: AudioData?
    @Published var errorMessage: String?

    let settingsManager: SettingsManager
    let audioService: AudioRecordingService
    let openAIClient: OpenAIClient
    let permissionsManager: PermissionsManager
    var hotkeyMonitor: GlobalHotkeyMonitor?
    var overlayController: OverlayController?

    func handleHotkeyPress()
}
```

### AudioRecordingService

```swift
class AudioRecordingService {
    func listAvailableDevices() -> [AudioDevice]
    func startRecording(device: AudioDevice) throws
    func stopRecording() -> AudioData
    func getCurrentAudioLevel() -> Float
    func switchToDevice(device: AudioDevice)
}
```

### OpenAIClient

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

### SettingsManager

```swift
class SettingsManager: ObservableObject {
    @Published private(set) var currentSettings: AppSettings

    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
    func resetToDefaults()
}
```

### PermissionsManager

```swift
class PermissionsManager: ObservableObject {
    @Published var microphonePermissionGranted: Bool
    @Published var accessibilityPermissionGranted: Bool

    static let shared: PermissionsManager

    func checkAllPermissions()
    func requestMicrophonePermission() async -> Bool
    func requestAccessibilityPermission()
    var allPermissionsGranted: Bool
}
```

### Validator

```swift
struct Validator {
    static func validateAPIKey(_ apiKey: String) -> ValidationResult
    static func validateAudioDuration(_ duration: TimeInterval) -> ValidationResult
    static func validateAudioSize(_ data: Data) -> ValidationResult
}

enum ValidationResult {
    case valid
    case invalid(String)

    var isValid: Bool
    var errorMessage: String?
}
```

---

## Debugging

### Enable Debug Logging

Add to your build:
```swift
#if DEBUG
print("[DEBUG] Your message here")
#endif
```

### Common Issues

**Build fails with "disk I/O error"**:
```bash
rm -rf .build
swift build
```

**Tests fail to run**:
- Ensure you're in `codebase/` directory
- Check test target is included in Package.swift

**Hotkey not detected**:
- Verify Accessibility permission
- Check console for event tap errors

### Profiling

Use Instruments:
1. Build with release configuration
2. Open Instruments (⌘I in Xcode)
3. Select "Time Profiler" or "Allocations"
4. Profile the app

---

## Security Considerations

### API Key Storage

**Current**: UserDefaults (plaintext)
**Production**: Should use Keychain

Migrate:
```swift
import Security

// Store
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "openai-api-key",
    kSecValueData as String: apiKey.data(using: .utf8)!
]
SecItemAdd(query as CFDictionary, nil)

// Retrieve
// ... (implement retrieval)
```

### Permissions

**Never**:
- Skip permission prompts
- Use private APIs
- Access data without permission

**Always**:
- Request permissions with clear explanations
- Respect denied permissions
- Provide fallbacks when permissions missing

---

## Future Enhancements

### Planned Features

1. **Auto-update**: Sparkle framework integration
2. **Multiple languages**: Explicit language selection
3. **Keyboard shortcut customization**: Full shortcut recorder
4. **Real-time audio level**: Live waveform in overlay
5. **Offline mode**: Local Whisper model support
6. **Team features**: Shared API key management

### Architecture Improvements

1. **Dependency Injection**: Replace singletons
2. **Protocol-based services**: Better testability
3. **Swift Concurrency**: Replace callbacks with async/await
4. **Error handling**: Typed errors instead of strings

---

## Resources

### Apple Documentation

- [AVFoundation](https://developer.apple.com/documentation/avfoundation)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Swift Package Manager](https://swift.org/package-manager/)
- [Accessibility](https://developer.apple.com/documentation/accessibility)

### OpenAI

- [Whisper API Docs](https://platform.openai.com/docs/guides/speech-to-text)
- [API Reference](https://platform.openai.com/docs/api-reference/audio)
- [Pricing](https://openai.com/pricing)

### Tools

- [SwiftLint](https://github.com/realm/SwiftLint)
- [create-dmg](https://github.com/create-dmg/create-dmg)
- [Sparkle](https://sparkle-project.org/)

---

## Contact

- **Issues**: [GitHub Issues](https://github.com)
- **Discussions**: [GitHub Discussions](https://github.com)
- **Email**: [support@typewriter.app](mailto:support@typewriter.app)

---

**Last Updated**: 2026-02-28
