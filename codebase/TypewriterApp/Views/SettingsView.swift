//
//  SettingsView.swift
//  Typewriter
//
//  Settings configuration tab
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var settings: AppSettings
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    @State private var isTestingAPI = false
    @State private var apiTestResult: APITestResult?
    @State private var availableMicrophones: [AudioDevice] = []

    init() {
        _settings = State(initialValue: SettingsManager().loadSettings())
    }

    enum APITestResult {
        case success
        case failure(String)
    }

    var body: some View {
        Form {
            // MARK: Permissions
            Section("Permissions") {
                HStack {
                    Image(systemName: permissionsManager.microphonePermissionGranted
                          ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(permissionsManager.microphonePermissionGranted ? .green : .red)
                    Text("Microphone")
                    Spacer()
                    if !permissionsManager.microphonePermissionGranted {
                        Button("Grant") {
                            Task { await permissionsManager.requestMicrophonePermission() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .help("Required to capture audio for transcription")

                HStack {
                    Image(systemName: permissionsManager.accessibilityPermissionGranted
                          ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(permissionsManager.accessibilityPermissionGranted ? .green : .red)
                    Text("Accessibility")
                    Spacer()
                    if !permissionsManager.accessibilityPermissionGranted {
                        Button("Grant") {
                            permissionsManager.requestAccessibilityPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .help("Required to detect the global hotkey and paste transcribed text at your cursor")

                Text("Both permissions are required for full functionality")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: API Configuration
            Section("API Configuration") {
                SecureField("OpenAI API Key", text: $settings.openAIApiKey)
                    .textFieldStyle(.roundedBorder)
                    .help("Your OpenAI API key, starting with \"sk-\". Get one at platform.openai.com/api-keys")

                Picker("API Model", selection: $settings.selectedAPIModel) {
                    ForEach(OpenAIModel.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .help("The Whisper model used for transcription. Higher-quality models cost slightly more per minute")

                Text(settings.selectedAPIModel.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button(action: { Task { await testAPIConnection() } }) {
                        HStack {
                            if isTestingAPI {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.trailing, 4)
                            }
                            Text(isTestingAPI ? "Testing..." : "Test API Connection")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTestingAPI || settings.openAIApiKey.isEmpty)
                    .help("Verifies your API key is valid by making a lightweight request to OpenAI")

                    if let result = apiTestResult {
                        switch result {
                        case .success:
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        case .failure:
                            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                        }
                    }
                }

                if case .failure(let message) = apiTestResult {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // MARK: Transcription Settings
            Section("Transcription Settings") {
                TextEditor(text: $settings.customInstructions)
                    .frame(height: 80)
                    .font(.body)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .help("Optional instructions sent with every transcription to guide formatting or style, e.g. \"Format as bullet points\" or \"Use British English\"")

                Text("Custom formatting instructions sent with each transcription")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: Audio Input
            Section("Audio Input") {
                Picker("Microphone", selection: $settings.selectedMicrophone) {
                    ForEach(availableMicrophones) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                .help("The microphone used for recording. Change this if the wrong device is being picked up")

                if availableMicrophones.isEmpty {
                    Text("No microphones detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // MARK: Storage
            Section("Storage") {
                Toggle("Save transcriptions locally", isOn: $settings.saveTranscriptionsLocally)
                    .help("Saves every transcription to a CSV file at the path shown below for later review or export")

                if settings.saveTranscriptionsLocally {
                    Text("Location: \(settings.transcriptionStoragePath.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // MARK: Hotkeys
            Section("Hotkeys") {
                HotkeySettingsView(
                    pushToTalkHotkeys: $settings.pushToTalkHotkeys,
                    handsFreeHotkeys: $settings.handsFreeHotkeys
                )
            }
        }
        .formStyle(.grouped)
        .onChange(of: settings) { newValue in
            coordinator.settingsManager.saveSettings(newValue)
            coordinator.reloadHotkeys()
        }
        .onAppear {
            loadMicrophones()
        }
    }

    // MARK: - Helpers

    private func loadMicrophones() {
        availableMicrophones = coordinator.audioService.listAvailableDevices()
        if availableMicrophones.isEmpty {
            availableMicrophones = [AudioDevice.defaultDevice]
        }
    }

    private func testAPIConnection() async {
        guard !settings.openAIApiKey.isEmpty else {
            apiTestResult = .failure("API key is required")
            return
        }

        isTestingAPI = true
        apiTestResult = nil

        do {
            try await coordinator.openAIClient.validateAPIKey(settings.openAIApiKey)
            apiTestResult = .success
        } catch let error as OpenAIError {
            apiTestResult = .failure(error.localizedDescription)
        } catch {
            apiTestResult = .failure("Connection failed: \(error.localizedDescription)")
        }

        isTestingAPI = false

        // Auto-clear result after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            apiTestResult = nil
        }
    }
}
