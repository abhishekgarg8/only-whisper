//
//  HotkeyRecorderView.swift
//  Typewriter
//
//  Hotkey recorder UI component with Push to Talk and Hands-free modes
//

import SwiftUI
import Carbon

// MARK: - Main Hotkey Settings View

struct HotkeySettingsView: View {
    @Binding var pushToTalkHotkeys: [HotkeyConfiguration]
    @Binding var handsFreeHotkeys: [HotkeyConfiguration]

    var body: some View {
        VStack(spacing: 16) {
            // Push to Talk Section
            HotkeyModeCard(
                title: "Push to talk",
                subtitle: "Hold to say something short",
                hotkeys: $pushToTalkHotkeys
            )

            // Hands-free Mode Section
            HotkeyModeCard(
                title: "Hands-free mode",
                subtitle: "Press to start and stop dictation",
                hotkeys: $handsFreeHotkeys
            )
        }
    }
}

// MARK: - Hotkey Mode Card

struct HotkeyModeCard: View {
    let title: String
    let subtitle: String
    @Binding var hotkeys: [HotkeyConfiguration]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Hotkey buttons
            VStack(spacing: 8) {
                ForEach(Array(hotkeys.enumerated()), id: \.element.id) { index, hotkey in
                    HotkeyRowView(
                        hotkey: Binding(
                            get: { hotkeys[index] },
                            set: { hotkeys[index] = $0 }
                        ),
                        onDelete: hotkeys.count > 1 ? {
                            hotkeys.remove(at: index)
                        } : nil
                    )
                }

                // Add another button
                Button(action: {
                    hotkeys.append(HotkeyConfiguration(keyCode: 0, modifiers: 0))
                }) {
                    Text("Add another")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Hotkey Row View

struct HotkeyRowView: View {
    @Binding var hotkey: HotkeyConfiguration
    var onDelete: (() -> Void)?
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 8) {
            // Hotkey display button
            Button(action: { isRecording.toggle() }) {
                HStack(spacing: 8) {
                    if isRecording {
                        Text("Press key...")
                            .foregroundColor(.blue)
                    } else if hotkey.keyCode == 0 && hotkey.modifiers == 0 {
                        Text("Click to set")
                            .foregroundColor(.secondary)
                    } else {
                        Text(hotkey.displayString)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(minWidth: 120)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRecording ? Color.blue.opacity(0.1) : Color(nsColor: .controlColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isRecording ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .background(
                HotkeyCapture(isRecording: $isRecording, hotkey: $hotkey)
            )

            // Delete button (only shown if there's more than one hotkey)
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Legacy Single Hotkey View (for backward compatibility)

struct HotkeyRecorderView: View {
    @Binding var hotkey: HotkeyConfiguration
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text("Global Hotkey")

            Spacer()

            Button(action: { isRecording.toggle() }) {
                HStack {
                    if isRecording {
                        Text("Press keys...")
                            .foregroundColor(.blue)
                    } else {
                        Text(hotkey.displayString)
                    }
                }
                .padding(8)
                .frame(minWidth: 120)
                .background(isRecording ? Color.blue.opacity(0.1) : Color.gray.opacity(0.2))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .overlay(
                HotkeyCapture(isRecording: $isRecording, hotkey: $hotkey)
            )
        }
    }
}

// MARK: - NSView wrapper to capture keyboard events

struct HotkeyCapture: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var hotkey: HotkeyConfiguration

    func makeNSView(context: Context) -> HotkeyCaptureView {
        let view = HotkeyCaptureView()
        view.onKeyCaptured = { keyCode, modifiers in
            hotkey = HotkeyConfiguration(
                id: hotkey.id,
                keyCode: keyCode,
                modifiers: modifiers
            )
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: HotkeyCaptureView, context: Context) {
        nsView.isCapturing = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

class HotkeyCaptureView: NSView {
    var isCapturing = false
    var onKeyCaptured: ((UInt16, UInt32) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isCapturing else {
            super.keyDown(with: event)
            return
        }

        let keyCode = event.keyCode
        var modifiers: UInt32 = 0

        if event.modifierFlags.contains(.command) {
            modifiers |= 256 // Command
        }
        if event.modifierFlags.contains(.shift) {
            modifiers |= 512 // Shift
        }
        if event.modifierFlags.contains(.option) {
            modifiers |= 2048 // Option
        }
        if event.modifierFlags.contains(.control) {
            modifiers |= 4096 // Control
        }

        // Capture modifier keys alone or with other keys
        onKeyCaptured?(keyCode, modifiers)
    }

    override func flagsChanged(with event: NSEvent) {
        guard isCapturing else {
            super.flagsChanged(with: event)
            return
        }

        // Capture modifier-only keys (Option, Control, Shift, Command)
        let keyCode = event.keyCode
        var modifiers: UInt32 = 0

        if event.modifierFlags.contains(.command) {
            modifiers |= 256
        }
        if event.modifierFlags.contains(.shift) {
            modifiers |= 512
        }
        if event.modifierFlags.contains(.option) {
            modifiers |= 2048
        }
        if event.modifierFlags.contains(.control) {
            modifiers |= 4096
        }

        // Only capture on key down (when modifier is pressed)
        // Check if this is a modifier key being pressed
        let isModifierKey = keyCode >= 54 && keyCode <= 63
        if isModifierKey && modifiers != 0 {
            onKeyCaptured?(keyCode, modifiers)
        }
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }
}
