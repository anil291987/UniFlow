//  Cubit.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import Foundation
import Combine

/// A simplified `Bloc` that emits new states directly, with no event type or
/// `mapEventToState` pipeline.
///
/// Subclass it and call ``emit(_:)`` from your own methods:
///
/// ```swift
/// final class CounterCubit: Cubit<CounterState> {
///     init() {
///         super.init(initialState: CounterState(count: 0))
///     }
///
///     func increment() {
///         emit(CounterState(count: state.count + 1))
///     }
/// }
/// ```
///
/// Because `StateType` is `Equatable`, emitting a state equal to the current
/// one is a no-op — no redundant `didChange` notification or UI update.
open class Cubit<StateType: StateProtocol & Equatable>: ObservableObject, BlocBase {
    // MARK: - Public Properties

    /// Current state of the cubit
    @Published public private(set) var state: StateType

    /// Publisher for state changes (useful for SwiftUI)
    public var statePublisher: Published<StateType>.Publisher {
        $state
    }

    // MARK: - Initialization

    /// Initialize the cubit with an initial state
    /// - Parameter initialState: The initial state of the cubit
    public init(initialState: StateType) {
        self.state = initialState
        // Notify bloc observer
        blocObserver?.didCreate(self)
    }

    // MARK: - Public Methods

    /// Emit a new state
    /// - Parameter newState: The new state to emit
    @MainActor
    public final func emit(_ newState: StateType) {
        guard newState != state else { return }
        let oldState = state
        state = newState
        // Notify bloc observer of state change
        blocObserver?.didChange(self, previousState: oldState)
    }

    /// Close the cubit and release resources
    public final func close() {
        blocObserver?.didClose(self)
    }

    // MARK: - Bloc Observer

    /// The bloc observer to be notified of lifecycle events.
    /// By default, uses the shared BlocObserver instance.
    open var blocObserver: BlocObserver? = BlocObserverImpl.shared
}