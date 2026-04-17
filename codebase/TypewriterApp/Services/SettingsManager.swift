//
//  SettingsManager.swift
//  Typewriter
//
//  Persistent storage for user preferences
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "com.typewriter.app.settings"

    @Published private(set) var currentSettings: AppSettings

    init() {
        self.currentSettings = Self.loadFromDefaults() ?? AppSettings.default
    }

    func loadSettings() -> AppSettings {
        return currentSettings
    }

    func saveSettings(_ settings: AppSettings) {
        currentSettings = settings
        Self.saveToDefaults(settings)
    }

    func resetToDefaults() {
        let defaultSettings = AppSettings.default
        saveSettings(defaultSettings)
    }

    // MARK: - Private Helpers

    private static func loadFromDefaults() -> AppSettings? {
        guard let data = UserDefaults.standard.data(forKey: "com.typewriter.app.settings") else {
            return nil
        }

        do {
            let settings = try JSONDecoder().decode(AppSettings.self, from: data)
            return settings
        } catch {
            print("Failed to decode settings: \(error)")
            return nil
        }
    }

    private static func saveToDefaults(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: "com.typewriter.app.settings")
        } catch {
            print("Failed to encode settings: \(error)")
        }
    }
}
