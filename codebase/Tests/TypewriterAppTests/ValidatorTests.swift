//
//  ValidatorTests.swift
//  TypewriterApp Tests
//
//  Unit tests for Validator
//

import XCTest
@testable import TypewriterApp

final class ValidatorTests: XCTestCase {

    // MARK: - API Key Validation Tests

    func testValidAPIKey() {
        let result = Validator.validateAPIKey("sk-1234567890abcdefghij")
        XCTAssertTrue(result.isValid)
    }

    func testEmptyAPIKey() {
        let result = Validator.validateAPIKey("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "API key cannot be empty")
    }

    func testAPIKeyWithoutPrefix() {
        let result = Validator.validateAPIKey("1234567890abcdefghij")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "API key should start with 'sk-'")
    }

    func testAPIKeyTooShort() {
        let result = Validator.validateAPIKey("sk-short")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "API key appears too short")
    }

    // MARK: - Audio Duration Validation Tests

    func testValidAudioDuration() {
        let result = Validator.validateAudioDuration(30.0)
        XCTAssertTrue(result.isValid)
    }

    func testZeroAudioDuration() {
        let result = Validator.validateAudioDuration(0.0)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "No audio recorded")
    }

    func testAudioDurationTooLong() {
        let result = Validator.validateAudioDuration(400.0)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Recording too long (max 5 minutes)")
    }

    // MARK: - Audio Size Validation Tests

    func testValidAudioSize() {
        let data = Data(count: 1024 * 1024) // 1MB
        let result = Validator.validateAudioSize(data)
        XCTAssertTrue(result.isValid)
    }

    func testEmptyAudioData() {
        let data = Data()
        let result = Validator.validateAudioSize(data)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "No audio data")
    }

    func testAudioSizeTooLarge() {
        let data = Data(count: 26 * 1024 * 1024) // 26MB
        let result = Validator.validateAudioSize(data)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Audio file too large (max 25MB)")
    }
}
