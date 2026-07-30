# Counter Example

A simple counter application demonstrating the use of UniFlow for state management in SwiftUI.

## Overview

This example shows how to:
- Define events and states
- Create a Bloc that handles events and emits states
- Use BlocBuilder to rebuild the UI when state changes
- Use BlocListener to handle side effects
- Integrate UniFlow with SwiftUI using BlocProvider

## Running the Example

1. Make sure you have Xcode 13 or later installed
2. Open `CounterExample/Package.swift` in Xcode
3. Build and run the project

## Code Overview

### Events
```swift
enum CounterEvent: Event {
    case increment
    case decrement
    case reset
}
```

### States
```swift
struct CounterState: State, Equatable {
    var count: Int = 0
}
```

### Bloc Implementation
```swift
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
```

### SwiftUI View
```swift
struct CounterView: View {
    @StateObject private var bloc = CounterBloc()

    var body: some View {
        VStack(spacing: 20) {
            // Other UI elements...
            
            BlocBuilder(bloc) { state in
                Text("Count: \(state.count)")
                    .font(.largeTitle)
                    .padding()
            }
            
            // Buttons to send events
            HStack(spacing: 16) {
                Button(action: { bloc.send(.decrement) }) {
                    Text("-")
                }
                
                Button(action: { bloc.send(.reset) }) {
                    Text("Reset")
                }
                
                Button(action: { bloc.send(.increment) }) {
                    Text("+")
                }
            }
            
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
```

## Key Concepts Demonstrated

1. **BlocBuilder**: Automatically rebuilds UI when state changes
2. **BlocListener**: Executes side effects in response to state changes
3. **Event handling**: Sending events to Bloc using `bloc.send()`
4. **State management**: Separating UI state from business logic

This example demonstrates the core principles of UniFlow while keeping the implementation simple and easy to understand.