//
//  AppCoordinatorTests.swift
//  TypewriterApp Tests
//
//  Tests for AppCoordinator state machine and settings integration.
//  NOTE: Requires Xcode.app (not just Command Line Tools) to run.
//

import XCTest
@testable import TypewriterApp

final class AppCoordinatorTests: XCTestCase {

    // MARK: - AppState Equatable

    func testAppStateEquality() {
        XCTAssertEqual(AppState.idle, AppState.idle)
        XCTAssertEqual(AppState.recording, AppState.recording)
        XCTAssertEqual(AppState.processing, AppState.processing)
        XCTAssertEqual(AppState.pasting, AppState.pasting)
        XCTAssertEqual(AppState.error(message: "oops"), AppState.error(message: "oops"))
        XCTAssertNotEqual(AppState.idle, AppState.recording)
        XCTAssertNotEqual(AppState.error(message: "a"), AppState.error(message: "b"))
        XCTAssertNotEqual(AppState.idle, AppState.error(message: ""))
    }

    // MARK: - Recording mode

    func testRecordingModesAreDistinct() {
        XCTAssertNotEqual(RecordingMode.pushToTalk, RecordingMode.handsFree)
        XCTAssertEqual(RecordingMode.pushToTalk, RecordingMode.pushToTalk)
    }

    // MARK: - Max recording duration constants

    func testMaxDurationIsExactlyFiveMinutes() {
        XCTAssertEqual(AppCoordinator.maxRecordingDuration, 300)
    }

    func testMaxDurationWarningIsThirtySeconds() {
        XCTAssertEqual(AppCoordinator.maxDurationWarning, 30)
    }

    // MARK: - Validator integration

    func testValidatorRejectsEmptyAudio() {
        let result = Validator.validateAudioSize(Data())
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func testValidatorRejectsZeroDuration() {
        let result = Validator.validateAudioDuration(0.0)
        XCTAssertFalse(result.isValid)
    }

    func testValidatorAcceptsTypicalAudio() {
        let result = Validator.validateAudioSize(Data(count: 1024 * 100))
        XCTAssertTrue(result.isValid)
    }

    func testValidatorAcceptsTypicalDuration() {
        let result = Validator.validateAudioDuration(10.0)
        XCTAssertTrue(result.isValid)
    }

    func testValidatorRejectsDurationAboveMax() {
        // Validator uses its own constant (300s); verify alignment with coordinator
        let result = Validator.validateAudioDuration(AppCoordinator.maxRecordingDuration + 1)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - OverlayState display text

    func testOverlayErrorShowsActualMessage() {
        let state = OverlayState.error(message: "Something went wrong")
        XCTAssertEqual(state.displayText, "Something went wrong")
    }

    func testOverlayDoneDisplayText() {
        XCTAssertEqual(OverlayState.done.displayText, "Done")
    }

    func testOverlayProcessingDisplayText() {
        XCTAssertEqual(OverlayState.processing.displayText, "Processing...")
    }

    func testOverlayRecordingHasNoText() {
        XCTAssertNil(OverlayState.recording.displayText)
    }

    func testOverlayHiddenHasNoText() {
        XCTAssertNil(OverlayState.hidden.displayText)
    }

    // MARK: - OverlayState icon flags

    func testRecordingShowsSoundBars() {
        XCTAssertTrue(OverlayState.recording.showSoundBars)
        XCTAssertFalse(OverlayState.processing.showSoundBars)
    }

    func testProcessingShowsSpinner() {
        XCTAssertTrue(OverlayState.processing.showSpinner)
        XCTAssertFalse(OverlayState.recording.showSpinner)
    }

    func testDoneShowsCheckmark() {
        XCTAssertTrue(OverlayState.done.showCheckmark)
        XCTAssertFalse(OverlayState.recording.showCheckmark)
    }

    func testErrorShowsErrorIcon() {
        XCTAssertTrue(OverlayState.error(message: "").showErrorIcon)
        XCTAssertFalse(OverlayState.done.showErrorIcon)
    }

    // MARK: - HotkeyConfiguration defaults

    func testDefaultPushToTalkIsOptionKey() {
        let hotkey = HotkeyConfiguration.defaultPushToTalk
        XCTAssertEqual(hotkey.keyCode, 58) // Left Option
        XCTAssertFalse(hotkey.displayString.isEmpty)
    }

    func testDefaultHandsFreeIsControlKey() {
        let hotkey = HotkeyConfiguration.defaultHandsFree
        XCTAssertEqual(hotkey.keyCode, 59) // Left Control
        XCTAssertFalse(hotkey.displayString.isEmpty)
    }
}
