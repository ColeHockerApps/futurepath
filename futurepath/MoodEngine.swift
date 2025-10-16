//
//  MoodEngine.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Heuristics for selecting and ordering tasks based on the current mood.
/// Pure business logic: no UI, no persistence side-effects.

final class MoodEngine {

    // MARK: - Private

    private let calendar = Calendar.current

    // Small weights to bias icons toward certain moods (optional bonus).
    // Keys are SF Symbol names used in IconLibrary.
    private let iconAffinity: [Mood: Set<String>] = [
        .calm:     [IconLibrary.relax, IconLibrary.home, IconLibrary.health],
        .focused:  [IconLibrary.work, IconLibrary.study, IconLibrary.finance],
        .tired:    [IconLibrary.home, IconLibrary.relax, IconLibrary.health],
        .inspired: [IconLibrary.idea, IconLibrary.study, IconLibrary.travel],
        .anxious:  [IconLibrary.health, IconLibrary.relax, IconLibrary.sport]
    ].mapValues { Set($0) }

    // MARK: - Public API

    /// Scores a task for a given mood and reference date.
    /// Higher score means higher priority for the user in this mood.
    func score(task: TaskItem, for mood: Mood, reference: Date = Date()) -> Int {
        var s = 0

        // 1) Completion state
        if task.isDone { return Int.min / 2 } // push completed to the end

        // 2) Mood affinity
        if let hint = task.moodHint, hint == mood {
            s += 50
        }

        // 3) Due date urgency
        if let due = task.dueDate {
            let startToday = calendar.startOfDay(for: reference)
            let startDue   = calendar.startOfDay(for: due)

            if startDue < startToday {
                // Overdue
                s += 40
            } else if startDue == startToday {
                // Due today
                s += 30
            } else {
                // Future due date: slight decay the further it is
                let days = calendar.dateComponents([.day], from: startToday, to: startDue).day ?? 0
                s += max(0, 20 - days) // up to +20 if soon
            }
        } else {
            // No due date: neutral but slightly lower than urgent items
            s += 5
        }

        // 4) Icon affinity (light, optional bias)
        if iconAffinity[mood]?.contains(task.iconName) == true {
            s += 8
        }

        // 5) Title length (micro bias: shorter = often quicker)
        let titleLen = task.title.trimmingCharacters(in: .whitespacesAndNewlines).count
        if titleLen <= 24 { s += 4 }

        // 6) Recent creation (fresh items feel more actionable)
        let daysSinceCreated = abs(calendar.dateComponents([.day], from: task.createdAt, to: reference).day ?? 0)
        if daysSinceCreated <= 2 { s += 3 }

        return s
    }

    /// Returns a task list ordered by priority for the given mood.
    func ordered(tasks: [TaskItem], for mood: Mood, reference: Date = Date()) -> [TaskItem] {
        tasks.sorted { a, b in
            let sa = score(task: a, for: mood, reference: reference)
            let sb = score(task: b, for: mood, reference: reference)
            if sa == sb {
                // Stable tiebreakers: dueDate earlier first, then createdAt earlier
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
            return sa > sb
        }
    }

    /// Picks top N recommendations from a list for a given mood.
    func top(tasks: [TaskItem], for mood: Mood, limit: Int = 7, reference: Date = Date()) -> [TaskItem] {
        let ordered = ordered(tasks: tasks, for: mood, reference: reference)
        return Array(ordered.prefix(max(0, limit)))
    }

    /// Pulls not-done tasks from a repository and returns top recommendations for today.
    func recommend(from repo: TaskRepository, for mood: Mood, date: Date = Date(), limit: Int = 7) -> [TaskItem] {
        let notDone = repo.query(isDone: false)
        return top(tasks: notDone, for: mood, limit: limit, reference: date)
    }

    /// Returns a small set of "quick wins" (short, non-overdue, mood-aligned) to build momentum.
    func quickWins(from tasks: [TaskItem], for mood: Mood, limit: Int = 3, reference: Date = Date()) -> [TaskItem] {
        let filtered = tasks.filter { t in
            guard !t.isDone else { return false }
            let titleLenOK = t.title.trimmingCharacters(in: .whitespacesAndNewlines).count <= 20
            let notOverdue: Bool = {
                guard let due = t.dueDate else { return true }
                return calendar.startOfDay(for: due) >= calendar.startOfDay(for: reference)
            }()
            let moodOK = (t.moodHint == nil) || (t.moodHint == mood)
            return titleLenOK && notOverdue && moodOK
        }
        return top(tasks: filtered, for: mood, limit: limit, reference: reference)
    }
}
