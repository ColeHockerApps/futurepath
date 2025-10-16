//
//  DateExtensions.swift
//  futurepath
//
//  Created on 2025-10-15
//

import Foundation
import Combine

/// Utility extensions for date formatting, ranges, and common calendar operations.
extension Date {

    private static let calendar = Calendar.current

    // MARK: - Components

    /// Returns the start of the day for this date (midnight).
    var startOfDay: Date {
        Date.calendar.startOfDay(for: self)
    }

    /// Returns the end of the day (23:59:59).
    var endOfDay: Date {
        guard let next = Date.calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return self }
        return next.addingTimeInterval(-1)
    }

    /// Returns the day component (1–31).
    var dayNumber: Int {
        Date.calendar.component(.day, from: self)
    }

    /// Returns the weekday index (1 = Sunday, 7 = Saturday).
    var weekday: Int {
        Date.calendar.component(.weekday, from: self)
    }

    /// Returns true if this date is today.
    var isToday: Bool {
        Date.calendar.isDateInToday(self)
    }

    /// Returns true if this date is yesterday.
    var isYesterday: Bool {
        Date.calendar.isDateInYesterday(self)
    }

    /// Returns true if this date is tomorrow.
    var isTomorrow: Bool {
        Date.calendar.isDateInTomorrow(self)
    }

    // MARK: - Formatting

    /// Returns formatted short date string (e.g., "Oct 15").
    func shortLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: self)
    }

    /// Returns formatted long label (e.g., "Tuesday, Oct 15").
    func longLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: self)
    }

    /// Returns formatted with time (e.g., "Oct 15, 3:45 PM").
    func fullDateTimeLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: self)
    }

    // MARK: - Math

    /// Returns number of full days between self and another date (absolute value).
    func daysSince(_ date: Date) -> Int {
        abs(Date.calendar.dateComponents([.day], from: date.startOfDay, to: self.startOfDay).day ?? 0)
    }

    /// Returns true if this date is within the same day as another.
    func isSameDay(as other: Date) -> Bool {
        Date.calendar.isDate(self, inSameDayAs: other)
    }

    /// Returns a new date offset by given days.
    func adding(days: Int) -> Date {
        Date.calendar.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Returns a new date offset by given weeks.
    func adding(weeks: Int) -> Date {
        Date.calendar.date(byAdding: .day, value: weeks * 7, to: self) ?? self
    }

    /// Returns true if date lies between two dates inclusively.
    func isBetween(_ start: Date, _ end: Date) -> Bool {
        self >= start && self <= end
    }

    // MARK: - Range utilities

    /// Returns the full week range (Monday–Sunday) containing this date.
    func weekBounds() -> (start: Date, end: Date) {
        var cal = Date.calendar
        cal.firstWeekday = 2 // Monday
        let weekday = cal.component(.weekday, from: self)
        let diffToMonday = ((weekday + 5) % 7)
        let start = cal.date(byAdding: .day, value: -diffToMonday, to: startOfDay) ?? startOfDay
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
        return (start, end)
    }

    /// Returns the full month range (1st–last day) containing this date.
    func monthBounds() -> (start: Date, end: Date) {
        var comp = Date.calendar.dateComponents([.year, .month], from: self)
        comp.day = 1
        let start = Date.calendar.date(from: comp) ?? self.startOfDay
        let lastDay = Date.calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let end = Date.calendar.date(byAdding: .day, value: lastDay - 1, to: start) ?? start
        return (start, end)
    }

    // MARK: - Relative description

    /// Returns human-readable relative label ("Today", "Yesterday", "Tomorrow", etc.).
    func relativeDayLabel(reference: Date = Date()) -> String {
        let cal = Date.calendar
        if cal.isDateInToday(self) { return "Today" }
        if cal.isDateInYesterday(self) { return "Yesterday" }
        if cal.isDateInTomorrow(self) { return "Tomorrow" }

        let diff = cal.dateComponents([.day], from: reference.startOfDay, to: self.startOfDay).day ?? 0
        if diff < 0 {
            return "\(abs(diff)) day\(abs(diff) == 1 ? "" : "s") ago"
        } else {
            return "in \(diff) day\(diff == 1 ? "" : "s")"
        }
    }
}

#if DEBUG
struct DateExtensions_Previews {
    static func test() {
        let today = Date()
        print("Today:", today.longLabel())
        print("Week bounds:", today.weekBounds())
        print("Month bounds:", today.monthBounds())
        print("Relative yesterday:", today.adding(days: -1).relativeDayLabel())
        print("Relative +3 days:", today.adding(days: 3).relativeDayLabel())
    }
}
#endif
