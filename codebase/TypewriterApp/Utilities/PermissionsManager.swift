//
//  PermissionsManager.swift
//  Typewriter
//
//  System permissions management
//

import Foundation
import AVFoundation
import AppKit

class PermissionsManager: ObservableObject {
    @Published var microphonePermissionGranted = false
    @Published var accessibilityPermissionGranted = false

    static let shared = PermissionsManager()

    private init() {
        checkAllPermissions()
    }

    // MARK: - Check Permissions

    func checkAllPermissions() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
    }

    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionGranted = true
        case .notDetermined, .denied, .restricted:
            microphonePermissionGranted = false
        @unknown default:
            microphonePermissionGranted = false
        }
    }

    func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        accessibilityPermissionGranted = AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Request Permissions

    func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            microphonePermissionGranted = true
            return true

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            microphonePermissionGranted = granted
            return granted

        case .denied, .restricted:
            microphonePermissionGranted = false
            showMicrophonePermissionAlert()
            return false

        @unknown default:
            microphonePermissionGranted = false
            return false
        }
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let granted = AXIsProcessTrustedWithOptions(options)
        accessibilityPermissionGranted = granted

        if !granted {
            showAccessibilityPermissionAlert()
        }
    }

    // MARK: - Permission Alerts

    private func showMicrophonePermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Microphone Permission Required"
            alert.informativeText = "Typewriter needs access to your microphone to record audio for transcription. Please enable microphone access in System Preferences > Privacy & Security > Microphone."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.openSystemPreferences(pane: "Privacy_Microphone")
            }
        }
    }

    private func showAccessibilityPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Typewriter needs Accessibility permission to:\n\n1. Detect global hotkey presses\n2. Paste transcribed text at cursor position\n\nPlease enable Accessibility for Typewriter in System Preferences > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.openSystemPreferences(pane: "Privacy_Accessibility")
            }
        }
    }

    // MARK: - Helpers

    private func openSystemPreferences(pane: String) {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Status

    var allPermissionsGranted: Bool {
        microphonePermissionGranted && accessibilityPermissionGranted
    }

    var permissionsStatus: String {
        var status: [String] = []
        if !microphonePermissionGranted {
            status.append("Microphone")
        }
        if !accessibilityPermissionGranted {
            status.append("Accessibility")
        }

        if status.isEmpty {
            return "All permissions granted ✓"
        } else {
            return "Missing: \(status.joined(separator: ", "))"
        }
    }
}
