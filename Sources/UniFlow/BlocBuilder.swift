//  BlocBuilder.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import SwiftUI

/// A helper class to wrap an optional bloc for @StateObject
@MainActor
private class ExplicitBlocWrapper<B: BlocBase>: ObservableObject {
    var bloc: B?

    init(_ bloc: B? = nil) {
        self.bloc = bloc
    }
}

/// A SwiftUI Widget that rebuilds its UI in response to state changes in a Bloc or Cubit.
///
/// Usage:
///  ```
///  BlocBuilder<CounterBloc, CounterState> { bloc, state in
//      Text("Counter: \(state.counter)")
//  }
//  ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct BlocBuilder<B: BlocBase, Content: View>: View {
    // For explicit bloc instance - we wrap the optional in a class to make it ObservableObject
    @StateObject private var explicitBlocWrapper = ExplicitBlocWrapper<B>()
    // For bloc from environment
    @EnvironmentObject private var environmentBloc: B
    private let builder: (B.State) -> Content

    /// Creates a BlocBuilder that obtains the bloc from the environment.
    /// - Parameter builder: A function that takes the current state and returns a view.
    public init(@ViewBuilder builder: @escaping (B.State) -> Content) {
        self.builder = builder
    }

    /// Creates a BlocBuilder with an explicit bloc instance.
    /// - Parameters:
    ///   - bloc: The bloc to build with.
    ///   - builder: A function that takes the current state and returns a view.
    public init(_ bloc: B, @ViewBuilder builder: @escaping (B.State) -> Content) {
        self.builder = builder
        self.explicitBlocWrapper.bloc = bloc
    }

    private var bloc: B {
        // Return explicit bloc if provided, otherwise environment bloc
        explicitBlocWrapper.bloc ?? environmentBloc
    }

    public var body: some View {
        builder(bloc.state)
    }
}

/// A convenience typealias for building with a Cubit.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public typealias CubitBuilder<StateType: StateProtocol & Equatable, Content: View> = BlocBuilder<Cubit<StateType>, Content>