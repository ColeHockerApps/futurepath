//
//  HapticsManager.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine
import UIKit

/// Centralized manager for light and context-based haptic feedback.
final class HapticsManager {

    static let shared = HapticsManager()
    private init() {}

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // MARK: - Public API

    /// Triggers a light impact feedback.
    func light() {
        impactLight.prepare()
        impactLight.impactOccurred()
    }

    /// Triggers a medium impact feedback.
    func medium() {
        impactMedium.prepare()
        impactMedium.impactOccurred()
    }

    /// Triggers a heavy impact feedback.
    func heavy() {
        impactHeavy.prepare()
        impactHeavy.impactOccurred()
    }

    /// Triggers a selection change feedback.
    func selectionChange() {
        selection.prepare()
        selection.selectionChanged()
    }

    /// Triggers a notification feedback of a given type.
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.prepare()
        notification.notificationOccurred(type)
    }

    /// Plays a soft success haptic feedback.
    func success() {
        notify(.success)
    }

    /// Plays a warning haptic feedback.
    func warning() {
        notify(.warning)
    }

    /// Plays an error haptic feedback.
    func error() {
        notify(.error)
    }
}
