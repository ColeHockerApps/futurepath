//
//  MoodPickerView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Reusable horizontal mood picker with animated, colorful pills.
/// Provides a binding for the currently selected mood and an onSelect callback.
struct MoodPickerView: View {

    // MARK: - Bindings

    @Binding var selected: Mood?

    // MARK: - Config

    /// Optional callback fired when user selects a mood.
    var onSelect: ((Mood) -> Void)? = nil

    /// When `true`, pills are slightly smaller (useful for dense layouts).
    var compact: Bool = false

    // MARK: - Environment

    @EnvironmentObject private var theme: AppTheme
    private let haptics = HapticsManager.shared

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 8 : 10) {
                ForEach(Mood.allCases) { mood in
                    MoodPill(
                        mood: mood,
                        selected: selected == mood,
                        compact: compact
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selected = mood
                        }
                        haptics.selectionChange()
                        onSelect?(mood)
                    }
                }
            }
            .padding(.vertical, compact ? 2 : 4)
            .padding(.horizontal, 2)
        }
        .tint(theme.accentColor)
    }
}

// MARK: - Subviews

private struct MoodPill: View {
    let mood: Mood
    let selected: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: compact ? 6 : 8) {
                Image(systemName: mood.icon)
                    .font(.system(size: compact ? 13 : 15, weight: .semibold))
                Text(mood.displayName)
                    .font(compact ? Typography.caption : Typography.bodyMedium)
                    .lineLimit(1)
            }
            .padding(.vertical, compact ? 6 : 8)
            .padding(.horizontal, compact ? 10 : 12)
            .background(
                ZStack {
                    if selected {
                        mood.gradient
                    } else {
                        Color(.systemFill)
                    }
                }
            )
            .foregroundStyle(selected ? Color.white : Color.primary.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? Color.white.opacity(0.35) : Color.black.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(mood.displayName)
            .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
struct MoodPickerView_Previews: PreviewProvider {
    @State static var current: Mood? = .calm
    static var previews: some View {
        MoodPickerView(selected: $current)
            .environmentObject(AppTheme())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
