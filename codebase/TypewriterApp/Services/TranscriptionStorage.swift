//
//  TranscriptionStorage.swift
//  Typewriter
//
//  CSV-based transcription persistence with append and delete support
//

import Foundation

class TranscriptionStorage {
    static let shared = TranscriptionStorage()

    private let fileManager = FileManager.default
    private var storageURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let typewriterDir = documentsPath.appendingPathComponent("Typewriter")
        try? fileManager.createDirectory(at: typewriterDir, withIntermediateDirectories: true)
        return typewriterDir.appendingPathComponent("transcriptions.csv")
    }

    private init() {
        initializeCSVIfNeeded()
    }

    // MARK: - Public Methods

    /// Appends a new transcription row to the CSV file.
    func save(_ transcription: Transcription) {
        print("💾 [Storage] Saving transcription to: \(storageURL.path)")

        let csvLine = formatAsCSVLine(transcription)

        do {
            let directory = storageURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            if fileManager.fileExists(atPath: storageURL.path) {
                let fileHandle = try FileHandle(forWritingTo: storageURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(csvLine.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
                print("✅ [Storage] Appended to existing file")
            } else {
                let header = "timestamp,duration_seconds,text,instructions\n"
                try (header + csvLine).write(to: storageURL, atomically: true, encoding: .utf8)
                print("✅ [Storage] Created new file with header")
            }
        } catch {
            print("❌ [Storage] Failed to save: \(error)")
        }
    }

    /// Loads all stored transcriptions in chronological order.
    func loadAll() -> [Transcription] {
        guard fileManager.fileExists(atPath: storageURL.path) else { return [] }

        do {
            let content = try String(contentsOf: storageURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { return [] }
            return lines.dropFirst().compactMap { parseCSVLine($0) }
        } catch {
            print("❌ [Storage] Failed to load: \(error)")
            return []
        }
    }

    /// Deletes a specific transcription by matching on timestamp and text.
    /// Since IDs are not stored in the CSV, this identifies entries by content.
    func delete(matching transcription: Transcription) {
        var all = loadAll()
        all.removeAll {
            abs($0.timestamp.timeIntervalSince(transcription.timestamp)) < 1.0 &&
            $0.text == transcription.text
        }
        rewriteCSV(all)
        print("🗑️ [Storage] Deleted transcription; \(all.count) remaining")
    }

    /// Deletes all stored transcriptions and resets the file to headers only.
    func deleteAll() {
        try? fileManager.removeItem(at: storageURL)
        initializeCSVIfNeeded()
        print("🗑️ [Storage] Deleted all transcriptions")
    }

    // MARK: - Private Helpers

    private func initializeCSVIfNeeded() {
        guard !fileManager.fileExists(atPath: storageURL.path) else { return }
        let header = "timestamp,duration_seconds,text,instructions\n"
        try? header.write(to: storageURL, atomically: true, encoding: .utf8)
    }

    /// Rewrites the entire CSV from an in-memory array (used after deletes).
    private func rewriteCSV(_ transcriptions: [Transcription]) {
        let header = "timestamp,duration_seconds,text,instructions\n"
        let rows = transcriptions.map { formatAsCSVLine($0) }.joined()
        do {
            try (header + rows).write(to: storageURL, atomically: true, encoding: .utf8)
        } catch {
            print("❌ [Storage] Failed to rewrite CSV: \(error)")
        }
    }

    private func formatAsCSVLine(_ transcription: Transcription) -> String {
        let timestamp = ISO8601DateFormatter().string(from: transcription.timestamp)
        let duration = String(format: "%.1f", transcription.duration)
        let text = escapeCSV(transcription.text)
        let instructions = escapeCSV(transcription.customInstructions)
        return "\(timestamp),\(duration),\(text),\(instructions)\n"
    }

    private func parseCSVLine(_ line: String) -> Transcription? {
        let components = parseCSVComponents(line)
        guard components.count >= 4 else { return nil }
        guard let timestamp = ISO8601DateFormatter().date(from: components[0]),
              let duration = Double(components[1]) else { return nil }
        return Transcription(
            timestamp: timestamp,
            duration: duration,
            text: components[2],
            customInstructions: components[3]
        )
    }

    private func escapeCSV(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func parseCSVComponents(_ line: String) -> [String] {
        var components: [String] = []
        var currentComponent = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                components.append(currentComponent.trimmingCharacters(in: .whitespaces))
                currentComponent = ""
            } else {
                currentComponent.append(char)
            }
        }

        components.append(currentComponent.trimmingCharacters(in: .whitespaces))
        return components
    }
}
