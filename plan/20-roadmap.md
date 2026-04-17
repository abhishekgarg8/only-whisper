# Implementation Roadmap - Typewriter App

## Development Phases

### Phase 0: Project Setup (Foundation)
**Duration**: 1 session
**Goal**: Set up Xcode project and basic app structure

**Tasks**:
1. Create Xcode project with macOS app template
2. Configure project settings (deployment target macOS 13.0+)
3. Set up folder structure in codebase/src/
4. Create empty Swift files for core components
5. Add Info.plist entries for permissions
6. Configure app icon and bundle identifier
7. Test: App launches and shows empty window

**Deliverables**:
- Xcode project file
- Basic app that builds and runs
- Folder structure: Models/, Services/, Views/, Utilities/

---

### Phase 1: Core Infrastructure (MVP Foundation)
**Duration**: 2-3 sessions
**Goal**: Implement fundamental services without UI

#### 1.1 Settings Management
**What**: Persistent storage for user preferences

**Implementation Steps**:
1. Create `AppSettings.swift` model (Codable struct)
2. Create `SettingsManager.swift` (UserDefaults wrapper)
3. Implement default settings on first launch
4. Add property observers for reactive updates
5. Test: Settings persist across app restarts

**Files Created**:
- `codebase/src/Models/AppSettings.swift`
- `codebase/src/Services/SettingsManager.swift`

**Test Cases**:
- Save and load settings
- Handle missing settings (first launch)
- Update individual settings
- Reset to defaults

#### 1.2 Audio Recording Service
**What**: Capture audio from selected microphone

**Implementation Steps**:
1. Create `AudioDevice.swift` model
2. Create `AudioRecordingService.swift`
3. Implement device enumeration (AVCaptureDevice)
4. Implement recording start/stop (AVAudioEngine)
5. Record to in-memory buffer (M4A format)
6. Calculate audio levels for visualizer
7. Test: Record 10-second audio, verify buffer contains data

**Files Created**:
- `codebase/src/Models/AudioDevice.swift`
- `codebase/src/Models/AudioData.swift`
- `codebase/src/Services/AudioRecordingService.swift`

**Test Cases**:
- List available audio devices
- Start recording from default device
- Stop recording and retrieve buffer
- Get current audio level (0.0-1.0)
- Handle no devices available
- Handle permission denied

#### 1.3 OpenAI Client
**What**: HTTP client for transcription API

**Implementation Steps**:
1. Create `OpenAIModels.swift` (request/response models)
2. Create `OpenAIClient.swift`
3. Implement multipart/form-data upload
4. Implement async/await API call
5. Parse JSON response
6. Handle errors (401, 429, network)
7. Test: Mock API call with sample audio

**Files Created**:
- `codebase/src/Models/OpenAIModels.swift`
- `codebase/src/Services/OpenAIClient.swift`

**Test Cases**:
- Successful transcription
- Invalid API key (401)
- Rate limit (429)
- Network timeout
- Malformed response
- Large file upload (2MB+)

---

### Phase 2: UI Implementation (User-Facing)
**Duration**: 3-4 sessions
**Goal**: Build main window and settings interface

#### 2.1 Main Window Structure
**What**: SwiftUI app with 3 tabs

**Implementation Steps**:
1. Create `MainWindowView.swift` with TabView
2. Create empty tab views: SettingsView, TranscriptionsView, AboutView
3. Create `AppCoordinator.swift` as ObservableObject
4. Wire up coordinator to main window
5. Set window size constraints (400x600)
6. Test: App shows 3 tabs, can switch between them

**Files Created**:
- `codebase/src/Views/MainWindowView.swift`
- `codebase/src/Views/SettingsView.swift`
- `codebase/src/Views/TranscriptionsView.swift`
- `codebase/src/Views/AboutView.swift`
- `codebase/src/Coordinators/AppCoordinator.swift`

#### 2.2 Settings Tab
**What**: Form for all user preferences

**Implementation Steps**:
1. Add hotkey recorder component (shows current hotkey)
2. Add API key secure text field
3. Add custom instructions text editor
4. Add microphone dropdown (populate from AudioService)
5. Add API model dropdown
6. Add local storage toggle
7. Add "Test API Connection" button
8. Bind all fields to SettingsManager via coordinator
9. Style with minimalist design
10. Test: All settings save and load correctly

