//
//  AppTheme.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Global theme manager controlling colors, typography, and appearance mode.
@MainActor
final class AppTheme: ObservableObject {

    // MARK: - Published state

    /// True when dark mode is active.
    @Published var isDarkMode: Bool = false {
        didSet { updateAppearance() }
    }

    /// Accent color used for highlights and primary elements.
    @Published var accentColor: Color = ColorPalette.brandBlue

    /// Background color based on current theme mode.
    @Published private(set) var background: Color = ColorPalette.surfaceLight

    /// Text color for standard content.
    @Published private(set) var textPrimary: Color = ColorPalette.textDark

    /// Secondary text color for hints and details.
    @Published private(set) var textSecondary: Color = ColorPalette.textGray

    // MARK: - Private

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        updateAppearance()
    }

    // MARK: - Public API

    /// Toggles between dark and light themes.
    func toggleMode() {
        isDarkMode.toggle()
    }

    /// Applies a specific accent color.
    func applyAccent(_ color: Color) {
        accentColor = color
    }

    // MARK: - Internal logic

    private func updateAppearance() {
        if isDarkMode {
            background = ColorPalette.surfaceDark
            textPrimary = ColorPalette.textLight
            textSecondary = ColorPalette.textGrayLight
        } else {
            background = ColorPalette.surfaceLight
            textPrimary = ColorPalette.textDark
            textSecondary = ColorPalette.textGray
        }
    }
}
