//
//  OverlayState.swift
//  Typewriter
//
//  Overlay panel states
//

import Foundation

enum OverlayState: Equatable {
    case hidden
    case recording
    case processing
    case done
    case error(message: String)

    var displayText: String? {
        switch self {
        case .hidden:
            return nil
        case .recording:
            return nil // Show sound bars only
        case .processing:
            return "Processing..."
        case .done:
            return "Done"
        case .error(let message):
            return message
        }
    }

    var showSoundBars: Bool {
        if case .recording = self {
            return true
        }
        return false
    }

    var showSpinner: Bool {
        if case .processing = self {
            return true
        }
        return false
    }

    var showCheckmark: Bool {
        if case .done = self {
            return true
        }
        return false
    }

    var showErrorIcon: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}
