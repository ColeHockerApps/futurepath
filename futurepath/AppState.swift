//
//  AppState.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine
import UIKit

/// Global application state shared across the app.

final class AppState: ObservableObject {

    /// Available tabs in the root TabBar.
    enum AppTab: String, CaseIterable, Identifiable {
        case today
        case focus
        case journal
        case stats
        case settings

        var id: String { rawValue }

        /// System icon name for the tab.
        var systemIcon: String {
            switch self {
            case .today:    return "sun.max"
            case .focus:    return "timer"
            case .journal:  return "book.closed"
            case .stats:    return "chart.bar"
            case .settings: return "gearshape"
            }
        }

        /// Localized (English) title for the tab.
        var title: String {
            switch self {
            case .today:    return "Today"
            case .focus:    return "Focus"
            case .journal:  return "Journal"
            case .stats:    return "Stats"
            case .settings: return "Settings"
            }
        }
    }

    // MARK: - Published state

    /// Currently selected tab in the TabBar.
    @Published var selectedTab: AppTab = .today

    /// The current day (at device calendar startOfDay).
    @Published private(set) var currentDay: Date = Calendar.current.startOfDay(for: Date())

    // MARK: - Private

    private var bag = Set<AnyCancellable>()
    private let calendar = Calendar.current

    // MARK: - Init

    init() {
        observeDayBoundary()
    }

    // MARK: - Public API

    /// Selects a tab programmatically.
    func select(_ tab: AppTab) {
        selectedTab = tab
    }

    /// Returns `true` if the provided date is the same logical day as `currentDay`.
    func isSameDay(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: currentDay)
    }

    /// Forces refresh of the `currentDay` based on device time.
    func refreshCurrentDay() {
        let start = calendar.startOfDay(for: Date())
        if start != currentDay {
            currentDay = start
        }
    }

    // MARK: - Day boundary observer

    /// Observes time changes and updates `currentDay` when a new day starts.
    private func observeDayBoundary() {
        // A minute-level tick is enough to catch day boundary without battery impact.
        Timer
            .publish(every: 60, on: .current, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshCurrentDay()
            }
            .store(in: &bag)

        // Also react to significant time/clock changes.
        NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshCurrentDay()
            }
            .store(in: &bag)
    }
}
