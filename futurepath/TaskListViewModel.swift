//
//  TaskListViewModel.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// ViewModel for listing, filtering, and editing tasks for a given day.
@MainActor
final class TaskListViewModel: ObservableObject {

    // MARK: - Dependencies

    private let appState: AppState
    private let tasksRepo: TaskRepository
    private let taskEngine: TaskEngine

    // MARK: - Published

    /// Working date (tracks AppState.currentDay).
    @Published private(set) var date: Date

    /// Optional mood filter. `nil` means "All".
    @Published var moodFilter: Mood? = nil {
        didSet { recompute() }
    }

    /// Search query to filter tasks by title/note.
    @Published var searchText: String = "" {
        didSet { recompute() }
    }

    /// Tasks due on the current day, after filters.
    @Published private(set) var items: [TaskItem] = []

    /// Overdue tasks relative to the current date (not done, due < today).
    @Published private(set) var overdue: [TaskItem] = []

    /// Undated tasks (no dueDate), after filters.
    @Published private(set) var undated: [TaskItem] = []

    // MARK: - Private

    private var bag = Set<AnyCancellable>()
    private let calendar = Calendar.current

    // MARK: - Init

    init(
        appState: AppState,
        tasksRepository: TaskRepository,
        taskEngine: TaskEngine
    ) {
        self.appState = appState
        self.tasksRepo = tasksRepository
        self.taskEngine = taskEngine
        self.date = appState.currentDay

        bind()
        refreshAll()
    }

    // MARK: - Binding

    private func bind() {
        // ✅ Observe the @Published directly
        appState.$currentDay
            .removeDuplicates()
            .sink { [weak self] newDay in
                guard let self else { return }
                self.date = newDay
                self.refreshAll()
            }
            .store(in: &bag)

        tasksRepo.$tasks
            .sink { [weak self] _ in
                self?.recompute()
            }
            .store(in: &bag)
    }

    // MARK: - Public API

    /// Refreshes all sections for the current day.
    func refreshAll() {
        recompute()
    }

    /// Creates and stores a new task. Returns the created task.
    @discardableResult
    func addTask(
        title: String,
        note: String? = nil,
        moodHint: Mood? = nil,
        dueDate: Date? = nil,
        colorID: String = "brandBlue",
        iconName: String = IconLibrary.idea
    ) -> TaskItem {
        let normalizedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)

        let targetDate = dueDate ?? calendar.startOfDay(for: date)

        let item = TaskItem(
            title: normalizedTitle.isEmpty ? "New Task" : normalizedTitle,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            moodHint: moodHint,
            dueDate: targetDate,
            isDone: false,
            colorID: colorID,
            iconName: iconName
        )
        tasksRepo.add(item)
        return item
    }

    /// Updates an existing task.
    func updateTask(_ task: TaskItem) {
        tasksRepo.update(task)
    }

    /// Toggles completion state for a task by ID.
    func toggleDone(_ id: UUID) {
        tasksRepo.toggle(id)
    }

    /// Deletes a task by ID.
    func delete(_ id: UUID) {
        tasksRepo.delete(id)
    }

    /// Moves a task to a specific day (startOfDay).
    func moveToDay(_ id: UUID, day: Date) {
        _ = taskEngine.moveTask(id, to: day, in: tasksRepo)
    }

    /// Clears the due date of a task (makes it undated).
    func clearDueDate(_ id: UUID) {
        _ = taskEngine.clearDueDate(id, in: tasksRepo)
    }

    /// Changes accent color of a task by ID.
    func setColor(_ id: UUID, colorID: String) {
        guard var item = tasksRepo.tasks.first(where: { $0.id == id }) else { return }
        item.colorID = colorID
        tasksRepo.update(item)
    }

    /// Changes icon of a task by ID.
    func setIcon(_ id: UUID, iconName: String) {
        guard var item = tasksRepo.tasks.first(where: { $0.id == id }) else { return }
        item.iconName = iconName
        tasksRepo.update(item)
    }

    // MARK: - Internal

    private func recompute() {
        // Base sets
        let dayItems = taskEngine.tasks(for: date, from: tasksRepo)
        let overdueItems = tasksRepo.overdue(reference: date)
        let undatedItems = tasksRepo.query(dueFrom: nil, dueTo: nil).filter { $0.dueDate == nil }

        // Apply mood filter
        let applyMood: (TaskItem) -> Bool = { [weak self] t in
            guard let filter = self?.moodFilter else { return true }
            return t.moodHint == nil || t.moodHint == filter
        }

        // Apply search filter
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let applySearch: (TaskItem) -> Bool = { t in
            guard !query.isEmpty else { return true }
            if t.title.lowercased().contains(query) { return true }
            if let note = t.note?.lowercased(), note.contains(query) { return true }
            return false
        }

        // Compose filters and sort
        items = dayItems
            .filter { applyMood($0) && applySearch($0) }
            .sorted(by: sortRule)

        overdue = overdueItems
            .filter { applyMood($0) && applySearch($0) }
            .sorted(by: sortRule)

        undated = undatedItems
            .filter { applyMood($0) && applySearch($0) }
            .sorted(by: sortRule)
    }

    private func sortRule(_ a: TaskItem, _ b: TaskItem) -> Bool {
        // Not-done first
        if a.isDone != b.isDone { return !a.isDone && b.isDone }

        // Due date ascending (nil last)
        switch (a.dueDate, b.dueDate) {
        case let (da?, db?):
            if da != db { return da < db }
        case (nil, .some):
            return false
        case (.some, nil):
            return true
        default:
            break
        }

        // Creation time ascending
        if a.createdAt != b.createdAt { return a.createdAt < b.createdAt }

        // Title tiebreaker
        return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
    }
}
