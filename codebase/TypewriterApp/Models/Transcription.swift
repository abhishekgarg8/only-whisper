//
//  Transcription.swift
//  Typewriter
//
//  Transcription record model
//

import Foundation

struct Transcription: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let duration: TimeInterval
    let text: String
    let customInstructions: String

    init(id: UUID = UUID(), timestamp: Date = Date(), duration: TimeInterval, text: String, customInstructions: String = "") {
        self.id = id
        self.timestamp = timestamp
        self.duration = duration
        self.text = text
        self.customInstructions = customInstructions
    }

    var textPreview: String {
        if text.count <= 100 {
            return text
        }
        return String(text.prefix(100)) + "..."
    }
}
