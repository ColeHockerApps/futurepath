//
//  MoodRepository.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Handles persistence and retrieval of daily mood plans.
@MainActor
final class MoodRepository: ObservableObject {

    // MARK: - Published State

    @Published private(set) var plans: [DayPlan] = []

    // MARK: - Private

    private let store = FileStore.shared
    private let fileName = "moodplans.json"
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - Public API

    /// Loads all saved day plans from file.
    func load() {
        if let loaded: [DayPlan] = store.load([DayPlan].self, from: fileName) {
            plans = loaded
        } else {
            plans = []
        }
    }

    /// Saves current plans to file.
    func save() {
        store.save(plans, as: fileName)
    }

    /// Returns the plan for a given date or creates a new one.
    func plan(for date: Date) -> DayPlan {
        if let existing = plans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return existing
        } else {
            let new = DayPlan(date: Calendar.current.startOfDay(for: date))
            plans.append(new)
            save()
            return new
        }
    }

    /// Updates a plan (add, replace, or modify).
    func update(_ updated: DayPlan) {
        if let index = plans.firstIndex(where: { $0.id == updated.id }) {
            plans[index] = updated
        } else {
            plans.append(updated)
        }
        save()
    }

    /// Removes plans older than the specified number of days.
    func prune(olderThan days: Int) {
        let threshold = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        plans.removeAll { $0.date < threshold }
        save()
    }

    /// Assigns a new mood for the specified date.
    func setMood(_ mood: Mood, for date: Date) {
        var plan = plan(for: date)
        plan.selectedMood = mood
        update(plan)
    }

    /// Returns the mood for a specific date, if set.
    func mood(for date: Date) -> Mood? {
        plan(for: date).selectedMood
    }

    /// Adds a task to a specific day's plan.
    func addTask(_ task: TaskItem, for date: Date) {
        var plan = plan(for: date)
        plan.addTask(task)
        update(plan)
    }

    /// Updates a task inside a day's plan.
    func updateTask(_ task: TaskItem, for date: Date) {
        var plan = plan(for: date)
        plan.updateTask(task)
        update(plan)
    }

    /// Toggles completion for a specific task by ID.
    func toggleTask(id: UUID, for date: Date) {
        var plan = plan(for: date)
        plan.toggleTask(id: id)
        update(plan)
    }

    /// Deletes a task from the day's plan.
    func deleteTask(id: UUID, for date: Date) {
        var plan = plan(for: date)
        plan.removeTask(id: id)
        update(plan)
    }

    /// Returns the list of all moods used within a given period.
    func moodsBetween(start: Date, end: Date) -> [Mood] {
        plans
            .filter { $0.date >= start && $0.date <= end }
            .compactMap { $0.selectedMood }
    }

    /// Clears all stored data (used for reset in Settings).
    func clearAll() {
        plans.removeAll()
        store.delete(fileName)
    }
}
