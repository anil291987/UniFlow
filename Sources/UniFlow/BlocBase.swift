//  BlocBase.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import Foundation
import Combine

/// The common interface shared by `Bloc` and `Cubit`.
///
/// Generic SwiftUI plumbing (`BlocProvider`, `BlocBuilder`, `BlocListener`,
/// `CubitProvider`, `CubitBuilder`, `CubitListener`) is written against this
/// protocol rather than the concrete `Bloc`/`Cubit` classes, so it works with
/// either. You won't normally conform to `BlocBase` yourself.
@MainActor
public protocol BlocBase: ObservableObject {
    associatedtype State: StateProtocol
    /// The current state of the bloc/cubit.
    var state: State { get }
    /// Publisher for state changes (useful for SwiftUI)
    var statePublisher: Published<State>.Publisher { get }
}