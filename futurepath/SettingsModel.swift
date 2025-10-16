//
//  SettingsModel.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Represents user preferences and configuration options.
struct SettingsModel: Codable, Equatable {

    // MARK: - Properties

    var isDarkMode: Bool
    var accentColorID: String
    var enableHaptics: Bool
    var autoCarryTasks: Bool
    var preferredLanguage: String

    // MARK: - Init

    init(
        isDarkMode: Bool = false,
        accentColorID: String = "brandBlue",
        enableHaptics: Bool = true,
        autoCarryTasks: Bool = true,
        preferredLanguage: String = "en"
    ) {
        self.isDarkMode = isDarkMode
        self.accentColorID = accentColorID
        self.enableHaptics = enableHaptics
        self.autoCarryTasks = autoCarryTasks
        self.preferredLanguage = preferredLanguage
    }

    // MARK: - Helpers

    /// Returns the actual SwiftUI Color for the selected accent ID.
    var accentColor: Color {
        switch accentColorID {
        case "brandBlue":   return ColorPalette.brandBlue
        case "brandGreen":  return ColorPalette.brandGreen
        case "brandYellow": return ColorPalette.brandYellow
        case "brandCoral":  return ColorPalette.brandCoral
        case "brandPurple": return ColorPalette.brandPurple
        default:            return ColorPalette.brandBlue
        }
    }
}
