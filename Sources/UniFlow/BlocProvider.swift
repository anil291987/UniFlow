//  BlocProvider.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import SwiftUI

/// A SwiftUI View that provides a Bloc or Cubit to its subtree via `environmentObject`.
///
/// Usage:
/// ```
/// BlocProvider(
///     CounterBloc(initialState: CounterState(counter: 0))
/// ) {
///     CounterView()
/// }
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct BlocProvider<B: BlocBase, Content: View>: View {
    @StateObject private var bloc: B
    private let content: () -> Content

    /// Creates a BlocProvider that creates and holds the bloc.
    /// - Parameters:
    ///   - bloc: A closure that creates the bloc.
    ///   - content: The content to wrap with the bloc provider.
    public init(_ bloc: @autoclosure @escaping () -> B, @ViewBuilder content: @escaping () -> Content) {
        self._bloc = StateObject(wrappedValue: bloc())
        self.content = content
    }

    public var body: some View {
        content()
            .environmentObject(bloc)
    }
}

/// A SwiftUI View that provides a Cubit to its subtree via `environmentObject`.
/// Typealias for BlocProvider where the generic is constrained to Cubit.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public typealias CubitProvider<StateType: StateProtocol & Equatable, Content: View> = BlocProvider<Cubit<StateType>, Content>