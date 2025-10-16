//
//  JournalView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

// MARK: - ViewModel


final class JournalViewModel: ObservableObject {

    // Dependencies
    private let repo: JournalRepository
    private let engine: JournalEngine

    // Inputs (filters)
    @Published var moodFilter: Mood? = nil { didSet { recompute() } }
    @Published var searchText: String = "" { didSet { recompute() } }

    // Outputs
    @Published private(set) var entries: [JournalEntry] = []
    @Published private(set) var grouped: [(month: Date, items: [JournalEntry])] = []
    @Published private(set) var moodHistogram: [Mood: Int] = [:]

    private var bag = Set<AnyCancellable>()
    private let calendar = Calendar.current

    init(repo: JournalRepository, engine: JournalEngine = JournalEngine()) {
        self.repo = repo
        self.engine = engine
        bind()
        recompute()
    }

    private func bind() {
        repo.$entries
            .sink { [weak self] _ in self?.recompute() }
            .store(in: &bag)
    }

    // MARK: - Public API

    func add(date: Date, mood: Mood?, note: String, colorID: String? = nil, iconName: String? = nil) {
        let suggestedColor = colorID ?? engine.suggestedColorID(for: mood)
        let suggestedIcon  = iconName ?? engine.suggestedIcon(for: mood)
        let entry = engine.makeEntry(
            date: date,
            mood: mood,
            note: note,
            colorID: suggestedColor,
            iconName: suggestedIcon
        )
        repo.add(entry)
    }

    func update(_ entry: JournalEntry) {
        repo.update(entry)
    }

    func delete(_ id: UUID) {
        repo.delete(id)
    }

    // MARK: - Compute

    private func recompute() {
        let base: [JournalEntry]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            base = repo.entries
        } else {
            base = repo.search(searchText)
        }
        let filtered = moodFilter == nil ? base : base.filter { $0.mood == moodFilter }
        entries = filtered
        grouped = engine.groupedByMonth(filtered)
        moodHistogram = engine.moodHistogram(filtered)
    }
}

// MARK: - Screen


struct JournalScreen: View {

    @StateObject private var vm: JournalViewModel

    // UI State
    @State private var showEditor = false
    @State private var editing: JournalEntry? = nil
    @State private var newDate: Date = Date()
    @State private var newMood: Mood? = nil
    @State private var newNote: String = ""

    @EnvironmentObject private var theme: AppTheme
    private let haptics = HapticsManager.shared

    init(viewModel: JournalViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                if vm.entries.isEmpty {
                    EmptyStateView(
                        iconSystemName: "book.closed",
                        title: "No journal entries",
                        message: "Capture how you feel and why. It helps planning.",
                        actionTitle: "New Entry",
                        action: { openCreate() }
                    )
                    .padding()
                } else {
                    List {
                        // Filter bar
                        Section {
                            filterBar
                        }

                        // Groups
                        ForEach(vm.grouped, id: \.month) { group in
                            Section(header: Text(monthLabel(group.month)).font(Typography.caption)) {
                                ForEach(group.items) { entry in
                                    JournalEntryRow(entry: entry)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            editing = entry
                                            showEditor = true
                                            haptics.selectionChange()
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                vm.delete(entry.id)
                                                haptics.medium()
                                            } label: {
                                                Label("Delete", systemImage: IconLibrary.delete)
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }

                // Floating add
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            openCreate()
                        } label: {
                            Image(systemName: IconLibrary.add)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(18)
                                .background(theme.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 18)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Journal")
            .sheet(isPresented: $showEditor) {
                JournalEditorSheet(
                    mode: editing == nil ? .create(defaultMood: newMood) : .edit(existing: editing!),
                    onCancel: { showEditor = false },
                    onSave: { saved in
                        if editing == nil {
                            vm.add(
                                date: saved.date,
                                mood: saved.mood,
                                note: saved.note,
                                colorID: saved.colorID,
                                iconName: saved.iconName
                            )
                        } else {
                            vm.update(saved)
                        }
                        showEditor = false
                        haptics.success()
                    },
                    onDelete: { id in
                        vm.delete(id)
                        showEditor = false
                        haptics.warning()
                    }
                )
                .environmentObject(theme)
                .presentationDetents([.medium, .large])
            }
        }
        .tint(theme.accentColor)
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
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField("Search in notes", text: Binding(
                    get: { vm.searchText },
                    set: { vm.searchText = $0 }
                ))
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
                        haptics.selectionChange()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.clear)
    }

    // MARK: - Actions

    private func openCreate() {
        newDate = Date()
        newMood = nil
        newNote = ""
        editing = nil
        showEditor = true
        haptics.selectionChange()
    }

    // MARK: - Helpers

    private func monthLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date)
    }
}

