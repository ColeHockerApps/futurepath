//
//  MoodPickerViewModel.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// ViewModel for selecting today's mood and getting mood-based recommendations.
@MainActor
final class MoodPickerViewModel: ObservableObject {

    // MARK: - Dependencies

    private let appState: AppState
    private let moodRepo: MoodRepository
    private let taskRepo: TaskRepository
    private let moodEngine: MoodEngine
    private let taskEngine: TaskEngine
    private let settings: SettingsStore

    // MARK: - Published

    /// Current working date (tracks AppState.currentDay).
    @Published private(set) var date: Date

    /// Selected mood for the current day.
    @Published private(set) var selectedMood: Mood?

    /// Top recommendations for the selected mood.
    @Published private(set) var recommendations: [TaskItem] = []

    /// A tiny set of quick wins to build momentum.
    @Published private(set) var quickWins: [TaskItem] = []

    // MARK: - Private

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        appState: AppState,
        moodRepository: MoodRepository,
        taskRepository: TaskRepository,
        moodEngine: MoodEngine,
        taskEngine: TaskEngine,
        settings: SettingsStore
    ) {
        self.appState = appState
        self.moodRepo = moodRepository
        self.taskRepo = taskRepository
        self.moodEngine = moodEngine
        self.taskEngine = taskEngine
        self.settings = settings
        self.date = appState.currentDay
        self.selectedMood = moodRepository.mood(for: appState.currentDay)

        bind()
        refreshAll()
    }

    // MARK: - Binding

    private func bind() {
        // (You can keep or remove this; it's a no-op placeholder.)
        appState.$selectedTab
            .sink { [weak self] _ in
                guard self != nil else { return }
            }
            .store(in: &bag)

        // ✅ Observe the @Published directly
        appState.$currentDay
            .removeDuplicates()
            .sink { [weak self] newDay in
                guard let self else { return }
                self.date = newDay
                self.refreshAll()
            }
            .store(in: &bag)

        settings.$model
            .sink { [weak self] _ in
                self?.recomputeRecommendations()
            }
            .store(in: &bag)
    }

    // MARK: - Public API

    /// Sets the mood for the current day and updates recommendations.
    func setMood(_ mood: Mood) {
        moodRepo.setMood(mood, for: date)
        selectedMood = moodRepo.mood(for: date)
        recomputeRecommendations()
    }

    /// Forces a full refresh for the current day (carry overdue tasks if enabled, then recompute).
    func refreshAll() {
        // Optionally carry overdue tasks to today based on Settings.
        _ = taskEngine.applyAutoCarryIfNeeded(settings: settings, tasks: taskRepo, reference: date)

        // Ensure we have a plan for the day and sync selected mood.
        let plan = moodRepo.plan(for: date)
        selectedMood = plan.selectedMood

        recomputeRecommendations()
    }

    /// Returns the current day's plan (always exists after init/refresh).
    func currentPlan() -> DayPlan {
        moodRepo.plan(for: date)
    }

    // MARK: - Internal

    private func recomputeRecommendations() {
        guard let mood = selectedMood else {
            recommendations = []
            quickWins = []
            return
        }

        // Build recommendations based on global task list filtered by not-done.
        let top = moodEngine.recommend(from: taskRepo, for: mood, date: date, limit: 7)
        recommendations = top

        // Quick wins for momentum.
        quickWins = moodEngine.quickWins(from: top, for: mood, limit: 3, reference: date)
    }
}
