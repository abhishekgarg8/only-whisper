//
//  Validator.swift
//  Typewriter
//
//  Input validation utilities
//

import Foundation

struct Validator {
    // MARK: - API Key Validation

    static func validateAPIKey(_ apiKey: String) -> ValidationResult {
        guard !apiKey.isEmpty else {
            return .invalid("API key cannot be empty")
        }

        guard apiKey.hasPrefix("sk-") else {
            return .invalid("API key should start with 'sk-'")
        }

        guard apiKey.count >= 20 else {
            return .invalid("API key appears too short")
        }

        return .valid
    }

    // MARK: - Audio Duration Validation

    static func validateAudioDuration(_ duration: TimeInterval) -> ValidationResult {
        let maxDuration: TimeInterval = 300 // 5 minutes

        guard duration > 0 else {
            return .invalid("No audio recorded")
        }

        guard duration <= maxDuration else {
            return .invalid("Recording too long (max 5 minutes)")
        }

        return .valid
    }

    // MARK: - File Size Validation

    static func validateAudioSize(_ data: Data) -> ValidationResult {
        let maxSize = 25 * 1024 * 1024 // 25MB (OpenAI limit)

        guard !data.isEmpty else {
            return .invalid("No audio data")
        }

        guard data.count <= maxSize else {
            return .invalid("Audio file too large (max 25MB)")
        }

        return .valid
    }
}

enum ValidationResult {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}
