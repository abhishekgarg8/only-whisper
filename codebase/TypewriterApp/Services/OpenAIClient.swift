//
//  OpenAIClient.swift
//  Typewriter
//
//  OpenAI Whisper API client with timeout and cancellation support
//

import Foundation

class OpenAIClient {
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    private let modelsURL = "https://api.openai.com/v1/models"
    let session: URLSession

    /// Creates a client with an optional URLSession (injectable for testing).
    /// Production builds get a session with a 30-second request timeout.
    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30   // 30-second per-request timeout
            config.timeoutIntervalForResource = 120 // 2-minute overall resource timeout
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - API Key Validation

    /// Validates the API key by performing a lightweight GET to the models endpoint.
    func validateAPIKey(_ apiKey: String) async throws {
        guard !apiKey.isEmpty else {
            throw OpenAIError.invalidAPIKey
        }

        guard let url = URL(string: modelsURL) else {
            throw OpenAIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return
        case 401:
            throw OpenAIError.invalidAPIKey
        case 429:
            throw OpenAIError.rateLimitExceeded(retryAfter: retryAfterSeconds(from: httpResponse))
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.serverError(message)
        }
    }

    // MARK: - Transcription

    /// Transcribes audio data using the Whisper API.
    /// Supports Swift cooperative cancellation — cancel the parent Task to abort mid-flight.
    func transcribe(
        audio: Data,
        apiKey: String,
        customInstructions: String?,
        model: OpenAIModel
    ) async throws -> TranscriptionResponse {
        print("📤 Starting transcription...")
        print("   Audio size: \(audio.count) bytes")
        print("   Model: \(model.rawValue)")

        guard !apiKey.isEmpty else {
            print("❌ API key is empty")
            throw OpenAIError.invalidAPIKey
        }

        guard audio.count > 0 else {
            print("❌ Audio data is empty")
            throw OpenAIError.invalidResponse
        }

        let request = try createMultipartRequest(
            audio: audio,
            apiKey: apiKey,
            customInstructions: customInstructions,
            model: model
        )

        print("📡 Sending request to OpenAI...")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw OpenAIError.requestCancelled
        } catch let error as URLError where error.code == .timedOut {
            throw OpenAIError.networkError(error)
        } catch {
            if Task.isCancelled { throw OpenAIError.requestCancelled }
            throw OpenAIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200:
            let transcription = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            print("✅ Transcription: \"\(transcription.text.prefix(50))\"")
            return transcription

        case 401:
            print("❌ Invalid API key")
            throw OpenAIError.invalidAPIKey

        case 429:
            print("❌ Rate limit exceeded")
            throw OpenAIError.rateLimitExceeded(retryAfter: retryAfterSeconds(from: httpResponse))

        case 400...499:
            let message = String(data: data, encoding: .utf8) ?? "Unknown client error"
            print("❌ Client error (\(httpResponse.statusCode)): \(message)")
            throw OpenAIError.serverError(message)

        case 500...599:
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            print("❌ Server error (\(httpResponse.statusCode)): \(message)")
            throw OpenAIError.serverError(message)

        default:
            throw OpenAIError.invalidResponse
        }
    }

    // MARK: - Private Helpers

    private func createMultipartRequest(
        audio: Data,
        apiKey: String,
        customInstructions: String?,
        model: OpenAIModel
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Audio file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audio)
        body.append("\r\n".data(using: .utf8)!)

        // Model part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append(model.rawValue.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Optional custom instructions (as Whisper prompt)
        if let instructions = customInstructions, !instructions.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append(instructions.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        return request
    }

    /// Parses the `Retry-After` response header into an integer number of seconds.
    private func retryAfterSeconds(from response: HTTPURLResponse) -> Int? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
        return Int(value)
    }
}
