//
//  TodayScreen.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Main "Today" screen: mood picker + prioritized recommendations + quick add.
@MainActor
struct TodayScreen: View {

    // MARK: - ViewModels owned by this screen

    @StateObject private var moodVM: MoodPickerViewModel
    @StateObject private var listVM:  TaskListViewModel

    // MARK: - UI State

    @State private var showAddSheet: Bool = false
    @State private var newTitle: String = ""
    @State private var newNote: String = ""
    @State private var newMood: Mood? = nil
    @State private var newIcon: String = IconLibrary.idea
    @State private var newColorID: String = "brandBlue"

    // MARK: - Theme / Haptics

    @EnvironmentObject private var theme: AppTheme
    private let haptics = HapticsManager.shared

    // MARK: - Init (explicit DI)

    init(
        appState: AppState,
        moodRepository: MoodRepository,
        taskRepository: TaskRepository,
        settings: SettingsStore,
        moodEngine: MoodEngine = MoodEngine(),
        taskEngine: TaskEngine = TaskEngine()
    ) {
        _moodVM = StateObject(wrappedValue: MoodPickerViewModel(
            appState: appState,
            moodRepository: moodRepository,
            taskRepository: taskRepository,
            moodEngine: moodEngine,
            taskEngine: taskEngine,
            settings: settings
        ))
        _listVM = StateObject(wrappedValue: TaskListViewModel(
            appState: appState,
            tasksRepository: taskRepository,
            taskEngine: taskEngine
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        headerSection

                        moodPickerSection

                        if !moodVM.quickWins.isEmpty {
                            quickWinsSection
                        }

                        recommendationsSection

                        todayBucketSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }

                addFloatingButton
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        openAdd()
                    } label: {
                        Image(systemName: IconLibrary.add)
                    }
                    .tint(theme.accentColor)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTaskSheet(
                    title: $newTitle,
                    note: $newNote,
                    mood: $newMood,
                    iconName: $newIcon,
                    colorID: $newColorID,
                    onCancel: closeAdd,
                    onSave: saveNewTask
                )
                .presentationDetents([.large])
            }
        }
        .tint(theme.accentColor)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dateLabel(moodVM.date))
                .font(Typography.caption)
                .foregroundStyle(theme.textSecondary)
            Text("How are you today?")
                .font(Typography.title)
                .foregroundStyle(theme.textPrimary)
        }
    }

    private var moodPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Mood.allCases) { mood in
                        MoodChip(
                            mood: mood,
                            selected: moodVM.selectedMood == mood
                        ) {
                            haptics.selectionChange()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                moodVM.setMood(mood)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let mood = moodVM.selectedMood {
                RoundedRectangle(cornerRadius: 16)
                    .fill(mood.gradient)
                    .overlay(
                        HStack(spacing: 12) {
                            Image(systemName: mood.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text("\(mood.displayName) mode is on")
                                .font(Typography.body)
                        }
                        .foregroundStyle(Color.white.opacity(0.95))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    )
                    .frame(height: 44)
                    .accessibilityLabel("\(mood.displayName) mode")
            } else {
                Text("Pick a mood to get tailored suggestions.")
                    .font(Typography.body)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private var quickWinsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Wins")
                .font(Typography.subtitle)
                .foregroundStyle(theme.textPrimary)
            VStack(spacing: 8) {
                ForEach(moodVM.quickWins) { item in
                    TaskRow(item: item, highlight: true) {
                        listVM.toggleDone(item.id)
                        haptics.light()
                    }
                }
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended")
                .font(Typography.subtitle)
                .foregroundStyle(theme.textPrimary)
            if moodVM.recommendations.isEmpty {
                EmptyState(text: "No recommendations yet. Add a task to get started.")
            } else {
                VStack(spacing: 8) {
                    ForEach(moodVM.recommendations) { item in
                        TaskRow(item: item) {
                            listVM.toggleDone(item.id)
                            haptics.light()
                        }
                    }
                }
            }
        }
    }

    private var todayBucketSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today’s Tasks")
                .font(Typography.subtitle)
                .foregroundStyle(theme.textPrimary)

            if listVM.items.isEmpty {
                EmptyState(text: "Nothing planned for today. Tap + to add your first task.")
            } else {
                VStack(spacing: 8) {
                    ForEach(listVM.items) { item in
                        TaskRow(item: item) {
                            listVM.toggleDone(item.id)
                            haptics.light()
                        }
                    }
                }
            }

            if !listVM.overdue.isEmpty {
                Divider().padding(.vertical, 8)
                Text("Overdue")
                    .font(Typography.caption)
                    .foregroundStyle(theme.textSecondary)
                VStack(spacing: 8) {
                    ForEach(listVM.overdue) { item in
                        TaskRow(item: item) {
                            listVM.toggleDone(item.id)
                            haptics.medium()
                        }
                    }
                }
            }

            if !listVM.undated.isEmpty {
                Divider().padding(.vertical, 8)
                Text("Undated")
                    .font(Typography.caption)
                    .foregroundStyle(theme.textSecondary)
                VStack(spacing: 8) {
                    ForEach(listVM.undated) { item in
                        TaskRow(item: item) {
                            listVM.toggleDone(item.id)
                            haptics.light()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Floating Add Button

    private var addFloatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: openAdd) {
                    Image(systemName: IconLibrary.add)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(18)
                        .background(theme.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 8, x: 0, y: 4)
                        .accessibilityLabel("Add Task")
                }
                .padding(.trailing, 18)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Actions

    private func openAdd() {
        newTitle = ""
        newNote = ""
        newMood = moodVM.selectedMood
        newIcon = IconLibrary.idea
        newColorID = "brandBlue"
        showAddSheet = true
        haptics.selectionChange()
    }

    private func closeAdd() {
        showAddSheet = false
    }

    private func saveNewTask() {
        let due = moodVM.date // default to today's startOfDay inside VM addTask
        _ = listVM.addTask(
            title: newTitle,
            note: newNote.isEmpty ? nil : newNote,
            moodHint: newMood,
            dueDate: due,
            colorID: newColorID,
            iconName: newIcon
        )
        showAddSheet = false
        haptics.success()
        // Refresh recommendations to include the new item
        moodVM.refreshAll()
        listVM.refreshAll()
    }

    // MARK: - Helpers

    private func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }
}

// MARK: - Subviews (private to this file)

private struct MoodChip: View {
    let mood: Mood
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: mood.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(mood.displayName)
                    .font(Typography.bodyMedium)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                ZStack {
                    Color(.systemFill)
                    if selected {
                        mood.gradient
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(selected ? Color.white : Color.primary.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? Color.white.opacity(0.35) : Color.black.opacity(0.06), lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(mood.displayName)
            .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
        }
        .buttonStyle(.plain)
    }
}

private struct TaskRow: View {
    let item: TaskItem
    var highlight: Bool = false
    let toggle: () -> Void

    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                Image(systemName: item.isDone ? IconLibrary.done : "circle")
                    .font(.system(size: 20, weight: .semibold))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(theme.textPrimary)
                    .strikethrough(item.isDone, color: theme.textSecondary.opacity(0.6))

                HStack(spacing: 8) {
                    if let mood = item.moodHint {
                        Label(mood.displayName, systemImage: mood.icon)
                            .labelStyle(.titleAndIcon)
                            .font(Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    if let due = item.formattedDueDate {
                        Label(due, systemImage: "calendar")
                            .labelStyle(.titleAndIcon)
                            .font(Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
            Spacer(minLength: 8)
            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(item.color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(highlight ? item.color.opacity(0.12) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}

private struct EmptyState: View {
    let text: String
    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 18, weight: .regular))
            Text(text)
                .font(Typography.body)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct AddTaskSheet: View {
    @Binding var title: String
    @Binding var note: String
    @Binding var mood: Mood?
    @Binding var iconName: String
    @Binding var colorID: String

    let onCancel: () -> Void
    let onSave: () -> Void

    @EnvironmentObject private var theme: AppTheme

    private let colorOptions = ["brandBlue", "brandGreen", "brandYellow", "brandCoral", "brandPurple"]
    private let iconOptions  = [
        IconLibrary.work, IconLibrary.study, IconLibrary.sport, IconLibrary.health,
        IconLibrary.relax, IconLibrary.travel, IconLibrary.social, IconLibrary.idea,
        IconLibrary.finance, IconLibrary.home
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Note (optional)", text: $note)
                }

                Section("Mood") {
                    Picker("Mood", selection: Binding(
                        get: { mood ?? .calm },
                        set: { newVal in mood = newVal }
                    )) {
                        ForEach(Mood.allCases) { m in
                            Label(m.displayName, systemImage: m.icon).tag(m)
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Icon", selection: $iconName) {
                        ForEach(iconOptions, id: \.self) { name in
                            Label(name.replacingOccurrences(of: ".fill", with: ""), systemImage: name).tag(name)
                        }
                    }
                    Picker("Color", selection: $colorID) {
                        ForEach(colorOptions, id: \.self) { id in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colorForID(id))
                                    .frame(width: 14, height: 14)
                                Text(readableColorID(id))
                            }.tag(id)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .tint(theme.accentColor)
    }

    private func colorForID(_ id: String) -> Color {
        switch id {
        case "brandBlue":   return ColorPalette.brandBlue
        case "brandGreen":  return ColorPalette.brandGreen
        case "brandYellow": return ColorPalette.brandYellow
        case "brandCoral":  return ColorPalette.brandCoral
        case "brandPurple": return ColorPalette.brandPurple
        default:            return .gray
        }
    }

    private func readableColorID(_ id: String) -> String {
        switch id {
        case "brandBlue":   return "Blue"
        case "brandGreen":  return "Green"
        case "brandYellow": return "Yellow"
        case "brandCoral":  return "Coral"
        case "brandPurple": return "Purple"
        default:            return id
        }
    }
}
