//  CounterExampleApp.swift
//  CounterExample
//
//  Created by Claude on 2024-01-01
//

import SwiftUI
import UniFlow

@main
struct CounterExampleApp: App {
    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}

// MARK: - Events

enum CounterEvent: Event {
    case increment
    case decrement
    case reset
}

// MARK: - States

struct CounterState: StateProtocol, Equatable {
    var count: Int = 0

    static func == (lhs: CounterState, rhs: CounterState) -> Bool {
        lhs.count == rhs.count
    }
}

// MARK: - Bloc

class CounterBloc: Bloc<CounterEvent, CounterState> {
    init() {
        super.init(initialState: CounterState())
    }

    override func mapEventToState(_ event: CounterEvent) -> AsyncStream<CounterState> {
        return AsyncStream { continuation in
            switch event {
            case .increment:
                let newState = CounterState(count: state.count + 1)
                continuation.yield(newState)
                continuation.finish()

            case .decrement:
                let newState = CounterState(count: state.count - 1)
                continuation.yield(newState)
                continuation.finish()

            case .reset:
                let newState = CounterState()
                continuation.yield(newState)
                continuation.finish()
            }
        }
    }
}

// MARK: - Views

struct CounterView: View {
    @StateObject private var bloc = CounterBloc()

    var body: some View {
        VStack(spacing: 20) {
            Text("UniFlow Counter Example")
                .font(.title)
                .padding()

            BlocBuilder(bloc) { state in
                Text("Count: \(state.count)")
                    .font(.largeTitle)
                    .padding()
                    .accessibilityIdentifier("countLabel")
            }

            HStack(spacing: 16) {
                Button(action: { bloc.send(.decrement) }) {
                    Text("-")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .accessibilityIdentifier("decrementButton")

                Button(action: { bloc.send(.reset) }) {
                    Text("Reset")
                        .font(.title2)
                        .frame(width: 80, height: 50)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                .accessibilityIdentifier("resetButton")

                Button(action: { bloc.send(.increment) }) {
                    Text("+")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
                .accessibilityIdentifier("incrementButton")
            }
            .padding()

            // Example of BlocListener for side effects
            BlocListener(bloc) { state in
                if state.count >= 5 {
                    print("Counter reached 5 or more!")
                }
                if state.count <= -5 {
                    print("Counter reached -5 or less!")
                }
            } child: {
                EmptyView()
            }
        }
        .padding()
    }
}