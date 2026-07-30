//  State.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import Foundation

/// A marker protocol for the state a `Bloc` or `Cubit` holds and emits.
///
/// Conform your own state type — typically a `struct` with `let` properties —
/// to `StateProtocol`. Additionally conforming to `Equatable` lets `Cubit`
/// skip emitting a state that's identical to the current one:
///
/// ```swift
/// struct CounterState: StateProtocol, Equatable {
///     let count: Int
/// }
/// ```
public protocol StateProtocol: Sendable { }

/// A state type with no data, useful as a placeholder or initial state.
public struct EmptyState: StateProtocol { }