//
//  SettingsManagerTests.swift
//  TypewriterApp Tests
//
//  Unit tests for SettingsManager
//

import XCTest
@testable import TypewriterApp

final class SettingsManagerTests: XCTestCase {
    var settingsManager: SettingsManager!

    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
        // Clear any existing settings
        UserDefaults.standard.removeObject(forKey: "com.typewriter.app.settings")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "com.typewriter.app.settings")
        settingsManager = nil
        super.tearDown()
    }

    func testDefaultSettings() {
        let settings = settingsManager.loadSettings()

        XCTAssertEqual(settings.openAIApiKey, "")
        XCTAssertEqual(settings.customInstructions, "")
        XCTAssertEqual(settings.selectedMicrophone, "default")
        XCTAssertEqual(settings.selectedAPIModel, .gpt4oTranscribe)
        XCTAssertFalse(settings.saveTranscriptionsLocally)
    }

    func testSaveAndLoadSettings() {
        var settings = settingsManager.loadSettings()
        settings.openAIApiKey = "sk-test123"
        settings.customInstructions = "Format as bullet points"
        settings.saveTranscriptionsLocally = true

        settingsManager.saveSettings(settings)

        let loaded = settingsManager.loadSettings()
        XCTAssertEqual(loaded.openAIApiKey, "sk-test123")
        XCTAssertEqual(loaded.customInstructions, "Format as bullet points")
        XCTAssertTrue(loaded.saveTranscriptionsLocally)
    }

    func testResetToDefaults() {
        var settings = settingsManager.loadSettings()
        settings.openAIApiKey = "sk-test123"
        settingsManager.saveSettings(settings)

        settingsManager.resetToDefaults()

        let reset = settingsManager.loadSettings()
        XCTAssertEqual(reset.openAIApiKey, "")
    }
}
