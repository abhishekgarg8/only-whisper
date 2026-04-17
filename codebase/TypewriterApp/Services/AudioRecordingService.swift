//
//  AudioRecordingService.swift
//  Typewriter
//
//  Audio input device management, recording, and disconnection detection
//

import Foundation
import AVFoundation

class AudioRecordingService: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingStartTime: Date?

    /// Called on the main thread when the underlying recorder encounters an error
    /// (e.g. microphone disconnected mid-recording).
    var onRecordingFailed: (() -> Void)?

    override init() {}

    // MARK: - Device Management

    /// Returns all available audio input devices. Falls back to a synthetic default
    /// if the system reports none.
    func listAvailableDevices() -> [AudioDevice] {
        var devices: [AudioDevice] = []

        if let defaultDevice = AVCaptureDevice.default(for: .audio) {
            devices.append(AudioDevice(
                id: defaultDevice.uniqueID,
                name: defaultDevice.localizedName,
                isDefault: true
            ))
        }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        )

        for device in discoverySession.devices {
            if !devices.contains(where: { $0.id == device.uniqueID }) {
                devices.append(AudioDevice(
                    id: device.uniqueID,
                    name: device.localizedName,
                    isDefault: false
                ))
            }
        }

        return devices.isEmpty ? [AudioDevice.defaultDevice] : devices
    }

    // MARK: - Recording

    func startRecording(device: AudioDevice) throws {
        print("🎤 Starting recording on device: \(device.name)")

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "typewriter_recording_\(UUID().uuidString).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)

        guard let url = recordingURL else {
            throw RecordingError.engineInitFailed
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

            recordingStartTime = Date()
            let started = audioRecorder?.record() ?? false

            if started {
                print("✅ Recording started: \(url.lastPathComponent)")
            } else {
                throw RecordingError.engineInitFailed
            }
        } catch {
            print("❌ Failed to create audio recorder: \(error)")
            throw RecordingError.engineInitFailed
        }
    }

    func stopRecording() -> AudioData {
        print("🛑 Stopping recording...")

        guard let recorder = audioRecorder, recorder.isRecording else {
            print("⚠️ No active recording")
            return AudioData(data: Data(), duration: 0, format: .m4a)
        }

        let duration = recorder.currentTime
        recorder.stop()
        print("✅ Recording stopped — duration: \(String(format: "%.1f", duration))s")

        guard let url = recordingURL else {
            return AudioData(data: Data(), duration: duration, format: .m4a)
        }

        do {
            let data = try Data(contentsOf: url)
            print("✅ Audio data loaded: \(data.count) bytes")
            try? FileManager.default.removeItem(at: url)
            resetState()
            return AudioData(data: data, duration: duration, format: .m4a)
        } catch {
            print("❌ Error reading audio file: \(error)")
            resetState()
            return AudioData(data: Data(), duration: duration, format: .m4a)
        }
    }

    func getCurrentAudioLevel() -> Float {
        guard let recorder = audioRecorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        let db = recorder.averagePower(forChannel: 0)
        // Convert dB to linear 0–1; clamp to valid range
        return min(max(pow(10, db / 20), 0), 1)
    }

    func isRecording() -> Bool {
        return audioRecorder?.isRecording ?? false
    }

    // MARK: - Private

    private func resetState() {
        audioRecorder = nil
        recordingURL = nil
        recordingStartTime = nil
    }

    // MARK: - Errors

    enum RecordingError: Error, LocalizedError {
        case engineInitFailed
        case permissionDenied
        case noDeviceAvailable

        var errorDescription: String? {
            switch self {
            case .engineInitFailed:   return "Failed to initialize audio recorder"
            case .permissionDenied:   return "Microphone permission denied"
            case .noDeviceAvailable:  return "No audio input device available"
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // A non-successful finish means the recorder was interrupted (e.g. mic disconnected)
        if !flag {
            print("❌ [AudioService] Recording finished unsuccessfully — possible disconnection")
            DispatchQueue.main.async { [weak self] in
                self?.onRecordingFailed?()
            }
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ [AudioService] Encode error: \(String(describing: error))")
        DispatchQueue.main.async { [weak self] in
            self?.onRecordingFailed?()
        }
    }
}
