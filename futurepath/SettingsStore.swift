//
//  SettingsStore.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Persistent store for user settings with dual-write (UserDefaults + JSON backup).

final class SettingsStore: ObservableObject {

    // MARK: - Published

    @Published private(set) var model: SettingsModel {
        didSet { persist() }
    }

    // MARK: - Private

    private let store = FileStore.shared
    private let fileName = "settings.json"
    private let ud = UserDefaults.standard

    private enum Key {
        static let isDarkMode       = "settings.isDarkMode"
        static let accentColorID    = "settings.accentColorID"
        static let enableHaptics    = "settings.enableHaptics"
        static let autoCarryTasks   = "settings.autoCarryTasks"
        static let preferredLanguage = "settings.preferredLanguage"
    }

    // MARK: - Init

    init() {
        // Step 1: Try to load from JSON file
        if let json: SettingsModel = store.load(SettingsModel.self, from: fileName) {
            self.model = json
            writeUserDefaults(from: json)
            return
        }

        // Step 2: Try to load from UserDefaults
        if let fromUD = Self.readUserDefaultsStatic() {
            self.model = fromUD
            store.save(fromUD, as: fileName)
            return
        }

        // Step 3: Use default values
        let defaults = SettingsModel()
        self.model = defaults
        persist()
    }

    // MARK: - Public API (mutations)

    func setDarkMode(_ isOn: Bool) {
        guard model.isDarkMode != isOn else { return }
        model.isDarkMode = isOn
    }

    func toggleDarkMode() {
        model.isDarkMode.toggle()
    }

    func setAccentColorID(_ id: String) {
        guard model.accentColorID != id else { return }
        model.accentColorID = id
    }

    func setHapticsEnabled(_ isOn: Bool) {
        guard model.enableHaptics != isOn else { return }
        model.enableHaptics = isOn
    }

    func setAutoCarryTasks(_ isOn: Bool) {
        guard model.autoCarryTasks != isOn else { return }
        model.autoCarryTasks = isOn
    }

    func setLanguage(_ code: String) {
        let normalized = code.lowercased()
        guard model.preferredLanguage != normalized else { return }
        model.preferredLanguage = normalized
    }

    /// Resets settings to defaults.
    func resetToDefaults() {
        model = SettingsModel()
    }

    // MARK: - Convenience accessors

    var isDarkMode: Bool { model.isDarkMode }
    var accentColor: Color { model.accentColor }
    var hapticsEnabled: Bool { model.enableHaptics }
    var autoCarryEnabled: Bool { model.autoCarryTasks }
    var languageCode: String { model.preferredLanguage }

    // MARK: - Persistence

    private static func readUserDefaultsStatic() -> SettingsModel? {
        let ud = UserDefaults.standard

        guard ud.object(forKey: "settings.isDarkMode") != nil ||
              ud.object(forKey: "settings.accentColorID") != nil ||
              ud.object(forKey: "settings.enableHaptics") != nil ||
              ud.object(forKey: "settings.autoCarryTasks") != nil ||
              ud.object(forKey: "settings.preferredLanguage") != nil else {
            return nil
        }

        let isDarkMode = ud.bool(forKey: "settings.isDarkMode")
        let accentID = ud.string(forKey: "settings.accentColorID") ?? "brandBlue"
        let enableHaptics = ud.object(forKey: "settings.enableHaptics") as? Bool ?? true
        let autoCarry = ud.object(forKey: "settings.autoCarryTasks") as? Bool ?? true
        let lang = ud.string(forKey: "settings.preferredLanguage") ?? "en"

        return SettingsModel(
            isDarkMode: isDarkMode,
            accentColorID: accentID,
            enableHaptics: enableHaptics,
            autoCarryTasks: autoCarry,
            preferredLanguage: lang
        )
    }
    
    
    private func persist() {
        writeUserDefaults(from: model)
        store.save(model, as: fileName)
    }

    private func writeUserDefaults(from m: SettingsModel) {
        ud.set(m.isDarkMode, forKey: Key.isDarkMode)
        ud.set(m.accentColorID, forKey: Key.accentColorID)
        ud.set(m.enableHaptics, forKey: Key.enableHaptics)
        ud.set(m.autoCarryTasks, forKey: Key.autoCarryTasks)
        ud.set(m.preferredLanguage, forKey: Key.preferredLanguage)
    }

    private func readUserDefaults() -> SettingsModel? {
        // If nothing has been stored before, return nil to allow defaults.
        guard ud.object(forKey: Key.isDarkMode) != nil ||
                ud.object(forKey: Key.accentColorID) != nil ||
                ud.object(forKey: Key.enableHaptics) != nil ||
                ud.object(forKey: Key.autoCarryTasks) != nil ||
                ud.object(forKey: Key.preferredLanguage) != nil
        else { return nil }

        let isDarkMode = ud.bool(forKey: Key.isDarkMode)
        let accentID = ud.string(forKey: Key.accentColorID) ?? "brandBlue"
        let enableHaptics = ud.object(forKey: Key.enableHaptics) as? Bool ?? true
        let autoCarry = ud.object(forKey: Key.autoCarryTasks) as? Bool ?? true
        let lang = ud.string(forKey: Key.preferredLanguage) ?? "en"

        return SettingsModel(
            isDarkMode: isDarkMode,
            accentColorID: accentID,
            enableHaptics: enableHaptics,
            autoCarryTasks: autoCarry,
            preferredLanguage: lang
        )
    }
}
