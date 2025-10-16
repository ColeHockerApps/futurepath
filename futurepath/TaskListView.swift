//
//  TaskListView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Reusable task list with filtering (mood + search) and grouped sections.
struct TaskListView: View {

    // MARK: - ViewModel

    @StateObject private var vm: TaskListViewModel

    // MARK: - UI state

    @State private var searchText: String = ""
    @State private var showMoveSheetFor: TaskItem? = nil
    @State private var moveTargetDay: Date = Date()

    // MARK: - Environment

    @EnvironmentObject private var theme: AppTheme
    private let haptics = HapticsManager.shared

    // MARK: - Init

    init(viewModel: TaskListViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    contentList
                }
            }
            .navigationTitle("Tasks")
        }
        .onChange(of: searchText) { _, newValue in
            vm.searchText = newValue
        }
    }

    // MARK: - Views

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        icon: "square.grid.2x2",
                        selected: vm.moodFilter == nil
                    ) {
                        vm.moodFilter = nil
                        haptics.selectionChange()
                    }

                    ForEach(Mood.allCases) { mood in
                        FilterChip(
                            title: mood.displayName,
                            icon: mood.icon,
                            selected: vm.moodFilter == mood
                        ) {
                            vm.moodFilter = mood
                            haptics.selectionChange()
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .padding(.vertical, 2)
            }

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $searchText)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        haptics.selectionChange()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var contentList: some View {
        List {
            // Today section
            Section(header: sectionHeader("Today")) {
                if vm.items.isEmpty {
                    TaskListEmptyState(text: "No tasks for today")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(vm.items) { item in
                        TaskListRowView(item: item) {
                            vm.toggleDone(item.id)
                            haptics.light()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                vm.delete(item.id)
                                haptics.medium()
                            } label: {
                                Label("Delete", systemImage: IconLibrary.delete)
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                vm.toggleDone(item.id)
                                haptics.light()
                            } label: {
                                Label(item.isDone ? "Undone" : "Done",
                                      systemImage: item.isDone ? "arrow.uturn.backward" : IconLibrary.done)
                            }.tint(.green)
                        }
                        .contextMenu {
                            Button {
                                // Move to another day
                                moveTargetDay = vm.date
                                showMoveSheetFor = item
                            } label: {
                                Label("Move to…", systemImage: "calendar.badge.clock")
                            }

                            Button {
                                vm.clearDueDate(item.id)
                            } label: {
                                Label("Remove date", systemImage: "calendar.badge.exclamationmark")
                            }
                        }
                    }
                }
            }

            // Overdue section
            if !vm.overdue.isEmpty {
                Section(header: sectionHeader("Overdue")) {
                    ForEach(vm.overdue) { item in
                        TaskListRowView(item: item, emphasis: .warning) {
                            vm.toggleDone(item.id)
                            haptics.medium()
                        }
                        .swipeActions {
                            Button {
                                vm.moveToDay(item.id, day: vm.date)
                                haptics.selectionChange()
                            } label: {
                                Label("Move to Today", systemImage: "calendar")
                            }.tint(.orange)

                            Button(role: .destructive) {
                                vm.delete(item.id)
                            } label: {
                                Label("Delete", systemImage: IconLibrary.delete)
                            }
                        }
                    }
                }
            }

            // Undated section
            if !vm.undated.isEmpty {
                Section(header: sectionHeader("Undated")) {
                    ForEach(vm.undated) { item in
                        TaskListRowView(item: item) {
                            vm.toggleDone(item.id)
                            haptics.light()
                        }
                        .swipeActions {
                            Button {
                                vm.moveToDay(item.id, day: vm.date)
                                haptics.selectionChange()
                            } label: {
                                Label("Plan for Today", systemImage: "calendar.badge.plus")
                            }.tint(.blue)

                            Button(role: .destructive) {
                                vm.delete(item.id)
                            } label: {
                                Label("Delete", systemImage: IconLibrary.delete)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $showMoveSheetFor, content: { item in
            NavigationStack {
                VStack(spacing: 16) {
                    DatePicker(
                        "Select a day",
                        selection: $moveTargetDay,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)

                    Button {
                        vm.moveToDay(item.id, day: moveTargetDay)
                        showMoveSheetFor = nil
                        haptics.success()
                    } label: {
                        Text("Move Task")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Button(role: .cancel) {
                        showMoveSheetFor = nil
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 12)
                .navigationTitle("Move Task")
            }
        })
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Typography.subtitle)
            .foregroundStyle(theme.textPrimary)
    }
}

// MARK: - Row

private struct TaskListRowView: View {
    let item: TaskItem
    var emphasis: Emphasis = .none
    let toggle: () -> Void

    enum Emphasis {
        case none
        case warning
    }

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
                .fill(backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        )
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.clear)
    }

    private var backgroundFill: Color {
        switch emphasis {
        case .none:    return Color(.secondarySystemBackground)
        case .warning: return ColorPalette.brandYellow.opacity(0.18)
        }
    }
}

// MARK: - Empty State

private struct TaskListEmptyState: View {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(Typography.caption)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? Color(.tertiarySystemFill) : Color(.systemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? Color.black.opacity(0.12) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