**Components**:
- `HotkeyRecorderView.swift` (custom component)
- Form fields in `SettingsView.swift`

#### 2.3 Transcriptions Tab
**What**: List of saved transcriptions

**Implementation Steps**:
1. Create `Transcription.swift` model
2. Create `TranscriptionStorage.swift` service (CSV operations)
3. Load transcriptions from CSV on tab appearance
4. Display in List with timestamp, text preview
5. Add search/filter bar
6. Add detail view on row tap
7. Add delete functionality
8. Test: Display sample transcriptions, search works

**Files Created**:
- `codebase/src/Models/Transcription.swift`
- `codebase/src/Services/TranscriptionStorage.swift`

#### 2.4 About Tab
**What**: App information and credits

**Implementation Steps**:
1. Display app name, version, icon
2. Add description text
3. Add links to GitHub, documentation
4. Add OpenAI attribution
5. Test: Links open in browser

**Files Created**:
- Content in `AboutView.swift`

---

### Phase 3: Global Hotkey System
**Duration**: 2 sessions
**Goal**: System-wide hotkey detection

#### 3.1 Hotkey Monitor
**What**: Detect global keyboard events

**Implementation Steps**:
1. Create `HotkeyConfiguration.swift` model
2. Create `GlobalHotkeyMonitor.swift`
3. Implement CGEvent tap registration
4. Convert CGEvent to key codes
5. Match against configured hotkey
6. Trigger callback on match
7. Request accessibility permission
8. Test: Hotkey detected from other apps

**Files Created**:
- `codebase/src/Models/HotkeyConfiguration.swift`
- `codebase/src/Services/GlobalHotkeyMonitor.swift`
- `codebase/src/Utilities/PermissionsManager.swift`

**Test Cases**:
- Register hotkey (Cmd+Shift+Space)
- Detect hotkey press from Chrome
- Detect hotkey press from Terminal
- Change hotkey configuration
- Handle permission denied

#### 3.2 Permission Handling
**What**: Request and check system permissions

**Implementation Steps**:
1. Create `PermissionsManager.swift`
2. Implement microphone permission check/request
3. Implement accessibility permission check/request
4. Show permission alert dialogs
5. Add permission status to Settings tab
6. Test: Permissions requested on first launch

**Permissions Required**:
- Microphone (NSMicrophoneUsageDescription)
- Accessibility (for global hotkey + paste)

---

### Phase 4: Overlay Panel
**Duration**: 2 sessions
**Goal**: Floating visual feedback UI

#### 4.1 Overlay Window
**What**: Pill-shaped always-on-top panel

**Implementation Steps**:
1. Create `OverlayPanel.swift` (NSPanel subclass)
2. Configure window properties (borderless, floating)
3. Create `OverlayContentView.swift` (SwiftUI)
4. Position at screen center
5. Implement show/hide animations
6. Test: Panel appears and disappears

**Files Created**:
- `codebase/src/Views/OverlayPanel.swift`
- `codebase/src/Views/OverlayContentView.swift`

#### 4.2 Overlay States
**What**: Visual feedback for recording, processing, done, error

**Implementation Steps**:
1. Create `OverlayState` enum
2. Implement recording state (pulsating sound bars)
3. Implement processing state (spinning indicator)
4. Implement done state (checkmark + auto-dismiss)
5. Implement error state (X icon + message)
6. Bind to AppCoordinator state
7. Test: All states display correctly

**Components**:
- `SoundBarsView.swift` (animated visualizer)
- `ProcessingIndicatorView.swift` (spinner)

**Visual Design**:
- Size: 200x50 points
- Backdrop: frosted glass (ultraThinMaterial)
- Corner radius: 25pt
- Animations: spring (duration: 0.3s)

---

### Phase 5: Integration & Core Flow
**Duration**: 3 sessions
**Goal**: Wire all components together

#### 5.1 App Coordinator Logic
**What**: Orchestrate entire user flow

**Implementation Steps**:
1. Implement state machine in AppCoordinator
2. Add handleHotkeyPress() method
3. Wire hotkey → start recording
4. Wire second hotkey → stop recording → API call
5. Wire API response → paste text
6. Handle all error cases
7. Update overlay state at each step
8. Test: Full flow from hotkey to paste

