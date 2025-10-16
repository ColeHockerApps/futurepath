//
//  ColorPalette.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Centralized color definitions for Future: Next Path.
enum ColorPalette {

    // MARK: - Core brand colors
    static let brandBlue     = Color(red: 30/255, green: 136/255, blue: 229/255) // #1E88E5
    static let brandGreen    = Color(red: 67/255, green: 160/255, blue: 71/255)  // #43A047
    static let brandYellow   = Color(red: 251/255, green: 192/255, blue: 45/255) // #FBC02D
    static let brandCoral    = Color(red: 239/255, green: 83/255, blue: 80/255)  // #EF5350
    static let brandPurple   = Color(red: 126/255, green: 87/255, blue: 194/255) // #7E57C2

    // MARK: - Surfaces
    static let surfaceLight  = Color(red: 250/255, green: 250/255, blue: 250/255) // light gray
    static let surfaceDark   = Color(red: 24/255,  green: 26/255,  blue: 31/255)  // deep gray-blue

    // MARK: - Text
    static let textDark      = Color(red: 28/255,  green: 28/255,  blue: 30/255)
    static let textLight     = Color(red: 245/255, green: 245/255, blue: 247/255)
    static let textGray      = Color(red: 120/255, green: 120/255, blue: 123/255)
    static let textGrayLight = Color(red: 160/255, green: 160/255, blue: 165/255)

    // MARK: - Mood backgrounds
    static let calmBlue      = Color(red: 173/255, green: 216/255, blue: 230/255)
    static let focusYellow   = Color(red: 255/255, green: 244/255, blue: 179/255)
    static let energyOrange  = Color(red: 255/255, green: 183/255, blue: 77/255)
    static let cozyPurple    = Color(red: 206/255, green: 147/255, blue: 216/255)
    static let neutralGray   = Color(red: 224/255, green: 224/255, blue: 224/255)

    // MARK: - Functional colors
    static let success       = Color(red: 76/255,  green: 175/255, blue: 80/255)
    static let warning       = Color(red: 255/255, green: 160/255, blue: 0/255)
    static let error         = Color(red: 211/255, green: 47/255,  blue: 47/255)

    // MARK: - Utility gradients
    static let blueGradient  = LinearGradient(
        colors: [brandBlue.opacity(0.9), brandPurple.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient  = LinearGradient(
        colors: [brandCoral.opacity(0.9), brandYellow.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let calmGradient  = LinearGradient(
        colors: [calmBlue.opacity(0.9), neutralGray.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
