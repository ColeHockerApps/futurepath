//
//  SettingsViewModel.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// ViewModel bridging SettingsStore with UI controls and AppTheme.

final class SettingsViewModel: ObservableObject {

    // MARK: - Dependencies

    private let settings: SettingsStore
    private let theme: AppTheme

    // MARK: - Published (UI bindings)

    @Published var isDarkMode: Bool
    @Published var accentColorID: String
    @Published var enableHaptics: Bool
    @Published var autoCarryTasks: Bool
    @Published var languageCode: String

    /// Available accent IDs for UI pickers.
    let accentOptions: [String] = [
        "brandBlue", "brandGreen", "brandYellow", "brandCoral", "brandPurple"
    ]

    // MARK: - Private

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(settings: SettingsStore, theme: AppTheme) {
        self.settings = settings
        self.theme = theme

        // Seed from store
        let m = settings.model
        self.isDarkMode = m.isDarkMode
        self.accentColorID = m.accentColorID
        self.enableHaptics = m.enableHaptics
        self.autoCarryTasks = m.autoCarryTasks
        self.languageCode = m.preferredLanguage

        bind()
        applyThemeSideEffects()
    }

    // MARK: - Binding

    private func bind() {
        // Keep VM in sync if SettingsStore changes (e.g., external reset).
        settings.$model
            .sink { [weak self] m in
                guard let self else { return }
                if self.isDarkMode != m.isDarkMode { self.isDarkMode = m.isDarkMode }
                if self.accentColorID != m.accentColorID { self.accentColorID = m.accentColorID }
                if self.enableHaptics != m.enableHaptics { self.enableHaptics = m.enableHaptics }
                if self.autoCarryTasks != m.autoCarryTasks { self.autoCarryTasks = m.autoCarryTasks }
                if self.languageCode != m.preferredLanguage { self.languageCode = m.preferredLanguage }
                self.applyThemeSideEffects()
            }
            .store(in: &bag)
    }

    // MARK: - Public API (mutations triggered by UI)

    func toggleDarkMode() {
        isDarkMode.toggle()
        settings.setDarkMode(isDarkMode)
        applyThemeSideEffects()
    }

    func setDarkMode(_ on: Bool) {
        guard isDarkMode != on else { return }
        isDarkMode = on
        settings.setDarkMode(on)
        applyThemeSideEffects()
    }

    func setAccent(id: String) {
        guard accentOptions.contains(id), accentColorID != id else { return }
        accentColorID = id
        settings.setAccentColorID(id)
        applyThemeSideEffects()
    }

    func setHapticsEnabled(_ on: Bool) {
        guard enableHaptics != on else { return }
        enableHaptics = on
        settings.setHapticsEnabled(on)
    }

    func setAutoCarry(_ on: Bool) {
        guard autoCarryTasks != on else { return }
        autoCarryTasks = on
        settings.setAutoCarryTasks(on)
    }

    func setLanguage(_ code: String) {
        let normalized = code.lowercased()
        guard languageCode != normalized else { return }
        languageCode = normalized
        settings.setLanguage(normalized)
    }

    func resetToDefaults() {
        settings.resetToDefaults()
        // settings.$model sink will propagate new values and call theme apply
    }

    // MARK: - Helpers

    private func applyThemeSideEffects() {
        // Sync theme mode
        if theme.isDarkMode != isDarkMode {
            theme.isDarkMode = isDarkMode
        }
        // Sync accent color
        let color = colorForAccentID(accentColorID)
        if theme.accentColor != color {
            theme.applyAccent(color)
        }
    }

    private func colorForAccentID(_ id: String) -> Color {
        switch id {
        case "brandBlue":   return ColorPalette.brandBlue
        case "brandGreen":  return ColorPalette.brandGreen
        case "brandYellow": return ColorPalette.brandYellow
        case "brandCoral":  return ColorPalette.brandCoral
        case "brandPurple": return ColorPalette.brandPurple
        default:            return ColorPalette.brandBlue
        }
    }
}
