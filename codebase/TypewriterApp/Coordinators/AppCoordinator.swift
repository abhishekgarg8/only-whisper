//
//  AppCoordinator.swift
//  Typewriter
//
//  Central state manager and pipeline orchestrator.
//
//  State machine: idle → recording → processing → pasting → idle
//                                 ↘ error → idle (auto-recover after 3s)
//

import Foundation
import Combine
import AppKit

// MARK: - AppState

enum AppState {
    case idle
    case recording
    case processing
    case pasting
    case error(message: String)
}

extension AppState: Equatable {
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.recording, .recording),
             (.processing, .processing), (.pasting, .pasting): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - AppCoordinator

@MainActor
public class AppCoordinator: ObservableObject {
    @Published var appState: AppState = .idle
    @Published var currentRecording: AudioData?
    @Published var errorMessage: String?

    let settingsManager: SettingsManager
    let audioService: AudioRecordingService
    let openAIClient: OpenAIClient
    let permissionsManager = PermissionsManager.shared
    var hotkeyMonitor: GlobalHotkeyMonitor?
    var overlayController: OverlayController?

    // MARK: - Private state

    private var currentRecordingMode: RecordingMode?

    /// Task running the full recording→transcription→paste pipeline.
    /// Cancel this to abort mid-flow.
    private var pipelineTask: Task<Void, Never>?

    /// Polls microphone levels during recording.
    private var audioLevelTask: Task<Void, Never>?

    /// Enforces the 5-minute maximum recording limit.
    private var maxDurationTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()

    static let maxRecordingDuration: TimeInterval = 300  // 5 minutes
    static let maxDurationWarning: TimeInterval = 30     // warn 30s before limit

    // MARK: - Init

    public init() {
        self.settingsManager = SettingsManager()
        self.audioService = AudioRecordingService()
        self.openAIClient = OpenAIClient()

        setupHotkeyMonitor()
        setupOverlay()
        observeAppActivation()
    }

    // MARK: - Setup

