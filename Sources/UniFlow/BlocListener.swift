//  BlocListener.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import SwiftUI
import Combine

/// A helper class to wrap an optional bloc for @StateObject
@MainActor
private class OptionalBlocWrapper<B: BlocBase>: ObservableObject {
    var bloc: B?

    init(_ bloc: B? = nil) {
        self.bloc = bloc
    }
}

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
    // For explicit bloc instance - we wrap the optional in a class to make it ObservableObject
    @StateObject private var explicitBlocWrapper = OptionalBlocWrapper<B>()
    // For bloc from environment
    @EnvironmentObject private var environmentBloc: B
    private let listener: (B.State) -> Void
    private let child: () -> Content

    /// Creates a BlocListener that listens to the bloc from the environment.
    /// - Parameters:
    ///   - listener: A closure that is called on every state change (excluding the initial state).
    ///   - child: The widget to build when the bloc is in the tree.
    public init(listener: @escaping (B.State) -> Void, @ViewBuilder child: @escaping () -> Content) {
        self.listener = listener
        self.child = child
    }

    /// Creates a BlocListener with an explicit bloc instance.
    /// - Parameters:
    ///   - bloc: The bloc to listen to.
    ///   - listener: A closure that is called on every state change (excluding the initial state).
    ///   - child: The widget to build when the bloc is in the tree.
    public init(_ bloc: B, listener: @escaping (B.State) -> Void, @ViewBuilder child: @escaping () -> Content) {
        self.listener = listener
        self.child = child
        self.explicitBlocWrapper.bloc = bloc
    }

    private var bloc: B {
        // Return explicit bloc if provided, otherwise environment bloc
        explicitBlocWrapper.bloc ?? environmentBloc
    }

    public var body: some View {
        child()
            .onReceive(bloc.statePublisher) { newState in
                self.listener(newState)
            }
    }
}

/// A convenience typealias for listening to a Cubit.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public typealias CubitListener<StateType: StateProtocol & Equatable, CubitContent: View> = BlocListener<Cubit<StateType>, CubitContent>