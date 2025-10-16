//
//  DayPlan.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Represents a daily plan consisting of a mood and a set of tasks.
struct DayPlan: Identifiable, Codable, Equatable {

    // MARK: - Properties

    let id: UUID
    var date: Date
    var selectedMood: Mood?
    var tasks: [TaskItem]

    // MARK: - Init

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        selectedMood: Mood? = nil,
        tasks: [TaskItem] = []
    ) {
        self.id = id
        self.date = date
        self.selectedMood = selectedMood
        self.tasks = tasks
    }

    // MARK: - Computed properties

    /// Returns the number of completed tasks.
    var completedCount: Int {
        tasks.filter { $0.isDone }.count
    }

    /// Returns true if all tasks are completed.
    var isAllDone: Bool {
        !tasks.isEmpty && tasks.allSatisfy { $0.isDone }
    }

    /// Returns a short formatted date label for UI.
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// Returns the completion percentage as a value between 0 and 1.
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }

    // MARK: - Mutating operations

    /// Adds a new task to the plan.
    mutating func addTask(_ task: TaskItem) {
        tasks.append(task)
    }

    /// Removes a task by its ID.
    mutating func removeTask(id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    /// Updates a task with new values.
    mutating func updateTask(_ updated: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == updated.id }) {
            tasks[index] = updated
        }
    }

    /// Toggles completion for a specific task.
    mutating func toggleTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isDone.toggle()
    }
}
