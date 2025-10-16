//
//  MoodBadge.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Small visual element representing a mood (icon + gradient background).
/// Used in stats, task lists, and summaries.
struct MoodBadge: View {

    let mood: Mood
    var compact: Bool = false
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            Image(systemName: mood.icon)
                .font(.system(size: compact ? 12 : 14, weight: .semibold))
            if showLabel {
                Text(mood.displayName)
                    .font(compact ? Typography.caption : Typography.bodySmall)
            }
        }
        .padding(.vertical, compact ? 4 : 6)
        .padding(.horizontal, compact ? 8 : 10)
        .background(mood.gradient)
        .foregroundStyle(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        .accessibilityLabel(mood.displayName)
    }
}

#if DEBUG
struct MoodBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            ForEach(Mood.allCases) { mood in
                MoodBadge(mood: mood)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
