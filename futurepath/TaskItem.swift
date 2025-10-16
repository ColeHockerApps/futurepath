//
//  TaskItem.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Represents a single task in the user's plan.
struct TaskItem: Identifiable, Codable, Equatable {

    // MARK: - Properties

    let id: UUID
    var title: String
    var note: String?
    var moodHint: Mood?
    var dueDate: Date?
    var isDone: Bool
    var colorID: String
    var iconName: String
    var createdAt: Date

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        moodHint: Mood? = nil,
        dueDate: Date? = nil,
        isDone: Bool = false,
        colorID: String = "brandBlue",
        iconName: String = "circle",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.moodHint = moodHint
        self.dueDate = dueDate
        self.isDone = isDone
        self.colorID = colorID
        self.iconName = iconName
        self.createdAt = createdAt
    }

    // MARK: - Helpers

    /// Returns the SwiftUI color for the assigned colorID.
    var color: Color {
        switch colorID {
        case "brandBlue":   return ColorPalette.brandBlue
        case "brandGreen":  return ColorPalette.brandGreen
        case "brandYellow": return ColorPalette.brandYellow
        case "brandCoral":  return ColorPalette.brandCoral
        case "brandPurple": return ColorPalette.brandPurple
        default:            return ColorPalette.neutralGray
        }
    }

    /// Returns the SF Symbol icon.
    var icon: String {
        iconName
    }

    /// Returns a formatted due date string or nil.
    var formattedDueDate: String? {
        guard let date = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Returns true if the task belongs to a given mood.
    func matches(mood: Mood?) -> Bool {
        guard let mood = moodHint else { return false }
        return mood == mood
    }

    /// Toggles completion state.
    mutating func toggleDone() {
        isDone.toggle()
    }
}
