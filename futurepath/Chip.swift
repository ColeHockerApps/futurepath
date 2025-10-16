
//
//  Chip.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// A minimal, reusable chip component (pill-style button) used across the app.
/// Can display text and/or icon, supports selection and color customization.
struct Chip: View {

    // MARK: - Configuration

    let title: String?
    let systemIcon: String?
    let selected: Bool
    let color: Color
    let action: () -> Void

    // MARK: - Layout options

    var compact: Bool = false
    var showBorder: Bool = true

    // MARK: - Environment

    @EnvironmentObject private var theme: AppTheme

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: compact ? 6 : 8) {
                if let systemIcon = systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: compact ? 13 : 15, weight: .semibold))
                }
                if let title = title {
                    Text(title)
                        .font(compact ? Typography.caption : Typography.bodySmall)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, compact ? 6 : 8)
            .padding(.horizontal, compact ? 10 : 12)
            .foregroundStyle(selected ? Color.white : theme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? color : Color(.systemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        showBorder ? (selected ? color.opacity(0.4) : Color.black.opacity(0.08)) : .clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(title ?? "Chip")
        .accessibilityAddTraits(.isButton)
    }
}

#if DEBUG
struct Chip_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            Chip(
                title: "Focused",
                systemIcon: "bolt.fill",
                selected: true,
                color: ColorPalette.brandBlue,
                action: {}
            )
            .environmentObject(AppTheme())

            Chip(
                title: "Calm",
                systemIcon: "leaf.fill",
                selected: false,
                color: ColorPalette.brandGreen,
                action: {}
            )
            .environmentObject(AppTheme())

            Chip(
                title: "Compact",
                systemIcon: "flame.fill",
                selected: false,
                color: ColorPalette.brandCoral,
                action: {},
                compact: true
            )
            .environmentObject(AppTheme())
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
