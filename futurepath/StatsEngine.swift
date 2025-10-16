//
//  StatsEngine.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Aggregations for mood and task analytics. Pure computation layer.

final class StatsEngine {

    // MARK: - Types

    struct MoodShare: Equatable {
        let mood: Mood
        let count: Int
        let share: Double // 0...1
    }

    struct DaySummary: Equatable, Identifiable {
        let id: Date           // startOfDay
        let date: Date         // startOfDay
        let mood: Mood?
        let total: Int
        let done: Int
        let progress: Double   // 0...1

        init(date: Date, mood: Mood?, total: Int, done: Int) {
            let calendar = Calendar.current
            self.id = calendar.startOfDay(for: date)
            self.date = calendar.startOfDay(for: date)
            self.mood = mood
            self.total = total
            self.done = done
            self.progress = total == 0 ? 0 : Double(done) / Double(total)
        }
    }

    // MARK: - Private

    private let calendar = Calendar.current

    // MARK: - Public API

    /// Returns a dictionary of mood → count within [start, end].
    func moodHistogram(from repo: MoodRepository, start: Date, end: Date) -> [Mood: Int] {
        let plans = repo.plans.filter { $0.date >= startOfDay(start) && $0.date <= startOfDay(end) }
        var dict: [Mood: Int] = [:]
        for p in plans {
            if let m = p.selectedMood {
                dict[m, default: 0] += 1
            }
        }
        return dict
    }

    /// Returns normalized mood shares (each as 0...1) within the period.
    func moodShare(from repo: MoodRepository, start: Date, end: Date) -> [MoodShare] {
        let hist = moodHistogram(from: repo, start: start, end: end)
        let total = hist.values.reduce(0, +)
        guard total > 0 else {
            return Mood.allCases.map { MoodShare(mood: $0, count: 0, share: 0) }
        }
        return Mood.allCases.map { mood in
            let c = hist[mood] ?? 0
            return MoodShare(mood: mood, count: c, share: Double(c) / Double(total))
        }
    }

    /// Calculates overall completion rate for tasks that have dueDate in [start, end].
    /// If includeUndated is true, undated tasks are included in the denominator (only if done within range).
    func completionRate(
        from repo: TaskRepository,
        start: Date,
        end: Date,
        includeUndated: Bool = false
    ) -> Double {
        let start = startOfDay(start)
        let end = startOfDay(end).addingTimeInterval(24*60*60 - 1)

        var relevant: [TaskItem] = repo.tasks.filter { t in
            if let due = t.dueDate {
                return (due >= start && due <= end)
            } else {
                return includeUndated
            }
        }

        if !includeUndated {
            // nothing more to filter
        } else {
            // For undated, consider them relevant if created within range
            relevant = relevant.filter { t in
                if t.dueDate != nil { return true }
                return t.createdAt >= start && t.createdAt <= end
            }
        }

        guard !relevant.isEmpty else { return 0 }
        let doneCount = relevant.filter { $0.isDone }.count
        return Double(doneCount) / Double(relevant.count)
    }

    /// Builds a per-day summary (mood + total/done) for the range.
    func dailySummary(from moodRepo: MoodRepository, tasksRepo: TaskRepository, start: Date, end: Date) -> [DaySummary] {
        let start = startOfDay(start)
        let end = startOfDay(end)

        // Index tasks by day
        var tasksByDay: [Date: [TaskItem]] = [:]
        for t in tasksRepo.tasks {
            let key: Date
            if let due = t.dueDate {
                key = startOfDay(due)
            } else {
                key = startOfDay(t.createdAt) // undated grouped by creation day
            }
            if key < start || key > end { continue }
            tasksByDay[key, default: []].append(t)
        }

        // Index moods by day
        var moodByDay: [Date: Mood?] = [:]
        for p in moodRepo.plans {
            let d = startOfDay(p.date)
            guard d >= start && d <= end else { continue }
            moodByDay[d] = p.selectedMood
        }

        // Build continuous range
        var result: [DaySummary] = []
        var cursor = start
        while cursor <= end {
            let items = tasksByDay[cursor] ?? []
            let total = items.count
            let done = items.filter { $0.isDone }.count
            let mood = moodByDay[cursor] ?? nil
            result.append(DaySummary(date: cursor, mood: mood, total: total, done: done))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86400)
        }
        return result
    }

    /// Longest streak of days in the range where at least one task was completed.
    func longestProductiveStreak(from repo: TaskRepository, start: Date, end: Date) -> Int {
        let start = startOfDay(start)
        let end = startOfDay(end)

        // Map day -> any done task
        var doneByDay: Set<Date> = []
        for t in repo.tasks where t.isDone {
            let day = startOfDay(t.dueDate ?? t.createdAt)
            if day >= start && day <= end {
                doneByDay.insert(day)
            }
        }

        var streak = 0
        var best = 0
        var cursor = start
        while cursor <= end {
            if doneByDay.contains(cursor) {
                streak += 1
                best = max(best, streak)
            } else {
                streak = 0
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86400)
        }
        return best
    }

    /// Distribution by weekday (Mon..Sun) of completed tasks within the range.
    func weekdayCompletion(from repo: TaskRepository, start: Date, end: Date) -> [Int: Int] {
        // 1 = Sunday in some calendars; normalize to 1...7 using Calendar.current
        let start = startOfDay(start)
        let end = startOfDay(end).addingTimeInterval(24*60*60 - 1)

        var dict: [Int: Int] = [:] // weekday index -> count
        for t in repo.tasks where t.isDone {
            let ref = t.dueDate ?? t.createdAt
            guard ref >= start && ref <= end else { continue }
            let w = calendar.component(.weekday, from: ref)
            dict[w, default: 0] += 1
        }
        return dict
    }

    /// Average tasks created per day within the range.
    func averageCreatedPerDay(from repo: TaskRepository, start: Date, end: Date) -> Double {
        let days = max(1, daysBetween(start, end) + 1)
        let filtered = repo.tasks.filter { $0.createdAt >= start && $0.createdAt <= end }
        return Double(filtered.count) / Double(days)
    }

    /// Average tasks completed per day within the range.
    func averageDonePerDay(from repo: TaskRepository, start: Date, end: Date) -> Double {
        let days = max(1, daysBetween(start, end) + 1)
        let filtered = repo.tasks.filter { $0.isDone && ($0.dueDate ?? $0.createdAt) >= start && ($0.dueDate ?? $0.createdAt) <= end }
        return Double(filtered.count) / Double(days)
    }

    // MARK: - Helpers

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func daysBetween(_ a: Date, _ b: Date) -> Int {
        abs(calendar.dateComponents([.day], from: startOfDay(a), to: startOfDay(b)).day ?? 0)
    }
}
