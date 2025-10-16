//
//  JournalModel.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

// MARK: - JournalEntry (Model)

/// A lightweight daily note linked to an optional mood.
struct JournalEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date                  // when the entry is for (startOfDay recommended)
    var mood: Mood?                 // optional mood snapshot for the day
    var note: String                // free-form text
    var colorID: String             // accent color id for styling
    var iconName: String            // SF Symbol name for a tiny accent

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Mood? = nil,
        note: String,
        colorID: String = "brandBlue",
        iconName: String = IconLibrary.idea,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.mood = mood
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.colorID = colorID
        self.iconName = iconName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Convenience accessors for UI
    var color: Color {
        switch colorID {
        case "brandBlue":   return ColorPalette.brandBlue
        case "brandGreen":  return ColorPalette.brandGreen
        case "brandYellow": return ColorPalette.brandYellow
        case "brandCoral":  return ColorPalette.brandCoral
        case "brandPurple": return ColorPalette.brandPurple
        default:            return ColorPalette.brandBlue
        }
    }

    var icon: String { iconName }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}

// MARK: - JournalRepository (Persistence)

/// Repository for CRUD operations and persistence of journal entries.
@MainActor
final class JournalRepository: ObservableObject {

    // Published state
    @Published private(set) var entries: [JournalEntry] = []

    // Private
    private let store = FileStore.shared
    private let fileName = "journal.json"
    private var bag = Set<AnyCancellable>()
    private let calendar = Calendar.current

    init() {
        load()
    }

    // Persistence
    func load() {
        if let loaded: [JournalEntry] = store.load([JournalEntry].self, from: fileName) {
            entries = loaded.sorted(by: sortRule)
        } else {
            entries = []
        }
    }

    func save() {
        store.save(entries, as: fileName)
    }

    // CRUD
    func add(_ entry: JournalEntry) {
        var e = entry
        e.updatedAt = Date()
        entries.append(e)
        entries.sort(by: sortRule)
        save()
    }

    func update(_ entry: JournalEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            var e = entry
            e.updatedAt = Date()
            entries[idx] = e
            entries.sort(by: sortRule)
            save()
        }
    }

    func delete(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        entries.removeAll()
        store.delete(fileName)
    }

    func addMany(_ list: [JournalEntry]) {
        guard !list.isEmpty else { return }
        entries.append(contentsOf: list)
        entries.sort(by: sortRule)
        save()
    }

    // Queries
    func entries(on day: Date) -> [JournalEntry] {
        let start = calendar.startOfDay(for: day)
        return entries.filter { calendar.isDate($0.date, inSameDayAs: start) }
            .sorted(by: sortRule)
    }

    func entries(from start: Date, to end: Date) -> [JournalEntry] {
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        return entries.filter { $0.date >= s && $0.date <= e }
            .sorted(by: sortRule)
    }

    func search(_ text: String) -> [JournalEntry] {
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter { e in
            if e.note.lowercased().contains(q) { return true }
            if let m = e.mood, m.displayName.lowercased().contains(q) { return true }
            return false
        }
    }

    func filter(mood: Mood?) -> [JournalEntry] {
        guard let mood else { return entries }
        return entries.filter { $0.mood == mood }
    }

    func latest(limit: Int = 20) -> [JournalEntry] {
        Array(entries.sorted(by: sortRule).prefix(limit))
    }

    // Helpers
    private func sortRule(_ a: JournalEntry, _ b: JournalEntry) -> Bool {
        if a.date != b.date { return a.date > b.date }             // newest first
        if a.updatedAt != b.updatedAt { return a.updatedAt > b.updatedAt }
        return a.createdAt > b.createdAt
    }
}

// MARK: - JournalEngine (Business Logic)

/// Pure utilities for composing, sanitizing, and slicing journal data.
final class JournalEngine {

    private let calendar = Calendar.current

    /// Creates a sanitized entry from raw inputs.
    func makeEntry(
        date: Date = Date(),
        mood: Mood?,
        note: String,
        colorID: String = "brandBlue",
        iconName: String = IconLibrary.idea
    ) -> JournalEntry {
        let trimmed = note
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)

        return JournalEntry(
            date: calendar.startOfDay(for: date),
            mood: mood,
            note: trimmed.isEmpty ? "No note" : trimmed,
            colorID: colorID,
            iconName: iconName
        )
    }

    /// Returns entries grouped by month (key = first day of month).
    func groupedByMonth(_ entries: [JournalEntry]) -> [(month: Date, items: [JournalEntry])] {
        let groups = Dictionary(grouping: entries) { e -> Date in
            let comp = calendar.dateComponents([.year, .month], from: e.date)
            return calendar.date(from: DateComponents(year: comp.year, month: comp.month, day: 1)) ?? e.date
        }
        return groups.keys.sorted(by: >).map { key in
            (month: key, items: groups[key]!.sorted { $0.date > $1.date })
        }
    }

    /// Returns a short mood histogram for the given entries.
    func moodHistogram(_ entries: [JournalEntry]) -> [Mood: Int] {
        var dict: [Mood: Int] = [:]
        for e in entries {
            if let m = e.mood { dict[m, default: 0] += 1 }
        }
        return dict
    }

    /// Suggests a colorID based on mood (keeps visuals consistent).
    func suggestedColorID(for mood: Mood?) -> String {
        guard let mood else { return "brandBlue" }
        switch mood {
        case .calm:     return "brandGreen"
        case .focused:  return "brandBlue"
        case .tired:    return "brandPurple"
        case .inspired: return "brandYellow"
        case .anxious:  return "brandCoral"
        }
    }

    /// Suggests an icon based on mood.
    func suggestedIcon(for mood: Mood?) -> String {
        guard let mood else { return IconLibrary.idea }
        switch mood {
        case .calm:     return IconLibrary.relax
        case .focused:  return IconLibrary.work
        case .tired:    return IconLibrary.home
        case .inspired: return IconLibrary.study
        case .anxious:  return IconLibrary.health
        }
    }
}
