//
//  Typography.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Centralized typography styles for consistent text usage across the app.
enum Typography {

    // MARK: - Headings

    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title      = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let subtitle   = Font.system(size: 20, weight: .medium, design: .rounded)

    // MARK: - Body text

    static let body       = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 17, weight: .medium, design: .rounded)
    static let bodyBold   = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Smaller variant of body text (used in compact UI like ToastView or chips).
    static let bodySmall  = Font.system(size: 15, weight: .regular, design: .rounded)

    // MARK: - Small text

    static let caption    = Font.system(size: 13, weight: .regular, design: .rounded)
    static let footnote   = Font.system(size: 11, weight: .medium, design: .rounded)

    // MARK: - Utility

    /// Applies line spacing and text alignment modifiers for long-form text blocks.
    static func styled(_ font: Font) -> some ViewModifier {
        return CustomTextModifier(font: font)
    }

    private struct CustomTextModifier: ViewModifier {
        let font: Font

        func body(content: Content) -> some View {
            content
                .font(font)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
    }
}