// MARK: - Row

private struct JournalEntryRow: View {
    let entry: JournalEntry
    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: entry.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(entry.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.formattedDate)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(theme.textPrimary)
                    if let mood = entry.mood {
                        Label(mood.displayName, systemImage: mood.icon)
                            .font(Typography.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                Text(entry.note)
                    .font(Typography.body)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(3)
            }

            Spacer(minLength: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        )
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

// MARK: - Editor

private struct JournalEditorSheet: View {

    enum Mode {
        case create(defaultMood: Mood? = nil)
        case edit(existing: JournalEntry)

        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }
    }

    let mode: Mode
    let onCancel: () -> Void
    let onSave: (JournalEntry) -> Void
    let onDelete: ((UUID) -> Void)?

    @EnvironmentObject private var theme: AppTheme
    private let calendar = Calendar.current
    private let haptics = HapticsManager.shared

    // State
    @State private var date: Date = Date()
    @State private var mood: Mood? = nil
    @State private var note: String = ""
    @State private var colorID: String = "brandBlue"
    @State private var iconName: String = IconLibrary.idea

    private let colorOptions = ["brandBlue", "brandGreen", "brandYellow", "brandCoral", "brandPurple"]
    private let iconOptions  = [
        IconLibrary.work, IconLibrary.study, IconLibrary.sport, IconLibrary.health,
        IconLibrary.relax, IconLibrary.travel, IconLibrary.social, IconLibrary.idea,
        IconLibrary.finance, IconLibrary.home
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Mood") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Mood", selection: Binding(
                        get: { mood ?? .calm },
                        set: { mood = $0 }
                    )) {
                        ForEach(Mood.allCases) { m in
                            Label(m.displayName, systemImage: m.icon).tag(m)
                        }
                    }
                }

                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 120)
                        .font(Typography.body)
                }

                Section("Appearance") {
                    Picker("Icon", selection: $iconName) {
                        ForEach(iconOptions, id: \.self) { name in
                            Label(readableIcon(name), systemImage: name).tag(name)
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

                if mode.isEditing, let onDelete = onDelete {
                    Section {
                        Button(role: .destructive) {
                            if case .edit(let e) = mode {
                                onDelete(e.id)
                                haptics.warning()
                            }
                        } label: {
                            Label("Delete Entry", systemImage: IconLibrary.delete)
                        }
                    }
                }
            }
            .navigationTitle(mode.isEditing ? "Edit Entry" : "New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { trySave() }
                        .disabled(noteTrimmed().isEmpty)
                }
            }
        }
        .tint(theme.accentColor)
        .onAppear { seedFromMode() }
    }

    private func trySave() {
        let entry: JournalEntry
        switch mode {
        case .create:
            entry = JournalEntry(
                date: calendar.startOfDay(for: date),
                mood: mood,
                note: noteTrimmed(),
                colorID: colorID,
                iconName: iconName
            )
            haptics.success()
        case .edit(let existing):
            var e = existing
            e.date = calendar.startOfDay(for: date)
            e.mood = mood
            e.note = noteTrimmed()
            e.colorID = colorID
            e.iconName = iconName
            entry = e
            haptics.light()
        }
        onSave(entry)
    }

    private func seedFromMode() {
        switch mode {
        case .create(let defMood):
            date = Date()
            mood = defMood
            note = ""
            colorID = "brandBlue"
            iconName = IconLibrary.idea
        case .edit(let e):
            date = e.date
            mood = e.mood
            note = e.note
            colorID = e.colorID
            iconName = e.iconName
        }
    }

    private func noteTrimmed() -> String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
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

    private func readableIcon(_ name: String) -> String {
        name
            .replacingOccurrences(of: ".fill", with: "")
            .replacingOccurrences(of: ".", with: " ")
            .capitalized
    }
}

// MARK: - Small FilterChip (local, to avoid cross-file reuse clash)

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
