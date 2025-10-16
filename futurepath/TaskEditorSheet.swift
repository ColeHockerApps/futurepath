//
//  TaskEditorSheet.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Universal sheet for creating or editing a task.
/// Pure UI component: persistence happens via callbacks.
struct TaskEditorSheet: View {

    // MARK: - Mode

    enum Mode {
        case create(defaultMood: Mood? = nil)
        case edit(existing: TaskItem)

        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }
    }

    // MARK: - Input

    let mode: Mode
    let onCancel: () -> Void
    let onSave: (TaskItem) -> Void
    let onDelete: ((UUID) -> Void)?

    // MARK: - State

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var selectedMood: Mood? = nil
    @State private var iconName: String = IconLibrary.idea
    @State private var colorID: String = "brandBlue"
    @State private var hasDueDate: Bool = true
    @State private var dueDate: Date = Calendar.current.startOfDay(for: Date())

    // MARK: - Env

    @EnvironmentObject private var theme: AppTheme
    private let haptics = HapticsManager.shared
    private let calendar = Calendar.current

    // MARK: - Constants

    private let colorOptions = ["brandBlue", "brandGreen", "brandYellow", "brandCoral", "brandPurple"]
    private let iconOptions  = [
        IconLibrary.work, IconLibrary.study, IconLibrary.sport, IconLibrary.health,
        IconLibrary.relax, IconLibrary.travel, IconLibrary.social, IconLibrary.idea,
        IconLibrary.finance, IconLibrary.home
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                        .onSubmit { trySave() }
                    TextField("Note (optional)", text: $note)
                }

                Section("Mood") {
                    Picker("Mood", selection: Binding(
                        get: { selectedMood ?? .calm },
                        set: { selectedMood = $0 }
                    )) {
                        ForEach(Mood.allCases) { m in
                            Label(m.displayName, systemImage: m.icon).tag(m)
                        }
                    }
                    .pickerStyle(.menu)

                    // Quick horizontal selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Mood.allCases) { m in
                                Button {
                                    selectedMood = m
                                    haptics.selectionChange()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: m.icon)
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(m.displayName)
                                            .font(Typography.caption)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        (selectedMood == m ? m.gradient : LinearGradient(colors: [Color(.systemFill)], startPoint: .top, endPoint: .bottom))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    )
                                    .foregroundStyle(selectedMood == m ? Color.white : Color.primary.opacity(0.85))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
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

                Section("Schedule") {
                    Toggle("Has due date", isOn: $hasDueDate)
                        .onChange(of: hasDueDate) { _, on in
                            if on == true && dueDate < calendar.startOfDay(for: Date()) {
                                dueDate = calendar.startOfDay(for: Date())
                            }
                        }
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                if mode.isEditing, let onDelete = onDelete {
                    Section {
                        Button(role: .destructive) {
                            if case .edit(let existing) = mode {
                                onDelete(existing.id)
                                haptics.warning()
                            }
                        } label: {
                            Label("Delete Task", systemImage: IconLibrary.delete)
                        }
                    }
                }
            }
            .navigationTitle(mode.isEditing ? "Edit Task" : "New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { trySave() }
                        .disabled(titleTrimmed().isEmpty)
                }
            }
        }
        .tint(theme.accentColor)
        .onAppear { seedFromMode() }
    }

    // MARK: - Actions

    private func trySave() {
        let cleanTitle = titleTrimmed()
        guard !cleanTitle.isEmpty else { return }

        switch mode {
        case .create(let defMood):
            let item = TaskItem(
                title: cleanTitle,
                note: noteTrimmed(),
                moodHint: selectedMood ?? defMood,
                dueDate: hasDueDate ? calendar.startOfDay(for: dueDate) : nil,
                isDone: false,
                colorID: colorID,
                iconName: iconName
            )
            onSave(item)
            haptics.success()

        case .edit(let existing):
            var updated = existing
            updated.title = cleanTitle
            updated.note = noteTrimmed()
            updated.moodHint = selectedMood
            updated.dueDate = hasDueDate ? calendar.startOfDay(for: dueDate) : nil
            updated.colorID = colorID
            updated.iconName = iconName
            onSave(updated)
            haptics.light()
        }
    }

    private func seedFromMode() {
        switch mode {
        case .create(let defMood):
            title = ""
            note = ""
            selectedMood = defMood
            iconName = IconLibrary.idea
            colorID = "brandBlue"
            hasDueDate = true
            dueDate = calendar.startOfDay(for: Date())

        case .edit(let existing):
            title = existing.title
            note = existing.note ?? ""
            selectedMood = existing.moodHint
            iconName = existing.iconName
            colorID = existing.colorID
            hasDueDate = existing.dueDate != nil
            dueDate = calendar.startOfDay(for: existing.dueDate ?? Date())
        }
    }

    // MARK: - Helpers

    private func titleTrimmed() -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
    }

    private func noteTrimmed() -> String? {
        let n = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? nil : n
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

// MARK: - Identifiable wrapper (optional convenience)

//extension TaskItem: Identifiable {}

#if DEBUG
struct TaskEditorSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TaskEditorSheet(
                mode: .create(defaultMood: .calm),
                onCancel: {},
                onSave: { _ in },
                onDelete: nil
            )
            .environmentObject(AppTheme())

            TaskEditorSheet(
                mode: .edit(existing: TaskItem(title: "Read book", moodHint: .focused, dueDate: Date(), colorID: "brandGreen", iconName: IconLibrary.study)),
                onCancel: {},
                onSave: { _ in },
                onDelete: { _ in }
            )
            .environmentObject(AppTheme())
        }
    }
}
#endif
