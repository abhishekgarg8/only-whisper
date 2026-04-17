//
//  TextPastingService.swift
//  Typewriter
//
//  Text injection via clipboard and simulated paste
//

import AppKit
import CoreGraphics

class TextPastingService {
    static let shared = TextPastingService()

    private init() {}

    func pasteText(_ text: String) {
        // 1. Save current clipboard content
        let pasteboard = NSPasteboard.general
        let savedContent = pasteboard.string(forType: .string)

        // 2. Copy transcription to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // 3. Simulate Cmd+V keypress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateCommandV()

            // 4. Restore original clipboard after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                if let saved = savedContent {
                    pasteboard.setString(saved, forType: .string)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func simulateCommandV() {
        // Create Cmd+V keypress event
        let vKeyCode: CGKeyCode = 9 // 'V' key

        // Key down with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }

        // Key up
        if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
