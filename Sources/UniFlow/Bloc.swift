//  Bloc.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import Foundation
import Combine

// MARK: - BlocBase is already defined in BlocBase.swift, Event and StateProtocol in their respective files

/// Abstract base class for Blocs (Business Logic Components): transforms a
/// stream of `EventType` into a stream of `StateType`.
///
/// Subclass it, override ``mapEventToState(_:)``, and call ``send(_:)`` to
/// feed it events:
///
/// ```swift
/// final class CounterBloc: Bloc<CounterEvent, CounterState> {
///     init() {
///         super.init(initialState: CounterState(count: 0))
///     }
///
///     override func mapEventToState(_ event: CounterEvent) -> AsyncStream<CounterState> {
///         AsyncStream { continuation in
///             switch event {
///             case .increment:
///                 continuation.yield(CounterState(count: state.count + 1))
///             case .decrement:
///                 continuation.yield(CounterState(count: state.count - 1))
///             }
///             continuation.finish()
///         }
///     }
/// }
/// ```
///
/// If you don't need event processing — just direct state updates — use
/// ``Cubit`` instead.
@MainActor
open class Bloc<EventType: Event & Sendable, StateType: StateProtocol & Sendable & Equatable>: ObservableObject, BlocBase {
    // MARK: - Public Properties

    /// Current state of the bloc
    @Published public private(set) var state: StateType

    /// Publisher for state changes (useful for SwiftUI)
    public var statePublisher: Published<StateType>.Publisher {
        $state
    }

    // MARK: - Private Properties

    private let _eventStream: AsyncStream<EventType>
    private var _eventContinuation: AsyncStream<EventType>.Continuation
    private var _task: Task<Void, Never>?

    // MARK: - Initialization

    /// Initialize the bloc with an initial state
    /// - Parameter initialState: The initial state of the bloc
    public init(initialState: StateType) {
        // Initialize state on main actor
        self.state = initialState
        var continuation: AsyncStream<EventType>.Continuation!
        _eventStream = AsyncStream { cont in
            continuation = cont
        }
        _eventContinuation = continuation
        setupEventStream()
        // Notify bloc observer
        blocObserver?.didCreate(self)
    }

    // MARK: - Public Methods

    /// Send an event to the bloc
    /// - Parameter event: The event to process
    public final func send(_ event: EventType) {
        Task { [weak self] in
            guard let self = self else { return }
            guard let task = self._task, !task.isCancelled else { return }
            self._eventContinuation.yield(event)
        }
    }

    /// Close the bloc and release resources
    public final func close() {
        _task?.cancel()
        _eventContinuation.finish()
        blocObserver?.didClose(self)
    }

    // MARK: - Protected Methods

    /// Subclasses should override this method to map events to new states
    /// - Parameter event: The event to process
    /// - Returns: An asynchronous stream of new states
    open func mapEventToState(_ event: EventType) -> AsyncStream<StateType> {
        // By default, events don't change state
        let currentState = self.state
        return AsyncStream { continuation in
            continuation.yield(currentState)
            continuation.finish()
        }
    }

    // MARK: - Private Methods

    private func setupEventStream() {
        _task = Task { [weak self] in
            guard let self = self else { return }
            for await event in self._eventStream {
                // Guard against cancellation
                if Task.isCancelled { break }
                // Process event and get new states
                let newStatesStream = self.mapEventToState(event)
                for await newState in newStatesStream {
                    // Update state on main thread for SwiftUI compatibility
                    await MainActor.run {
                        [weak self] in
                        guard let self = self else { return }
                        let oldState = self.state
                        self.state = newState
                        // Notify bloc observer of state change
                        self.blocObserver?.didChange(self, previousState: oldState)
                    }
                }
            }
        }
    }

    // MARK: - Bloc Observer

    /// The bloc observer to be notified of lifecycle events.
    /// By default, uses the shared BlocObserver instance.
    open var blocObserver: BlocObserver? = BlocObserverImpl.shared
}