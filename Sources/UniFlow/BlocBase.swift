//  BlocBase.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import Foundation
import Combine

/// A type that represents a Bloc or Cubit, providing access to its state.
@MainActor
public protocol BlocBase: ObservableObject {
    associatedtype State: StateProtocol
    /// The current state of the bloc/cubit.
    var state: State { get }
    /// Publisher for state changes (useful for SwiftUI)
    var statePublisher: Published<State>.Publisher { get }
}