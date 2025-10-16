//
//  TaskRowView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Reusable task row component with optional emphasis and callbacks.
/// This component is independent from screen-specific row implementations.
struct TaskRowView: View {

    // MARK: - Types

    enum Emphasis {
        case normal
        case highlight  // subtle colored background
        case warning    // stronger, for overdue, etc.
    }

    // MARK: - Inputs

    let item: TaskItem
    var emphasis: Emphasis = .normal
    var showMoodChip: Bool = true
    var showDueDate: Bool = true
    var onToggle: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    // MARK: - Environment

    @EnvironmentObject private var theme: AppTheme

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Toggle
                Button(action: { onToggle?() }) {
                    Image(systemName: item.isDone ? IconLibrary.done : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(item.isDone ? Color.green : theme.textSecondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                // Texts
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(theme.textPrimary)
                        .strikethrough(item.isDone, color: theme.textSecondary.opacity(0.6))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if showMoodChip, let mood = item.moodHint {
                            Label(mood.displayName, systemImage: mood.icon)
                                .labelStyle(.titleAndIcon)
                                .font(Typography.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        if showDueDate, let due = item.formattedDueDate {
                            Label(due, systemImage: "calendar")
                                .labelStyle(.titleAndIcon)
                                .font(Typography.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }

                Spacer(minLength: 8)

                // Trailing icon with color accent
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(item.color)
            }
            .padding(12)
            .background(backgroundFill)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Double tap to open")
    }

    // MARK: - Helpers

    private var backgroundFill: some View {
        let base: Color
        switch emphasis {
        case .normal:
            base = Color(.secondarySystemBackground)
        case .highlight:
            base = item.color.opacity(0.12)
        case .warning:
            base = ColorPalette.brandYellow.opacity(0.18)
        }
        return RoundedRectangle(cornerRadius: 14).fill(base)
    }
}

#if DEBUG
struct TaskRowView_Previews: PreviewProvider {
    static var previews: some View {
        let theme = AppTheme()
        let example = TaskItem(
            title: "Read 20 pages",
            note: "Tonight before bed",
            moodHint: .calm,
            dueDate: Date(),
            isDone: false,
            colorID: "brandGreen",
            iconName: IconLibrary.study
        )

        return VStack(spacing: 12) {
            TaskRowView(item: example)
                .environmentObject(theme)

            TaskRowView(item: example, emphasis: .highlight)
                .environmentObject(theme)

            TaskRowView(
                item: TaskItem(title: "Email report", moodHint: .focused, dueDate: Date().addingTimeInterval(-86400), colorID: "brandYellow", iconName: IconLibrary.work),
                emphasis: .warning
            )
            .environmentObject(theme)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
