//
//  StatsScreen.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Analytics screen showing mood distribution, completion, streaks, and daily summaries.
struct StatsScreen: View {

    // MARK: - ViewModel

    @StateObject private var vm: StatsViewModel

    // MARK: - UI State

    @State private var rangeMode: RangeMode = .week

    // MARK: - Environment

    @EnvironmentObject private var theme: AppTheme
    private let haptics = HapticsManager.shared
    private let calendar = Calendar.current

    // MARK: - Types

    enum RangeMode: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case custom = "Custom"

        var id: String { rawValue }
    }

    // MARK: - Init

    init(viewModel: StatsViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        summaryCards

                        moodShareCard

                        weekdayHistogramCard

                        dailyList
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Stats")
        }
        .tint(theme.accentColor)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            // Range mode + navigation
            HStack(spacing: 12) {
                Picker("", selection: $rangeMode) {
                    ForEach(RangeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: rangeMode) { _, newMode in
                    switch newMode {
                    case .week:
                        vm.setWeek(of: vm.end) // keep around current day
                    case .month:
                        vm.setMonth(of: vm.end)
                    case .custom:
                        break
                    }
                    haptics.selectionChange()
                }

                Spacer()

                Button {
                    vm.previousSpan()
                    haptics.selectionChange()
                } label: {
                    Image(systemName: "chevron.left")
                }

                Button {
                    vm.nextSpan()
                    haptics.selectionChange()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            // Date range selector (active in custom mode)
            if rangeMode == .custom {
                HStack(spacing: 10) {
                    DatePicker("Start", selection: Binding(
                        get: { vm.start },
                        set: { vm.setRange(start: $0, end: vm.end) }
                    ), displayedComponents: .date)
                    .labelsHidden()

                    DatePicker("End", selection: Binding(
                        get: { vm.end },
                        set: { vm.setRange(start: vm.start, end: $0) }
                    ), displayedComponents: .date)
                    .labelsHidden()
                }
            }

            Text("\(formatted(vm.start)) – \(formatted(vm.end))")
                .font(Typography.caption)
                .foregroundStyle(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Selected range")
        }
    }

    // MARK: - Summary

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Completion",
                    valueText: "\(Int((vm.completionRate * 100).rounded()))%",
                    content: {
                        ProgressBar(progress: vm.completionRate)
                    }
                )
                SummaryCard(
                    title: "Streak",
                    valueText: "\(vm.longestStreak)d",
                    content: {
                        Text("Longest productive streak")
                            .font(Typography.footnote)
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
            }

            HStack(spacing: 12) {
                SummaryCard(
                    title: "Avg Created",
                    valueText: String(format: "%.1f", vm.avgCreatedPerDay),
                    content: {
                        Text("tasks/day")
                            .font(Typography.footnote)
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                SummaryCard(
                    title: "Avg Done",
                    valueText: String(format: "%.1f", vm.avgDonePerDay),
                    content: {
                        Text("tasks/day")
                            .font(Typography.footnote)
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
            }
        }
    }

    // MARK: - Mood Share

    private var moodShareCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood Distribution")
                .font(Typography.subtitle)
                .foregroundStyle(theme.textPrimary)

            VStack(spacing: 8) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    let share = vm.moodShares.first(where: { $0.mood == mood })?.share ?? 0
                    HStack(spacing: 10) {
                        Label(mood.displayName, systemImage: mood.icon)
                            .font(Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                            .frame(width: 120, alignment: .leading)
                        Bar(value: share, gradient: mood.gradient)
                        Text("\(Int((share * 100).rounded()))%")
                            .font(Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
        }
    }

    // MARK: - Weekday Histogram

    private var weekdayHistogramCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Done by Weekday")
                .font(Typography.subtitle)
                .foregroundStyle(theme.textPrimary)

            let maxVal = (vm.weekdayHistogram.values.max() ?? 1)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(1...7, id: \.self) { w in
                    let v = vm.weekdayHistogram[w] ?? 0
                    VStack(spacing: 6) {
                        Rectangle()
                            .fill(theme.accentColor.opacity(0.85))
                            .frame(width: 20, height: max(6, CGFloat(v) / CGFloat(maxVal) * 120))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .accessibilityLabel("\(weekdayShort(w))")
                            .accessibilityValue("\(v) done")
                        Text(weekdayShort(w))
                            .font(Typography.footnote)
                            .foregroundStyle(theme.textSecondary)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 150)
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
        }
    }

    // MARK: - Daily list

    private var dailyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Summary")
                .font(Typography.subtitle)
                .foregroundStyle(theme.textPrimary)

            VStack(spacing: 10) {
                ForEach(vm.daily) { day in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dayLabel(day.date))
                                .font(Typography.bodyMedium)
                                .foregroundStyle(theme.textPrimary)
                            HStack(spacing: 8) {
                                if let mood = day.mood {
                                    Label(mood.displayName, systemImage: mood.icon)
                                        .font(Typography.caption)
                                        .foregroundStyle(theme.textSecondary)
                                } else {
                                    Text("No mood")
                                        .font(Typography.caption)
                                        .foregroundStyle(theme.textSecondary)
                                }
                                Text("• \(day.done)/\(day.total) done")
                                    .font(Typography.caption)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }

                        Spacer(minLength: 12)

                        ProgressRing(progress: day.progress)
                            .frame(width: 34, height: 34)
                            .accessibilityLabel("Progress")
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func dayLabel(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: d)
    }

    private func weekdayShort(_ idx: Int) -> String {
        // Calendar.current weekday: 1=Sunday ... 7=Saturday
        let symbols = calendar.shortWeekdaySymbols // ["Sun","Mon",...]
        let i = max(1, min(7, idx)) - 1
        return symbols[i]
    }
}

// MARK: - Reusable Local Views

private struct SummaryCard<Content: View>: View {
    @EnvironmentObject private var theme: AppTheme

    let title: String
    let valueText: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(theme.textSecondary)
            Text(valueText)
                .font(Typography.title)
                .foregroundStyle(theme.textPrimary)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }
}

private struct ProgressBar: View {
    var progress: Double // 0...1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemFill))
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProgressRing: View {
    var progress: Double // 0...1

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, progress))))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((progress * 100).rounded()))%")
                .font(Typography.footnote)
        }
    }
}

private struct Bar: View {
    var value: Double // 0...1
    var gradient: LinearGradient

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemFill))
                RoundedRectangle(cornerRadius: 8)
                    .fill(gradient)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
