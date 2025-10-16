//
//  FocusModel.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

// MARK: - FocusSession (Model)

/// Represents a single focus (Pomodoro-like) session.
struct FocusSession: Identifiable, Codable, Equatable {
    let id: UUID
    var mood: Mood?
    var taskTitle: String
    var startTime: Date?
    var duration: TimeInterval     // in seconds
    var endTime: Date? {
        startTime.map { $0.addingTimeInterval(duration) }
    }
    var isActive: Bool

    init(
        id: UUID = UUID(),
        mood: Mood? = nil,
        taskTitle: String = "",
        duration: TimeInterval = 1500, // 25 min
        startTime: Date? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.mood = mood
        self.taskTitle = taskTitle
        self.duration = duration
        self.startTime = startTime
        self.isActive = isActive
    }

    /// Returns remaining time in seconds if active.
    func remaining(at date: Date = Date()) -> TimeInterval {
        guard let startTime else { return duration }
        let elapsed = date.timeIntervalSince(startTime)
        return max(0, duration - elapsed)
    }

    /// Returns completion progress (0...1)
    func progress(at date: Date = Date()) -> Double {
        guard duration > 0 else { return 0 }
        return 1 - (remaining(at: date) / duration)
    }
}

// MARK: - FocusRepository (Persistence)

@MainActor
final class FocusRepository: ObservableObject {
    @Published private(set) var history: [FocusSession] = []

    private let store = FileStore.shared
    private let fileName = "focus_sessions.json"

    init() {
        load()
    }

    func load() {
        if let sessions: [FocusSession] = store.load([FocusSession].self, from: fileName) {
            history = sessions.sorted(by: { $0.startTime ?? .distantPast > $1.startTime ?? .distantPast })
        } else {
            history = []
        }
    }

    func save() {
        store.save(history, as: fileName)
    }

    func add(_ session: FocusSession) {
        history.append(session)
        save()
    }

    func clear() {
        history.removeAll()
        store.delete(fileName)
    }
}

// MARK: - FocusEngine (Timer Logic)

/// Pure Combine-based timer manager for Focus sessions.
final class FocusEngine: ObservableObject {

    // Published session state
    @Published private(set) var session: FocusSession? = nil
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var progress: Double = 0

    private var timerCancellable: AnyCancellable?
    private let interval: TimeInterval = 1.0
    private var repo: FocusRepository?
    private let haptics = HapticsManager.shared

    init(repo: FocusRepository? = nil) {
        self.repo = repo
    }

    // MARK: - Session control

    func start(mood: Mood?, taskTitle: String, duration: TimeInterval = 1500) {
        stop() // cancel any existing
        var s = FocusSession(
            mood: mood,
            taskTitle: taskTitle,
            duration: duration,
            startTime: Date(),
            isActive: true
        )
        session = s
        remaining = duration
        progress = 0

        // Auto-save start
        repo?.add(s)

        // Create timer publisher
        timerCancellable = Timer
            .publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }

        haptics.light()
    }

    func stop(saveFinal: Bool = true) {
        timerCancellable?.cancel()
        timerCancellable = nil

        if saveFinal, var s = session {
            s.isActive = false
            s.startTime = s.startTime ?? Date()
            repo?.add(s)
        }

        session = nil
        remaining = 0
        progress = 0
    }

    func tick() {
        guard let s = session else { return }
        let now = Date()
        let rem = s.remaining(at: now)
        remaining = rem
        progress = s.progress(at: now)

        if rem <= 0 {
            finish()
        }
    }

    func finish() {
        timerCancellable?.cancel()
        timerCancellable = nil
        if var s = session {
            s.isActive = false
            repo?.add(s)
        }
        session = nil
        remaining = 0
        progress = 1
        haptics.success()
    }

    // MARK: - Helpers

    func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
