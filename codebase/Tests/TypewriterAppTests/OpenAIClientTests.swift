//
//  OpenAIClientTests.swift
//  TypewriterApp Tests
//
//  Unit tests for OpenAIClient using MockURLProtocol to avoid real network calls.
//  NOTE: Requires Xcode.app (not just Command Line Tools) to run.
//

import XCTest
@testable import TypewriterApp

// MARK: - Mock URLProtocol

/// Intercepts URLSession requests and returns pre-configured stub responses.
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - OpenAIClientTests

final class OpenAIClientTests: XCTestCase {

    // MARK: - Helpers

    private func makeMockClient() -> OpenAIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return OpenAIClient(session: URLSession(configuration: config))
    }

    private func makeResponse(statusCode: Int, url: URL,
                              headers: [String: String]? = nil) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode,
                        httpVersion: nil, headerFields: headers)!
    }

    private let apiURL = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private let validAudio = Data(repeating: 0xFF, count: 1024)
    private let validKey = "sk-testvalidapikey12345"

    // MARK: - Input validation (no network call needed)

    func testTranscribeEmptyAPIKeyThrowsImmediately() async {
        let client = makeMockClient()
        do {
            _ = try await client.transcribe(audio: validAudio, apiKey: "",
                                            customInstructions: nil, model: .whisper1)
            XCTFail("Should have thrown")
        } catch let err as OpenAIError {
            if case .invalidAPIKey = err { return }
            XCTFail("Expected invalidAPIKey, got \(err)")
        } catch { XCTFail("Wrong error type") }
    }

    func testTranscribeEmptyAudioThrowsImmediately() async {
        let client = makeMockClient()
        do {
            _ = try await client.transcribe(audio: Data(), apiKey: validKey,
                                            customInstructions: nil, model: .whisper1)
            XCTFail("Should have thrown")
        } catch let err as OpenAIError {
            if case .invalidResponse = err { return }
            XCTFail("Expected invalidResponse, got \(err)")
        } catch { XCTFail("Wrong error type") }
    }

    // MARK: - HTTP error mapping

    func testTranscribe401ThrowsInvalidAPIKey() async {
        let client = makeMockClient()
        MockURLProtocol.requestHandler = { [self] _ in (makeResponse(statusCode: 401, url: apiURL), Data()) }
        do {
            _ = try await client.transcribe(audio: validAudio, apiKey: validKey,
                                            customInstructions: nil, model: .whisper1)
            XCTFail("Should have thrown")
        } catch let err as OpenAIError {
            if case .invalidAPIKey = err { return }
            XCTFail("Expected invalidAPIKey, got \(err)")
        } catch { XCTFail("Wrong error type") }
    }

    func testTranscribe429WithNoRetryAfter() async {
        let client = makeMockClient()
        MockURLProtocol.requestHandler = { [self] _ in (makeResponse(statusCode: 429, url: apiURL), Data()) }
        do {
            _ = try await client.transcribe(audio: validAudio, apiKey: validKey,
                                            customInstructions: nil, model: .whisper1)
            XCTFail("Should have thrown")
        } catch let err as OpenAIError {
            guard case .rateLimitExceeded(let after) = err else {
                XCTFail("Expected rateLimitExceeded"); return
            }
            XCTAssertNil(after)
        } catch { XCTFail("Wrong error type") }
    }

    func testTranscribe429ParsesRetryAfterHeader() async {
        let client = makeMockClient()
        MockURLProtocol.requestHandler = { [self] _ in
            (makeResponse(statusCode: 429, url: apiURL, headers: ["Retry-After": "60"]), Data())
        }
        do {
            _ = try await client.transcribe(audio: validAudio, apiKey: validKey,
                                            customInstructions: nil, model: .whisper1)
            XCTFail("Should have thrown")
        } catch let err as OpenAIError {
            guard case .rateLimitExceeded(let after) = err else {
                XCTFail("Expected rateLimitExceeded"); return
            }
            XCTAssertEqual(after, 60)
        } catch { XCTFail("Wrong error type") }
    }

    func testTranscribe200ReturnsText() async throws {
        let client = makeMockClient()
        MockURLProtocol.requestHandler = { [self] _ in
            (makeResponse(statusCode: 200, url: apiURL),
             #"{"text":"Hello, world!"}"#.data(using: .utf8)!)
        }
        let result = try await client.transcribe(audio: validAudio, apiKey: validKey,
                                                 customInstructions: nil, model: .whisper1)
        XCTAssertEqual(result.text, "Hello, world!")
    }

    func testTranscribe500ThrowsServerError() async {
        let client = makeMockClient()
        MockURLProtocol.requestHandler = { [self] _ in
            (makeResponse(statusCode: 500, url: apiURL), "Server Error".data(using: .utf8)!)
        }
        do {
            _ = try await client.transcribe(audio: validAudio, apiKey: validKey,
                                            customInstructions: nil, model: .whisper1)
            XCTFail("Should have thrown")
        } catch let err as OpenAIError {
            if case .serverError = err { return }
            XCTFail("Expected serverError, got \(err)")
        } catch { XCTFail("Wrong error type") }
    }

    // MARK: - Error descriptions

    func testRateLimitWithRetryAfterDescription() {
        let err = OpenAIError.rateLimitExceeded(retryAfter: 30)
        XCTAssertEqual(err.errorDescription, "Rate limit exceeded. Please wait 30 seconds.")
    }

    func testRateLimitWithoutRetryAfterDescription() {
        let err = OpenAIError.rateLimitExceeded(retryAfter: nil)
        XCTAssertEqual(err.errorDescription, "Rate limit exceeded. Please wait a moment.")
    }

    // MARK: - validateAPIKey

    func testValidateAPIKeyEmptyThrows() async {
        let client = makeMockClient()
        do {
            try await client.validateAPIKey("")
            XCTFail("Should have thrown")
        } catch let err as OpenAIError {
            if case .invalidAPIKey = err { return }
            XCTFail("Expected invalidAPIKey")
        } catch { XCTFail("Wrong error type") }
    }

    func testValidateAPIKey401Throws() async {
        let client = makeMockClient()
        let modelsURL = URL(string: "https://api.openai.com/v1/models")!
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: modelsURL, statusCode: 401,
                             httpVersion: nil, headerFields: nil)!, Data())
        }
        do {
            try await client.validateAPIKey(validKey)
            XCTFail("Should have thrown")
        } catch let err as OpenAIError {
            if case .invalidAPIKey = err { return }
            XCTFail("Expected invalidAPIKey, got \(err)")
        } catch { XCTFail("Wrong error type") }
    }

    func testValidateAPIKey200Succeeds() async throws {
        let client = makeMockClient()
        let modelsURL = URL(string: "https://api.openai.com/v1/models")!
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: modelsURL, statusCode: 200,
                             httpVersion: nil, headerFields: nil)!, Data())
        }
        try await client.validateAPIKey(validKey)  // should not throw
    }
}
