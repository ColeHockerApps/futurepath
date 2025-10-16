//
//  GradientBackdropView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// A soft animated gradient background used behind key screens.
/// Responds to the current mood or accent color dynamically.
struct GradientBackdropView: View {

    // MARK: - Config

    var mood: Mood?
    var accent: Color?
    var intensity: Double = 0.4

    // MARK: - Animation

    @State private var animate: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            gradientForMood(mood)
                .opacity(intensity)
                .rotationEffect(.degrees(animate ? 360 : 0))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animate)
        }
        .onAppear {
            animate = true
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: - Helpers

    private func gradientForMood(_ mood: Mood?) -> LinearGradient {
        if let m = mood {
            return m.gradient
        }
        if let accent = accent {
            return LinearGradient(
                colors: [
                    accent.opacity(0.9),
                    accent.opacity(0.6),
                    accent.opacity(0.4),
                    accent.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        // fallback neutral gradient
        return LinearGradient(
            colors: [
                ColorPalette.brandBlue.opacity(0.8),
                ColorPalette.brandPurple.opacity(0.6),
                ColorPalette.brandCoral.opacity(0.7),
                ColorPalette.brandGreen.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#if DEBUG
struct GradientBackdropView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GradientBackdropView(mood: .inspired)
        }
        .frame(height: 200)
        .previewLayout(.sizeThatFits)
    }
}
#endif
