//
//  TaskRepository.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Standalone repository for task CRUD and querying.
/// Stores a flat list of tasks for global search, filters, and utilities.
/// Day-specific operations still live in `MoodRepository` via `DayPlan`.
@MainActor
final class TaskRepository: ObservableObject {

    // MARK: - Published State

    @Published private(set) var tasks: [TaskItem] = []

    // MARK: - Private

    private let store = FileStore.shared
    private let fileName = "tasks.json"
    private var bag = Set<AnyCancellable>()
    private let calendar = Calendar.current

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - Persistence

    func load() {
        if let loaded: [TaskItem] = store.load([TaskItem].self, from: fileName) {
            tasks = loaded
        } else {
            tasks = []
        }
    }

    func save() {
        store.save(tasks, as: fileName)
    }

    // MARK: - CRUD

    func add(_ task: TaskItem) {
        tasks.append(task)
        save()
    }

    func update(_ updated: TaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == updated.id }) {
            tasks[idx] = updated
            save()
        }
    }

    func toggle(_ id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].isDone.toggle()
        save()
    }

    func delete(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        tasks.removeAll()
        store.delete(fileName)
    }

    // MARK: - Queries

    /// Returns tasks filtered by optional mood, completion state, and a date range for dueDate.
    func query(
        mood: Mood? = nil,
        isDone: Bool? = nil,
        dueFrom: Date? = nil,
        dueTo: Date? = nil
    ) -> [TaskItem] {
        tasks.filter { t in
            let moodPass: Bool = {
                guard let mood = mood else { return true }
                return t.moodHint == mood
            }()

            let donePass: Bool = {
                guard let isDone = isDone else { return true }
                return t.isDone == isDone
            }()

            let datePass: Bool = {
                guard let due = t.dueDate else {
                    // If a due range is requested but item has no dueDate → exclude.
                    return (dueFrom == nil && dueTo == nil)
                }
                if let from = dueFrom, due < from { return false }
                if let to = dueTo,   due > to { return false }
                return true
            }()

            return moodPass && donePass && datePass
        }
    }

    /// Returns overdue tasks (not done and dueDate strictly before today's start).
    func overdue(reference: Date = Date()) -> [TaskItem] {
        let startOfToday = calendar.startOfDay(for: reference)
        return tasks.filter { t in
            guard let due = t.dueDate else { return false }
            return !t.isDone && due < startOfToday
        }
    }

    /// Simple case-insensitive substring search in title and note.
    func search(_ text: String) -> [TaskItem] {
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return tasks }
        return tasks.filter { t in
            if t.title.lowercased().contains(q) { return true }
            if let note = t.note?.lowercased(), note.contains(q) { return true }
            return false
        }
    }

    /// Groups tasks by `moodHint` for quick analytics.
    func groupedByMood() -> [(mood: Mood?, items: [TaskItem])] {
        let groups = Dictionary(grouping: tasks, by: { $0.moodHint })
        return groups.keys.sorted { a, b in
            (a?.rawValue ?? "") < (b?.rawValue ?? "")
        }.map { key in
            (mood: key, items: groups[key] ?? [])
        }
    }

    /// Carry forward all overdue (not done) tasks by shifting their dueDate to today.
    /// Returns the number of moved tasks.
    @discardableResult
    func carryOverOverdue(to reference: Date = Date()) -> Int {
        let startOfToday = calendar.startOfDay(for: reference)
        var moved = 0
        for i in tasks.indices {
            guard let due = tasks[i].dueDate, !tasks[i].isDone else { continue }
            if due < startOfToday {
                tasks[i].dueDate = startOfToday
                moved += 1
            }
        }
        if moved > 0 { save() }
        return moved
    }

    /// Bulk add helper.
    func addMany(_ items: [TaskItem]) {
        guard !items.isEmpty else { return }
        tasks.append(contentsOf: items)
        save()
    }
}
