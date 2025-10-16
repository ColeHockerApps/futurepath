//
//  IconLibrary.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Centralized icon definitions and mappings used across the app.
enum IconLibrary {

    // MARK: - Mood icons
    static let calm       = "cloud.sun"
    static let focused    = "target"
    static let tired      = "zzz"
    static let inspired   = "sparkles"
    static let anxious    = "waveform.path.ecg"

    // MARK: - Task icons
    static let work       = "briefcase.fill"
    static let study      = "book.fill"
    static let sport      = "figure.run"
    static let health     = "heart.fill"
    static let relax      = "leaf.fill"
    static let travel     = "airplane"
    static let social     = "person.2.fill"
    static let idea       = "lightbulb.fill"
    static let finance    = "banknote.fill"
    static let home       = "house.fill"

    // MARK: - General interface
    static let add        = "plus.circle.fill"
    static let edit       = "pencil.circle.fill"
    static let delete     = "trash.circle.fill"
    static let done       = "checkmark.circle.fill"
    static let cancel     = "xmark.circle.fill"
    static let stats      = "chart.bar"
    static let settings   = "gearshape"
    static let today      = "sun.max"
    static let back       = "chevron.left"

    // MARK: - Utility API

    /// Returns an icon suitable for a given mood.
    static func icon(for mood: String) -> String {
        switch mood.lowercased() {
        case "calm":      return calm
        case "focused":   return focused
        case "tired":     return tired
        case "inspired":  return inspired
        case "anxious":   return anxious
        default:          return "circle"
        }
    }

    /// Returns an icon suitable for a task category.
    static func icon(forCategory category: String) -> String {
        switch category.lowercased() {
        case "work":      return work
        case "study":     return study
        case "sport":     return sport
        case "health":    return health
        case "relax":     return relax
        case "travel":    return travel
        case "social":    return social
        case "idea":      return idea
        case "finance":   return finance
        case "home":      return home
        default:          return "circle"
        }
    }
}
