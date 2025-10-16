//
//  TaskEngine.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Business logic for task operations: scheduling, carry-over, and utilities.
/// Pure logic layer: no UI code and no direct file I/O beyond repository calls.
final class TaskEngine {

    // MARK: - Private

    private let calendar = Calendar.current

    // MARK: - Public API

    /// If user enabled auto-carry in settings, shift all overdue (not done) tasks to today.
    /// - Returns: number of tasks moved.

    @discardableResult
    func applyAutoCarryIfNeeded(settings: SettingsStore, tasks: TaskRepository, reference: Date = Date()) -> Int {
        guard settings.autoCarryEnabled else { return 0 }
        return tasks.carryOverOverdue(to: reference)
    }

    /// Returns tasks whose dueDate falls on the given day (startOfDay..endOfDay).
    
    func tasks(for date: Date, from repo: TaskRepository) -> [TaskItem] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return repo.query(dueFrom: start, dueTo: end.addingTimeInterval(-1))
    }

    /// Moves a task to a specific date (preserves time at startOfDay).
    /// - Returns: `true` if updated successfully.

    @discardableResult
    func moveTask(_ id: UUID, to date: Date, in repo: TaskRepository) -> Bool {
        guard var item = repo.tasks.first(where: { $0.id == id }) else { return false }
        let start = calendar.startOfDay(for: date)
        item.dueDate = start
        repo.update(item)
        return true
    }

    /// Clears the due date (makes the task undated).
    /// - Returns: `true` if updated successfully.

    @discardableResult
    func clearDueDate(_ id: UUID, in repo: TaskRepository) -> Bool {
        guard var item = repo.tasks.first(where: { $0.id == id }) else { return false }
        item.dueDate = nil
        repo.update(item)
        return true
    }

    /// Bulk toggle completion for provided task IDs.

    func bulkSetDone(_ ids: [UUID], done: Bool, in repo: TaskRepository) {
        guard !ids.isEmpty else { return }
        for item in repo.tasks where ids.contains(item.id) && item.isDone != done {
            var updated = item
            updated.isDone = done
            repo.update(updated)
        }
    }

    /// Simple normalize: trims titles, collapses multiple spaces, caps length to a sane max.
    /// Returns number of tasks normalized.
 
    @discardableResult
    func normalizeTitles(in repo: TaskRepository, maxLength: Int = 120) -> Int {
        var updates = 0
        for item in repo.tasks {
            let original = item.title
            let trimmed = original
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            let capped = String(trimmed.prefix(maxLength))
            if capped != original {
                var updated = item
                updated.title = capped
                repo.update(updated)
                updates += 1
            }
        }
        return updates
    }

    /// Returns a dictionary grouping tasks by the day of their dueDate (nil bucket for undated).
 
    func groupByDay(from repo: TaskRepository, reference: Date = Date()) -> [Date?: [TaskItem]] {
        var result: [Date?: [TaskItem]] = [:]
        for t in repo.tasks {
            if let due = t.dueDate {
                let k = calendar.startOfDay(for: due)
                result[k, default: []].append(t)
            } else {
                result[nil, default: []].append(t)
            }
        }
        // Sort items within each bucket: not done first, then dueDate asc, then creation asc.
        for (k, arr) in result {
            result[k] = arr.sorted { a, b in
                if a.isDone != b.isDone { return !a.isDone && b.isDone }
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
                return a.createdAt < b.createdAt
            }
        }
        return result
    }

    /// Adjusts due dates to avoid past weekends by moving them to the next Monday.
    /// - Returns: number of tasks adjusted.
    
    @discardableResult
    func skipPastWeekends(in repo: TaskRepository, reference: Date = Date()) -> Int {
        var changed = 0
        for item in repo.tasks {
            guard let due = item.dueDate, due < reference, calendar.isDateInWeekend(due) else { continue }
            if let nextWorkday = nextWeekday(after: due) {
                var updated = item
                updated.dueDate = nextWorkday
                repo.update(updated)
                changed += 1
            }
        }
        return changed
    }

    // MARK: - Helpers

    private func nextWeekday(after date: Date) -> Date? {
        var comp = DateComponents()
        comp.day = 1
        var d = date
        for _ in 0..<7 {
            d = calendar.date(byAdding: comp, to: d) ?? d
            if !calendar.isDateInWeekend(d) {
                return calendar.startOfDay(for: d)
            }
        }
        return nil
    }
}