**State Machine**:
```
.idle → (hotkey) → .recording → (hotkey) → .processing → .pasting → .idle
                                                ↓ (error)
                                              .error → .idle
```

#### 5.2 Text Pasting Service
**What**: Inject text at cursor position

**Implementation Steps**:
1. Create `TextPastingService.swift`
2. Implement clipboard save/restore
3. Implement Cmd+V simulation via CGEvent
4. Add delay for clipboard restoration
5. Test: Text pastes into Notes, Chrome, Slack

**Files Created**:
- `codebase/src/Services/TextPastingService.swift`

**Test Cases**:
- Paste into text editor
- Paste into web browser
- Paste into terminal
- Verify clipboard restored

#### 5.3 Smart Microphone Switching
**What**: Auto-switch mic if no audio detected

**Implementation Steps**:
1. Add silence detection to AudioRecordingService
2. After 2 seconds of silence, trigger switch
3. Try next available microphone
4. Show notification in overlay
5. Test: Unplug mic during recording, verify switch

---

### Phase 6: Polish & Error Handling
**Duration**: 2 sessions
**Goal**: Production-ready robustness

#### 6.1 Error Handling
**What**: Graceful degradation for all failures

**Implementation Steps**:
1. Add error display in overlay (3-second timeout)
2. Handle API key validation before recording
3. Handle network timeouts (30-second max)
4. Handle API rate limits (show retry time)
5. Handle microphone disconnection during recording
6. Add retry logic for transient failures
7. Test: All error scenarios display user-friendly messages

**Error Messages**:
- "Invalid API key" → Prompt to check Settings
- "Network error" → Suggest retry
- "Rate limit exceeded" → Show wait time
- "No microphone detected" → Check connections
- "Permission denied" → Link to System Preferences

#### 6.2 User Experience Improvements
**What**: Small touches for delightful UX

**Implementation Steps**:
1. Add haptic feedback on hotkey press (if supported)
2. Add sound effect on transcription complete (optional)
3. Add keyboard shortcuts for common actions
4. Add tooltips to settings fields
5. Add loading states to "Test API" button
6. Improve visual design (colors, spacing, fonts)
7. Test: App feels polished and responsive

#### 6.3 Performance Optimization
**What**: Smooth operation under all conditions

**Implementation Steps**:
1. Debounce audio level updates (30fps)
2. Limit recording duration (5 minutes max)
3. Compress audio before API upload
4. Cancel in-flight API requests on error
5. Test: App responsive during long recordings

---

### Phase 7: Testing & Documentation
**Duration**: 2 sessions
**Goal**: Comprehensive test coverage

#### 7.1 Automated Tests
**What**: Unit and integration tests

**Implementation Steps**:
1. Write unit tests for SettingsManager
2. Write unit tests for OpenAIClient (mocked)
3. Write unit tests for AudioRecordingService (mocked)
4. Write integration test for full flow (mocked API)
5. Achieve >80% code coverage
6. Test: All tests pass

**Files Created**:
- `tests/unit/SettingsManagerTests.swift`
- `tests/unit/OpenAIClientTests.swift`
- `tests/unit/AudioRecordingServiceTests.swift`
- `tests/integration/EndToEndFlowTests.swift`

#### 7.2 Manual Testing
**What**: Real-world usage scenarios

**Test Scenarios**:
1. Install on fresh macOS (no settings)
2. Test with built-in microphone
3. Test with USB microphone
4. Test with Bluetooth headset
5. Test from 10+ different apps
6. Test with 5-second audio clips
7. Test with 2-minute audio clips
8. Test with poor network (throttled)
9. Test with invalid API key
10. Test with expired API key
11. Test hotkey conflicts with other apps
12. Test on macOS 13.0, 14.0, 15.0

#### 7.3 Documentation
**What**: User guide and developer docs

**Implementation Steps**:
1. Write README.md with setup instructions
2. Write user guide in docs/user-guide.md
3. Write developer guide in docs/developer-guide.md
4. Add inline code documentation (comments)
5. Create troubleshooting guide
6. Test: New user can set up and use app

**Files Created**:
- `README.md` (updated with usage)
- `docs/user-guide.md`
- `docs/developer-guide.md`
- `docs/troubleshooting.md`

---

