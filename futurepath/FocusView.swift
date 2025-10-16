//
//  FocusView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class FocusViewModel: ObservableObject {

    // Dependencies
    private let repo: FocusRepository
    private let engine: FocusEngine

    // Inputs (bindings)
    @Published var selectedMood: Mood? = nil
    @Published var taskTitle: String = ""
    @Published var duration: TimeInterval = 25 * 60 // seconds

    // Outputs (from engine)
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var progress: Double = 0

    // History
    @Published private(set) var history: [FocusSession] = []

    private var bag = Set<AnyCancellable>()

    init(repository: FocusRepository) {
           self.repo = repository
           self.engine = FocusEngine(repo: repository)

           engine.$session
               .sink { [weak self] session in
                   guard let self else { return }
                   self.isRunning = (session?.isActive ?? false)
                   self.history = self.repo.history
               }
               .store(in: &bag)

           engine.$remaining.assign(to: &self.$remaining)
           engine.$progress.assign(to: &self.$progress)

           self.history = repo.history
       }
    // MARK: - Actions

    func start() {
        let title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        engine.start(mood: selectedMood, taskTitle: title, duration: duration)
    }

    func stop() {
        engine.stop(saveFinal: true)
        // history is persisted in repo by engine
        self.history = repo.history
    }

    func resetDefaults() {
        selectedMood = nil
        taskTitle = ""
        duration = 25 * 60
    }

    // Helpers

    func formatted(_ seconds: TimeInterval) -> String {
        engine.formatTime(seconds)
    }

    func presetDurations() -> [TimeInterval] {
        [15*60, 25*60, 45*60, 60*60]
    }

    func titlePlaceholder() -> String {
        if let mood = selectedMood {
            return "What to do in \(mood.displayName.lowercased()) mood?"
        }
        return "What are you focusing on?"
    }
}

// MARK: - Screen

@MainActor
struct FocusScreen: View {

    @StateObject private var vm: FocusViewModel

    // UI State
    @State private var showKeyboard: Bool = false

    @EnvironmentObject private var theme: AppTheme
    private let haptics = HapticsManager.shared

    init(viewModel: FocusViewModel) {
            _vm = StateObject(wrappedValue: viewModel)
        }

    var body: some View {
        ZStack {
            // Animated background by mood
            GradientBackdropView(mood: vm.selectedMood, intensity: 0.35)

            VStack(spacing: 18) {
                header

                timerCard

                controlsCard

                historyList
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)
        }
        .navigationTitle("Focus")
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.accentColor)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            // Mood selector
            // Mood selector
//            MoodPickerView(selected: $vm.selectedMood)
//                .environmentObject(theme)
//                .padding(.horizontal, -2)
            FocusMoodRow(selected: $vm.selectedMood)

            // Task title
            HStack(spacing: 10) {
                Image(systemName: IconLibrary.work)
                TextField(vm.titlePlaceholder(), text: $vm.taskTitle)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
    }

    // MARK: - Timer Card

    private var timerCard: some View {
        VStack(spacing: 14) {
            FocusProgressRing(progress: vm.progress)
                .frame(width: 180, height: 180)

            Text(vm.formatted(vm.remaining == 0 && !vm.isRunning ? vm.duration : vm.remaining))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(theme.textPrimary)

            HStack(spacing: 10) {
                ForEach(vm.presetDurations(), id: \.self) { dur in
                    Chip(
                        title: durationLabel(dur),
                        systemIcon: "clock",
                        selected: vm.duration == dur && !vm.isRunning,
                        color: theme.accentColor
                    ) {
                        guard !vm.isRunning else { return }
                        vm.duration = dur
                        haptics.selectionChange()
                    }
                    .environmentObject(theme)
                    .opacity(vm.isRunning ? 0.45 : 1)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground).opacity(0.7)))
        .overlay(
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Controls

    private var controlsCard: some View {
        HStack(spacing: 12) {
            if vm.isRunning {
                Button {
                    vm.stop()
                    haptics.warning()
                } label: {
                    controlLabel(title: "Stop", icon: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(ColorPalette.brandCoral)
            } else {
                Button {
                    vm.start()
                    haptics.success()
                } label: {
                    controlLabel(title: "Start", icon: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accentColor)

                Button {
                    vm.resetDefaults()
                    haptics.selectionChange()
                } label: {
                    controlLabel(title: "Reset", icon: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }

    private func controlLabel(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title).font(Typography.bodyMedium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - History

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sessions")
                .font(Typography.subtitle)
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if vm.history.isEmpty {
                EmptyStateView(
                    iconSystemName: "timer",
                    title: "No focus sessions yet",
                    message: "Start your first focus to build momentum."
                )
                .environmentObject(theme)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(vm.history.prefix(10)) { s in
                            FocusHistoryRow(session: s)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func durationLabel(_ seconds: TimeInterval) -> String {
        "\(Int(seconds/60))m"
    }
}

// MARK: - Components

private struct FocusProgressRing: View {
    var progress: Double // 0...1

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 14)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, progress))))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((progress * 100).rounded()))%")
                .font(Typography.subtitle)
        }
    }
}

private struct FocusMoodRow: View {
    @Binding var selected: Mood?
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Mood.allCases) { m in
                    Button {
                        selected = m
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: m.icon).font(.system(size: 13, weight: .semibold))
                            Text(m.displayName).font(Typography.caption)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background((selected == m ? m.gradient : LinearGradient(colors: [Color(.systemFill)], startPoint: .top, endPoint: .bottom)))
                        .foregroundStyle(selected == m ? Color.white : Color.primary.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}



private struct FocusHistoryRow: View {
    let session: FocusSession
    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorForMood(session.mood).opacity(0.2))
                    .frame(width: 42, height: 42)
                Image(systemName: iconForMood(session.mood))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(colorForMood(session.mood))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.taskTitle.isEmpty ? "Focus Session" : session.taskTitle)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(theme.textPrimary)

                HStack(spacing: 8) {
                    if let mood = session.mood {
                        Label(mood.displayName, systemImage: mood.icon)
                            .font(Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    Text("• \(Int(session.duration/60))m")
                        .font(Typography.caption)
                        .foregroundStyle(theme.textSecondary)
                    if let start = session.startTime {
                        Text("• \(timeLabel(start))")
                            .font(Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.04), lineWidth: 1))
    }

    private func colorForMood(_ mood: Mood?) -> Color {
        switch mood {
        case .some(.calm):     return ColorPalette.brandGreen
        case .some(.focused):  return ColorPalette.brandBlue
        case .some(.tired):    return ColorPalette.brandPurple
        case .some(.inspired): return ColorPalette.brandYellow
        case .some(.anxious):  return ColorPalette.brandCoral
        case .none:            return ColorPalette.brandBlue
        }
    }

    private func iconForMood(_ mood: Mood?) -> String {
        switch mood {
        case .some(.calm):     return IconLibrary.relax
        case .some(.focused):  return IconLibrary.work
        case .some(.tired):    return IconLibrary.home
        case .some(.inspired): return IconLibrary.study
        case .some(.anxious):  return IconLibrary.health
        case .none:            return IconLibrary.idea
        }
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f.string(from: date)
    }
}
