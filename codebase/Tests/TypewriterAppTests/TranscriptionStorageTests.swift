//
//  TranscriptionStorageTests.swift
//  TypewriterApp Tests
//
//  Unit tests for TranscriptionStorage
//

import XCTest
@testable import TypewriterApp

final class TranscriptionStorageTests: XCTestCase {
    var storage: TranscriptionStorage!

    override func setUp() {
        super.setUp()
        storage = TranscriptionStorage.shared
        storage.deleteAll()
    }

    override func tearDown() {
        storage.deleteAll()
        super.tearDown()
    }

    func testSaveAndLoadTranscription() {
        let transcription = Transcription(
            duration: 10.5,
            text: "Hello world",
            customInstructions: "Test instructions"
        )

        storage.save(transcription)

        let loaded = storage.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.text, "Hello world")
        XCTAssertEqual(loaded.first?.duration, 10.5)
    }

    func testSaveMultipleTranscriptions() {
        for i in 1...5 {
            let transcription = Transcription(
                duration: Double(i),
                text: "Test \(i)",
                customInstructions: ""
            )
            storage.save(transcription)
        }

        let loaded = storage.loadAll()
        XCTAssertEqual(loaded.count, 5)
    }

    func testDeleteAll() {
        let transcription = Transcription(
            duration: 5.0,
            text: "Test",
            customInstructions: ""
        )
        storage.save(transcription)

        storage.deleteAll()

        let loaded = storage.loadAll()
        XCTAssertEqual(loaded.count, 0)
    }

    func testCSVEscaping() {
        let transcription = Transcription(
            duration: 1.0,
            text: "Text with \"quotes\" and, commas",
            customInstructions: "Instructions with \"quotes\""
        )

        storage.save(transcription)

        let loaded = storage.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.text, "Text with \"quotes\" and, commas")
    }
}