### Phase 8: Distribution
**Duration**: 1 session
**Goal**: Prepare for release

#### 8.1 Build & Notarization
**What**: Create distributable .dmg

**Implementation Steps**:
1. Configure code signing with Apple Developer certificate
2. Build release configuration
3. Create .dmg with create-dmg or similar tool
4. Notarize with Apple (xcrun notarytool)
5. Test: .dmg installs on fresh Mac

#### 8.2 Release Preparation
**What**: GitHub release and documentation

**Implementation Steps**:
1. Tag version (e.g., v1.0.0)
2. Write release notes
3. Upload .dmg to GitHub releases
4. Update README with download link
5. Test: User can download and install

---

## Parallel Workstreams

**Independent Tracks** (can be developed simultaneously):

**Track A: Core Services**
- Phase 1.1: Settings Management
- Phase 1.2: Audio Recording Service
- Phase 1.3: OpenAI Client

**Track B: UI Components**
- Phase 2.1: Main Window Structure
- Phase 2.2: Settings Tab
- Phase 2.3: Transcriptions Tab
- Phase 2.4: About Tab

**Track C: System Integration**
- Phase 3.1: Hotkey Monitor
- Phase 3.2: Permission Handling
- Phase 4.1: Overlay Window
- Phase 4.2: Overlay States

**Track D: Integration** (depends on A, B, C)
- Phase 5: Integration & Core Flow

**Track E: Quality** (depends on D)
- Phase 6: Polish & Error Handling
- Phase 7: Testing & Documentation
- Phase 8: Distribution

---

## Dependencies Graph

```
Phase 0 (Setup)
    ├─→ Phase 1.1 (Settings) ─┐
    ├─→ Phase 1.2 (Audio)     ├─→ Phase 5.1 (Coordinator)
    ├─→ Phase 1.3 (OpenAI)    ├─→ Phase 5.2 (Pasting)
    ├─→ Phase 2.x (UI)        ├─→ Phase 5.3 (Smart Mic)
    ├─→ Phase 3.x (Hotkey)    │           ↓
    └─→ Phase 4.x (Overlay) ─┘    Phase 6 (Polish)
                                          ↓
                                   Phase 7 (Testing)
                                          ↓
                                   Phase 8 (Distribution)
```

---

## Milestones

**M1: Infrastructure Complete** (End of Phase 1)
- All core services implemented and tested
- Can record audio, call API, save settings

**M2: UI Complete** (End of Phase 2)
- Main window fully functional
- All settings configurable
- Transcriptions viewable

**M3: System Integration Complete** (End of Phase 4)
- Global hotkey works
- Overlay displays correctly
- Permissions handled

**M4: MVP Complete** (End of Phase 5)
- Full flow works: hotkey → record → transcribe → paste
- App usable for basic transcription

**M5: Production Ready** (End of Phase 7)
- All tests passing
- Error handling robust
- Documentation complete

**M6: Released** (End of Phase 8)
- Notarized .dmg available
- GitHub release published

---

## Risk Mitigation

**Risk 1: Global Hotkey Unreliable**
- Mitigation: Test on multiple macOS versions early (Phase 3)
- Fallback: Menu bar activation if hotkey fails

**Risk 2: OpenAI API Changes**
- Mitigation: Abstract API client behind interface
- Fallback: Support multiple API versions

**Risk 3: Accessibility Permission Issues**
- Mitigation: Clear permission prompts and documentation
- Fallback: Manual copy-paste mode

**Risk 4: Audio Quality Problems**
- Mitigation: Test with multiple microphones early (Phase 1.2)
- Fallback: Allow audio format selection

**Risk 5: Performance with Long Recordings**
- Mitigation: Implement 5-minute limit and compression
- Fallback: Show progress indicator for large files

---

## Success Metrics

**Technical**:
- All unit tests passing (>80% coverage)
- No crashes in 100 test transcriptions
- API calls complete in <5 seconds for 30-second audio
- Memory usage <100MB during recording

**User Experience**:
- Hotkey → paste completes in <5 seconds
- Overlay feedback feels immediate (<100ms)
- Settings persist across restarts
- Works in 10+ common applications

**Quality**:
- Zero security vulnerabilities
- No API key leaks in logs
- Graceful error messages for all failures
- Professional visual design
