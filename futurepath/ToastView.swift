//
//  ToastView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Lightweight toast notification for transient in-app messages.
/// Appears at bottom and automatically dismisses after a delay.
struct ToastView: View {

    // MARK: - Configuration

    enum Style {
        case info
        case success
        case warning
        case error

        var icon: String {
            switch self {
            case .info:     return "info.circle"
            case .success:  return "checkmark.circle.fill"
            case .warning:  return "exclamationmark.triangle.fill"
            case .error:    return "xmark.octagon.fill"
            }
        }

        var color: Color {
            switch self {
            case .info:     return ColorPalette.brandBlue
            case .success:  return ColorPalette.brandGreen
            case .warning:  return ColorPalette.brandYellow
            case .error:    return ColorPalette.brandCoral
            }
        }
    }

    // MARK: - Inputs

    let style: Style
    let message: String
    var duration: TimeInterval = 2.2
    var onDismiss: (() -> Void)? = nil

    // MARK: - Internal state

    @State private var isVisible: Bool = false

    // MARK: - Body

    var body: some View {
        VStack {
            Spacer()
            if isVisible {
                HStack(spacing: 10) {
                    Image(systemName: style.icon)
                        .font(.system(size: 18, weight: .semibold))
                    Text(message)
                        .font(Typography.bodySmall)
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(
                    Capsule()
                        .fill(style.color.gradient)
                        .shadow(color: style.color.opacity(0.35), radius: 6, x: 0, y: 3)
                )
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isVisible)
                .onAppear(perform: autoDismiss)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
    }

    // MARK: - Behavior

    private func autoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation { isVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                isVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onDismiss?()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ToastView(style: .success, message: "Task saved successfully!")
            ToastView(style: .error, message: "Failed to load data.")
            ToastView(style: .warning, message: "Network connection unstable.")
            ToastView(style: .info, message: "Welcome back!")
        }
        .previewLayout(.fixed(width: 400, height: 300))
        .background(Color.black.opacity(0.1))
    }
}
#endif
