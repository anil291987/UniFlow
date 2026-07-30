//  BlocBuilder.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import SwiftUI

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
    private enum Source {
        case explicit(B)
        case environment
    }

    private let source: Source
    private let builder: (B.State) -> Content

    /// Creates a BlocBuilder that obtains the bloc from the environment.
    /// - Parameter builder: A function that takes the current state and returns a view.
    public init(@ViewBuilder builder: @escaping (B.State) -> Content) {
        self.source = .environment
        self.builder = builder
    }

    /// Creates a BlocBuilder with an explicit bloc instance.
    /// - Parameters:
    ///   - bloc: The bloc to build with.
    ///   - builder: A function that takes the current state and returns a view.
    public init(_ bloc: B, @ViewBuilder builder: @escaping (B.State) -> Content) {
        self.source = .explicit(bloc)
        self.builder = builder
    }

    public var body: some View {
        switch source {
        case .explicit(let bloc):
            _ExplicitBlocBuilder(bloc: bloc, builder: builder)
        case .environment:
            _EnvironmentBlocBuilder<B, Content>(builder: builder)
        }
    }
}

// MARK: - Private child views
//
// Split into two separate view types so that `@EnvironmentObject` is only ever a
// dynamic property on a view that is actually instantiated for the environment-based
// path. SwiftUI validates every dynamic property of a view when its body runs, even
// branches that go unused, so keeping both wrappers on one view type would crash
// whenever an explicit bloc is supplied without an environmentObject ancestor.

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct _ExplicitBlocBuilder<B: BlocBase, Content: View>: View {
    @ObservedObject var bloc: B
    let builder: (B.State) -> Content

    var body: some View {
        builder(bloc.state)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct _EnvironmentBlocBuilder<B: BlocBase, Content: View>: View {
    @EnvironmentObject var bloc: B
    let builder: (B.State) -> Content

    var body: some View {
        builder(bloc.state)
    }
}

/// A convenience typealias for building with a Cubit.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public typealias CubitBuilder<StateType: StateProtocol & Equatable, Content: View> = BlocBuilder<Cubit<StateType>, Content>
