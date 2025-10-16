//
//  EmptyStateView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Reusable empty-state view with icon, title, message, and optional primary action.
struct EmptyStateView: View {

    // MARK: - Configuration

    var iconSystemName: String = "text.badge.plus"
    var title: String
    var message: String? = nil

    /// Optional primary action button.
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    /// Optional width constraint for consistent layouts.
    var maxWidth: CGFloat? = 600

    // MARK: - Environment

    @EnvironmentObject private var theme: AppTheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconSystemName)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(theme.textSecondary)

            Text(title)
                .font(Typography.bodyMedium)
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)

            if let message = message, !message.isEmpty {
                Text(message)
                    .font(Typography.caption)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(Typography.bodyMedium)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(theme.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: maxWidth)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        let theme = AppTheme()
        VStack(spacing: 16) {
            EmptyStateView(
                title: "Nothing here yet",
                message: "Create your first task to get started."
            )
            .environmentObject(theme)

            EmptyStateView(
                iconSystemName: "calendar.badge.plus",
                title: "No tasks for today",
                message: "Plan something small to build momentum.",
                actionTitle: "Add Task",
                action: {}
            )
            .environmentObject(theme)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
