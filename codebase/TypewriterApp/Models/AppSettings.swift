//
//  AppSettings.swift
//  Typewriter
//
//  User preferences and configuration
//

import Foundation

struct AppSettings: Codable, Equatable {
    var pushToTalkHotkeys: [HotkeyConfiguration]
    var handsFreeHotkeys: [HotkeyConfiguration]
    var openAIApiKey: String
    var customInstructions: String
    var selectedMicrophone: String // Device ID
    var selectedAPIModel: OpenAIModel
    var saveTranscriptionsLocally: Bool
    var transcriptionStoragePath: URL

    // Legacy support
    var hotkeyConfiguration: HotkeyConfiguration {
        get { handsFreeHotkeys.first ?? .defaultHandsFree }
        set {
            if handsFreeHotkeys.isEmpty {
                handsFreeHotkeys = [newValue]
            } else {
                handsFreeHotkeys[0] = newValue
            }
        }
    }

    static var `default`: AppSettings {
        AppSettings(
            pushToTalkHotkeys: [.defaultPushToTalk],
            handsFreeHotkeys: [.defaultHandsFree],
            openAIApiKey: "",
            customInstructions: "",
            selectedMicrophone: "default",
            selectedAPIModel: .gpt4oTranscribe,
            saveTranscriptionsLocally: false,
            transcriptionStoragePath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Typewriter")
                .appendingPathComponent("transcriptions.csv")
        )
    }
}

struct HotkeyConfiguration: Codable, Equatable, Identifiable {
    var id: UUID
    var keyCode: UInt16
    var modifiers: UInt32

    init(keyCode: UInt16, modifiers: UInt32) {
        self.id = UUID()
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init(id: UUID = UUID(), keyCode: UInt16, modifiers: UInt32) {
        self.id = id
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    // Default for Push to Talk: Option key
    static var defaultPushToTalk: HotkeyConfiguration {
        HotkeyConfiguration(keyCode: 58, modifiers: 2048) // Option key
    }

    // Default for Hands-free: Control key
    static var defaultHandsFree: HotkeyConfiguration {
        HotkeyConfiguration(keyCode: 59, modifiers: 4096) // Control key
    }

    // Legacy default
    static var `default`: HotkeyConfiguration {
        defaultHandsFree
    }

    var displayString: String {
        var components: [String] = []
        if modifiers & 256 != 0 { components.append("⌘") }
        if modifiers & 512 != 0 { components.append("⇧") }
        if modifiers & 2048 != 0 { components.append("⌥") }
        if modifiers & 4096 != 0 { components.append("⌃") }

        // Map common key codes to readable names
        let keyName: String
        switch keyCode {
        case 49: keyName = "Space"
        case 36: keyName = "Return"
        case 48: keyName = "Tab"
        case 51: keyName = "Delete"
        case 53: keyName = "Escape"
        case 55: keyName = "Cmd"
        case 56: keyName = "Shift"
        case 57: keyName = "Caps"
        case 58: keyName = "Opt"
        case 59: keyName = "Ctrl"
        case 60: keyName = "Right Shift"
        case 61: keyName = "Right Opt"
        case 62: keyName = "Right Ctrl"
        case 63: keyName = "Fn"
        case 123: keyName = "←"
        case 124: keyName = "→"
        case 125: keyName = "↓"
        case 126: keyName = "↑"
        default:
            // For letter keys (a-z)
            if keyCode >= 0 && keyCode <= 11 {
                let letters = ["A", "S", "D", "F", "H", "G", "Z", "X", "C", "V", "B", "Q"]
                keyName = letters[Int(keyCode)]
            } else if keyCode >= 12 && keyCode <= 34 {
                let letters = ["W", "E", "R", "Y", "T", "1", "2", "3", "4", "6", "5", "=", "9", "7", "-", "8", "0", "]", "O", "U", "[", "I", "P"]
                keyName = letters[Int(keyCode - 12)]
            } else {
                keyName = "Key\(keyCode)"
            }
        }

        // For modifier-only keys, just show the key name with symbol
        if keyCode >= 55 && keyCode <= 63 {
            let symbol: String
            switch keyCode {
            case 58, 61: symbol = "⌥ "  // Option
            case 59, 62: symbol = "⌃ "  // Control
            case 55: symbol = "⌘ "      // Command
            case 56, 60: symbol = "⇧ "  // Shift
            default: symbol = ""
            }
            return symbol + keyName
        }

        components.append(keyName)
        return components.joined()
    }
}

enum RecordingMode: Equatable {
    case pushToTalk  // Hold to record, release to stop
    case handsFree   // Press to start, press again to stop
}

enum OpenAIModel: String, Codable, CaseIterable {
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
    case whisper1 = "whisper-1"

    var displayName: String {
        switch self {
        case .gpt4oTranscribe: return "GPT-4o Transcribe (Best quality)"
        case .gpt4oMiniTranscribe: return "GPT-4o Mini Transcribe (Faster, cheaper)"
        case .whisper1: return "Whisper-1 (Legacy)"
        }
    }

    var description: String {
        switch self {
        case .gpt4oTranscribe: return "$0.006/min - Best accuracy, lower word error rate"
        case .gpt4oMiniTranscribe: return "$0.003/min - Good accuracy, cost-effective"
        case .whisper1: return "$0.006/min - Original Whisper model"
        }
    }
}
