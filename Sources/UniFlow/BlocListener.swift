//  BlocListener.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import SwiftUI
import Combine

/// A SwiftUI Widget that invokes a callback in response to state changes in a Bloc or Cubit.
///
/// Usage:
/// ```
/// BlocListener<CounterBloc, CounterState> { bloc, state in
//     // Perform side effects here, e.g., show a toast, navigate, etc.
//     if state.counter >= 10 {
//         showAchievementBadge()
//     }
// } child: {
//     CounterView()
// }
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct BlocListener<B: BlocBase, Content: View>: View {
    private enum Source {
        case explicit(B)
        case environment
    }

    private let source: Source
    private let listener: (B.State) -> Void
    private let child: () -> Content

    /// Creates a BlocListener that listens to the bloc from the environment.
    /// - Parameters:
    ///   - listener: A closure that is called on every state change (excluding the initial state).
    ///   - child: The widget to build when the bloc is in the tree.
    public init(listener: @escaping (B.State) -> Void, @ViewBuilder child: @escaping () -> Content) {
        self.source = .environment
        self.listener = listener
        self.child = child
    }

    /// Creates a BlocListener with an explicit bloc instance.
    /// - Parameters:
    ///   - bloc: The bloc to listen to.
    ///   - listener: A closure that is called on every state change (excluding the initial state).
    ///   - child: The widget to build when the bloc is in the tree.
    public init(_ bloc: B, listener: @escaping (B.State) -> Void, @ViewBuilder child: @escaping () -> Content) {
        self.source = .explicit(bloc)
        self.listener = listener
        self.child = child
    }

    public var body: some View {
        switch source {
        case .explicit(let bloc):
            _ExplicitBlocListener(bloc: bloc, listener: listener, child: child)
        case .environment:
            _EnvironmentBlocListener<B, Content>(listener: listener, child: child)
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
private struct _ExplicitBlocListener<B: BlocBase, Content: View>: View {
    @ObservedObject var bloc: B
    let listener: (B.State) -> Void
    let child: () -> Content

    var body: some View {
        child()
            .onReceive(bloc.statePublisher.dropFirst()) { newState in
                listener(newState)
            }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct _EnvironmentBlocListener<B: BlocBase, Content: View>: View {
    @EnvironmentObject var bloc: B
    let listener: (B.State) -> Void
    let child: () -> Content

    var body: some View {
        child()
            .onReceive(bloc.statePublisher.dropFirst()) { newState in
                listener(newState)
            }
    }
}

/// A convenience typealias for listening to a Cubit.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public typealias CubitListener<StateType: StateProtocol & Equatable, CubitContent: View> = BlocListener<Cubit<StateType>, CubitContent>
