//
//  AnyCancellableBag.swift
//  futurepath
//
//  Created on 2025-10-15
//

import Foundation
import Combine

/// Simple helper for managing Combine subscriptions safely.
/// Instead of manually keeping a `Set<AnyCancellable>`, use `.store(in: bag)` for brevity.
@MainActor
final class AnyCancellableBag {

    // MARK: - Internal storage

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public API

    /// Adds a cancellable to the bag.
    func insert(_ cancellable: AnyCancellable) {
        cancellable.store(in: &cancellables)
    }

    /// Cancels and removes all subscriptions.
    func cancelAll() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    /// Returns the number of active subscriptions.
    var count: Int {
        cancellables.count
    }

    /// Whether there are any subscriptions.
    var isEmpty: Bool {
        cancellables.isEmpty
    }
}

// MARK: - Convenience extension

extension AnyCancellable {
    /// Stores this cancellable in the provided `AnyCancellableBag`.
    func store(in bag: AnyCancellableBag) {
        bag.insert(self)
    }
}

#if DEBUG
struct AnyCancellableBag_Debug {
    static func test() {
        let bag = AnyCancellableBag()
        let publisher = Just("Hello").delay(for: 0.5, scheduler: DispatchQueue.main)
        publisher
            .sink { print("Received:", $0) }
            .store(in: bag)
        print("Bag count:", bag.count)
    }
}
#endif