    private func observeAppActivation() {
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recheckPermissionsAndHotkeys()
                }
            }
            .store(in: &cancellables)
    }

    private func recheckPermissionsAndHotkeys() {
        permissionsManager.checkAllPermissions()
        if permissionsManager.accessibilityPermissionGranted && hotkeyMonitor == nil {
            setupHotkeyMonitor()
        }
    }

    private func setupHotkeyMonitor() {
        guard permissionsManager.accessibilityPermissionGranted else {
            print("⚠️ Accessibility permission not granted — hotkey disabled")
            return
        }

        hotkeyMonitor = GlobalHotkeyMonitor()
        let settings = settingsManager.loadSettings()

        hotkeyMonitor?.register(
            pushToTalk: settings.pushToTalkHotkeys,
            handsFree: settings.handsFreeHotkeys
        )

        hotkeyMonitor?.onPushToTalkPressed  = { [weak self] in self?.handlePushToTalkStart() }
        hotkeyMonitor?.onPushToTalkReleased = { [weak self] in self?.handlePushToTalkEnd() }
        hotkeyMonitor?.onHandsFreePressed   = { [weak self] in self?.handleHandsFreeToggle() }
        hotkeyMonitor?.onHotkeyPressed      = { [weak self] in self?.handleHotkeyPress() }
    }

    private func setupOverlay() {
        overlayController = OverlayController()
    }

    // MARK: - Public control

    /// Re-registers hotkeys after settings change. Also initialises the monitor if
    /// accessibility permission was just granted.
    func reloadHotkeys() {
        if hotkeyMonitor == nil {
            if permissionsManager.accessibilityPermissionGranted {
                setupHotkeyMonitor()
            }
            return
        }
        let settings = settingsManager.loadSettings()
        hotkeyMonitor?.register(
            pushToTalk: settings.pushToTalkHotkeys,
            handsFree: settings.handsFreeHotkeys
        )
    }

    /// Cancels any active recording immediately, discarding captured audio.
    func cancelRecording() {
        guard case .recording = appState else { return }
        print("🚫 [Coordinator] Recording cancelled by user")
        stopAudioLevelPolling()
        maxDurationTask?.cancel()
        maxDurationTask = nil
        pipelineTask?.cancel()
        pipelineTask = nil
        _ = audioService.stopRecording()
        overlayController?.hide()
        appState = .idle
        currentRecordingMode = nil
    }

    // MARK: - Hotkey handlers

    func handlePushToTalkStart() {
        print("🎙️ [Coordinator] Push-to-talk START, state=\(appState)")
        guard case .idle = appState else { return }
        currentRecordingMode = .pushToTalk
        pipelineTask = Task { await startRecording() }
    }

    func handlePushToTalkEnd() {
        print("🎙️ [Coordinator] Push-to-talk END, state=\(appState)")
        guard case .recording = appState, currentRecordingMode == .pushToTalk else { return }
        pipelineTask = Task { await stopRecordingAndTranscribe() }
    }

    func handleHandsFreeToggle() {
        print("🎙️ [Coordinator] Hands-free TOGGLE, state=\(appState)")
        pipelineTask = Task {
            switch appState {
            case .idle:
                currentRecordingMode = .handsFree
                await startRecording()
            case .recording where currentRecordingMode == .handsFree:
                await stopRecordingAndTranscribe()
            default:
                print("⚠️ [Coordinator] Invalid state for toggle")
            }
        }
    }

    func handleHotkeyPress() {
        print("🎙️ [Coordinator] Hotkey pressed (legacy), state=\(appState)")
        pipelineTask = Task {
            switch appState {
            case .idle:
                currentRecordingMode = .handsFree
                await startRecording()
            case .recording:
                await stopRecordingAndTranscribe()
            default:
                print("⚠️ [Coordinator] Invalid state")
            }
        }
    }

    // MARK: - Recording pipeline

    private func startRecording() async {
        print("🎙️ [Coordinator] startRecording()")

        // ── 1. Validate API key before doing anything ──────────────────────────
        let settings = settingsManager.loadSettings()
        guard !settings.openAIApiKey.isEmpty else {
            print("❌ [Coordinator] API key not set")
            await showError("API key not set. Check Settings.")
            currentRecordingMode = nil
            return
        }

        // ── 2. Microphone permission ───────────────────────────────────────────
        let granted = await permissionsManager.requestMicrophonePermission()
        guard granted else {
            print("❌ [Coordinator] Microphone permission denied")
            appState = .error(message: "Microphone permission denied")
            await showError("Microphone permission denied")
            appState = .idle
            return
        }

        // ── 3. Start audio capture ─────────────────────────────────────────────
        do {
            appState = .recording
            overlayController?.show(state: .recording)

            let devices = audioService.listAvailableDevices()
            let selectedDevice = devices.first { $0.id == settings.selectedMicrophone }
                ?? AudioDevice.defaultDevice

            // Wire disconnection handler before starting
            audioService.onRecordingFailed = { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.handleMicrophoneDisconnection()
                }
            }

            try audioService.startRecording(device: selectedDevice)
            print("✅ [Coordinator] Recording on: \(selectedDevice.name)")

            startAudioLevelPolling()
            scheduleMaxDurationEnforcement()

        } catch {
            print("❌ [Coordinator] Failed to start recording: \(error)")
            stopAudioLevelPolling()
            appState = .error(message: error.localizedDescription)
            await showError(error.localizedDescription)
            appState = .idle
            currentRecordingMode = nil
        }
    }

    private func stopRecordingAndTranscribe() async {
        print("🛑 [Coordinator] stopRecordingAndTranscribe()")
        stopAudioLevelPolling()
        maxDurationTask?.cancel()
        maxDurationTask = nil

        do {
            appState = .processing
            overlayController?.show(state: .processing)

            let audioData = audioService.stopRecording()
            currentRecording = audioData

            print("📊 [Coordinator] Audio: \(audioData.data.count) bytes, \(String(format: "%.1f", audioData.duration))s")

            // ── Validate using Validator utility ──────────────────────────────
            let sizeResult = Validator.validateAudioSize(audioData.data)
            if !sizeResult.isValid {
                throw NSError(domain: "TypewriterApp", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: sizeResult.errorMessage ?? "Audio error"])
            }

            let durationResult = Validator.validateAudioDuration(audioData.duration)
            if !durationResult.isValid {
                throw NSError(domain: "TypewriterApp", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: durationResult.errorMessage ?? "Audio too short"])
            }

            // ── Check cooperative cancellation before network call ─────────────
            guard !Task.isCancelled else {
                overlayController?.hide()
                appState = .idle
                currentRecordingMode = nil
                return
            }

            let settings = settingsManager.loadSettings()

            print("🌐 [Coordinator] Calling OpenAI Whisper API…")
            let transcription = try await openAIClient.transcribe(
                audio: audioData.data,
                apiKey: settings.openAIApiKey,
                customInstructions: settings.customInstructions.isEmpty ? nil : settings.customInstructions,
                model: settings.selectedAPIModel
            )
            print("✅ [Coordinator] Transcription: \"\(transcription.text.prefix(50))\"")

            // Save before pasting so a paste crash doesn't lose the result
            if settings.saveTranscriptionsLocally {
                saveTranscription(text: transcription.text,
                                  duration: audioData.duration,
                                  instructions: settings.customInstructions)
            }

            await pasteText(transcription.text)

            overlayController?.show(state: .done)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            overlayController?.hide()

            print("✅ [Coordinator] Flow complete")
            appState = .idle
            currentRecordingMode = nil

        } catch {
            print("❌ [Coordinator] Error: \(error)")
            appState = .error(message: error.localizedDescription)
            overlayController?.show(state: .error(message: error.localizedDescription))
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            overlayController?.hide()
            appState = .idle
            currentRecordingMode = nil
        }
    }

    private func pasteText(_ text: String) async {
        appState = .pasting
        TextPastingService.shared.pasteText(text)
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms for paste to land
    }

    private func saveTranscription(text: String, duration: TimeInterval, instructions: String) {
        let transcription = Transcription(duration: duration, text: text, customInstructions: instructions)
        TranscriptionStorage.shared.save(transcription)
    }

    // MARK: - Error presentation

    private func showError(_ message: String) async {
        overlayController?.show(state: .error(message: message))
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        overlayController?.hide()
    }

    // MARK: - Microphone disconnection

    private func handleMicrophoneDisconnection() async {
        guard case .recording = appState else { return }
        print("❌ [Coordinator] Microphone disconnected during recording")
        stopAudioLevelPolling()
        maxDurationTask?.cancel()
        maxDurationTask = nil
        _ = audioService.stopRecording()
        appState = .error(message: "Microphone disconnected")
        await showError("Microphone disconnected")
        appState = .idle
        currentRecordingMode = nil
    }

    // MARK: - Audio level polling

    private func startAudioLevelPolling() {
        audioLevelTask?.cancel()
        audioLevelTask = Task {
            while !Task.isCancelled {
                let level = audioService.getCurrentAudioLevel()
                overlayController?.audioLevel = level
                try? await Task.sleep(nanoseconds: 33_000_000) // ~30fps
            }
        }
    }

    private func stopAudioLevelPolling() {
        audioLevelTask?.cancel()
        audioLevelTask = nil
        overlayController?.audioLevel = 0
    }

    // MARK: - Max recording duration enforcement

    private func scheduleMaxDurationEnforcement() {
        maxDurationTask?.cancel()
        maxDurationTask = Task {
            let warningDelay = UInt64((Self.maxRecordingDuration - Self.maxDurationWarning) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: warningDelay)
            guard !Task.isCancelled, case .recording = appState else { return }

            // Show 30-second warning
            print("⚠️ [Coordinator] 30 seconds remaining in max recording window")
            overlayController?.show(state: .error(message: "30s left — max 5 min"))
            try? await Task.sleep(nanoseconds: UInt64(Self.maxDurationWarning * 1_000_000_000))
            guard !Task.isCancelled, case .recording = appState else { return }

            // Force stop
            print("⏱️ [Coordinator] Max recording duration reached — stopping")
            await stopRecordingAndTranscribe()
        }
    }
}
