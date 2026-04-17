//
//  OpenAIModels.swift
//  Typewriter
//
//  OpenAI API request/response models and error types
//

import Foundation

struct TranscriptionRequest {
    let audioData: Data
    let fileName: String
    let model: OpenAIModel
    let prompt: String?
}

struct TranscriptionResponse: Codable {
    let text: String
}

enum OpenAIError: Error, LocalizedError {
    case invalidAPIKey
    /// - retryAfter: seconds to wait, parsed from the Retry-After response header (nil if not provided)
    case rateLimitExceeded(retryAfter: Int?)
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case requestCancelled

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Check your settings."
        case .rateLimitExceeded(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limit exceeded. Please wait \(seconds) seconds."
            }
            return "Rate limit exceeded. Please wait a moment."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let message):
            return "Server error: \(message)"
        case .requestCancelled:
            return "Request was cancelled."
        }
    }
}
