//
//  StatsViewModel.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// ViewModel providing aggregated analytics for the Stats screen.

final class StatsViewModel: ObservableObject {

    // MARK: - Dependencies

    private let appState: AppState
    private let moodRepo: MoodRepository
    private let taskRepo: TaskRepository
    private let engine: StatsEngine

    // MARK: - Published

    /// Start date (inclusive) for the current analytics range (startOfDay).
    @Published private(set) var start: Date

    /// End date (inclusive) for the current analytics range (startOfDay).
    @Published private(set) var end: Date

    /// Mood distribution shares for the current range.
    @Published private(set) var moodShares: [StatsEngine.MoodShare] = []

    /// Per-day summaries (mood + totals) for the current range.
    @Published private(set) var daily: [StatsEngine.DaySummary] = []

    /// Overall completion rate (0...1) for tasks in range.
    @Published private(set) var completionRate: Double = 0

    /// Longest streak of days with ≥1 completed task within range.
    @Published private(set) var longestStreak: Int = 0

    /// Average created and done tasks per day in range.
    @Published private(set) var avgCreatedPerDay: Double = 0
    @Published private(set) var avgDonePerDay: Double = 0

    /// Distribution of completed tasks by weekday index (Calendar.current .weekday).
    @Published private(set) var weekdayHistogram: [Int: Int] = [:]

    // MARK: - Private

    private var bag = Set<AnyCancellable>()
    private let calendar = Calendar.current

    // MARK: - Init

    init(
        appState: AppState,
        moodRepository: MoodRepository,
        taskRepository: TaskRepository,
        statsEngine: StatsEngine
    ) {
        self.appState = appState
        self.moodRepo = moodRepository
        self.taskRepo = taskRepository
        self.engine = statsEngine

        // Default range: current week (Mon...Sun) containing currentDay
        let today = calendar.startOfDay(for: appState.currentDay)
        let week = Self.weekBounds(for: today, calendar: calendar)
        self.start = week.start
        self.end = week.end

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
                if Self.contains(date: start, end: end, date: calendar.startOfDay(for: newDay)),
                   Self.isOneWeekRange(start: start, end: end, calendar: calendar) {
                    let wb = Self.weekBounds(for: newDay, calendar: calendar)
                    self.start = wb.start
                    self.end = wb.end
                }
                self.refreshAll()
            }
            .store(in: &bag)

        moodRepo.$plans
            .sink { [weak self] _ in self?.refreshAll() }
            .store(in: &bag)

        taskRepo.$tasks
            .sink { [weak self] _ in self?.refreshAll() }
            .store(in: &bag)
    }

    // MARK: - Public API

    /// Sets the range to the week (Mon..Sun) containing provided date.
    func setWeek(of date: Date) {
        let wb = Self.weekBounds(for: date, calendar: calendar)
        start = wb.start
        end = wb.end
        refreshAll()
    }

    /// Sets the range to the calendar month containing provided date.
    func setMonth(of date: Date) {
        let d = calendar.startOfDay(for: date)
        let comp = calendar.dateComponents([.year, .month], from: d)
        guard
            let first = calendar.date(from: DateComponents(year: comp.year, month: comp.month, day: 1)),
            let lastDay = calendar.range(of: .day, in: .month, for: first)?.count,
            let last = calendar.date(from: DateComponents(year: comp.year, month: comp.month, day: lastDay))
        else { return }
        start = first
        end = last
        refreshAll()
    }

    /// Sets a custom inclusive range (dates will be normalized to startOfDay).
    func setRange(start s: Date, end e: Date) {
        start = calendar.startOfDay(for: s)
        end = calendar.startOfDay(for: e)
        refreshAll()
    }

    /// Moves the current range backward by the same span.
    func previousSpan() {
        let days = Self.daysBetween(start, end, calendar: calendar) + 1
        start = calendar.date(byAdding: .day, value: -days, to: start) ?? start
        end = calendar.date(byAdding: .day, value: -days, to: end) ?? end
        refreshAll()
    }

    /// Moves the current range forward by the same span.
    func nextSpan() {
        let days = Self.daysBetween(start, end, calendar: calendar) + 1
        start = calendar.date(byAdding: .day, value: days, to: start) ?? start
        end = calendar.date(byAdding: .day, value: days, to: end) ?? end
        refreshAll()
    }

    // MARK: - Internal

    private func refreshAll() {
        // Normalize boundaries to startOfDay.
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)

        moodShares = engine.moodShare(from: moodRepo, start: s, end: e)
        daily = engine.dailySummary(from: moodRepo, tasksRepo: taskRepo, start: s, end: e)
        completionRate = engine.completionRate(from: taskRepo, start: s, end: e)
        longestStreak = engine.longestProductiveStreak(from: taskRepo, start: s, end: e)
        weekdayHistogram = engine.weekdayCompletion(from: taskRepo, start: s, end: e)
        avgCreatedPerDay = engine.averageCreatedPerDay(from: taskRepo, start: s, end: e)
        avgDonePerDay = engine.averageDonePerDay(from: taskRepo, start: s, end: e)
    }

    // MARK: - Helpers (static)

    private static func weekBounds(for date: Date, calendar: Calendar) -> (start: Date, end: Date) {
        let d = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: d)

        // Normalize Monday as first weekday for consistency in stats.
        var cal = calendar
        cal.firstWeekday = 2 // 1 = Sunday, 2 = Monday

        // Distance to Monday
        let distanceToMonday = ((weekday + 5) % 7) // 0 => Monday, 6 => Sunday
        let start = cal.date(byAdding: .day, value: -distanceToMonday, to: d) ?? d
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
        return (cal.startOfDay(for: start), cal.startOfDay(for: end))
    }

    private static func contains(date start: Date, end: Date, date: Date) -> Bool {
        let s = Calendar.current.startOfDay(for: start)
        let e = Calendar.current.startOfDay(for: end)
        let d = Calendar.current.startOfDay(for: date)
        return d >= s && d <= e
    }

    private static func isOneWeekRange(start: Date, end: Date, calendar: Calendar) -> Bool {
        daysBetween(start, end, calendar: calendar) + 1 == 7
    }

    private static func daysBetween(_ a: Date, _ b: Date, calendar: Calendar) -> Int {
        abs(calendar.dateComponents([.day], from: calendar.startOfDay(for: a), to: calendar.startOfDay(for: b)).day ?? 0)
    }
}
