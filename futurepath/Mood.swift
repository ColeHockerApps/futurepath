//
//  Mood.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Represents the emotional state of a given day.
enum Mood: String, CaseIterable, Codable, Identifiable {
    case calm
    case focused
    case tired
    case inspired
    case anxious

    var id: String { rawValue }

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .calm:      return "Calm"
        case .focused:   return "Focused"
        case .tired:     return "Tired"
        case .inspired:  return "Inspired"
        case .anxious:   return "Anxious"
        }
    }

    /// Associated color for this mood.
    var color: Color {
        switch self {
        case .calm:      return ColorPalette.calmBlue
        case .focused:   return ColorPalette.focusYellow
        case .tired:     return ColorPalette.neutralGray
        case .inspired:  return ColorPalette.cozyPurple
        case .anxious:   return ColorPalette.energyOrange
        }
    }

    /// Icon name representing this mood.
    var icon: String {
        switch self {
        case .calm:      return IconLibrary.calm
        case .focused:   return IconLibrary.focused
        case .tired:     return IconLibrary.tired
        case .inspired:  return IconLibrary.inspired
        case .anxious:   return IconLibrary.anxious
        }
    }

    /// Optional gradient background for decorative elements.
    var gradient: LinearGradient {
        switch self {
        case .calm:
            return ColorPalette.calmGradient
        case .focused:
            return LinearGradient(
                colors: [ColorPalette.brandYellow.opacity(0.8), ColorPalette.brandBlue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .tired:
            return LinearGradient(
                colors: [ColorPalette.neutralGray.opacity(0.9), ColorPalette.textGray.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .inspired:
            return ColorPalette.warmGradient
        case .anxious:
            return LinearGradient(
                colors: [ColorPalette.brandCoral.opacity(0.9), ColorPalette.energyOrange.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
