# UniFlow

![Swift](https://img.shields.io/badge/swift-5.5+-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)

A Swift implementation of the BLoC (Business Logic Component) pattern for state management in SwiftUI and UIKit applications.

## Overview

UniFlow is a predictable state management library that helps you implement the BLoC pattern in your Swift applications. It separates business logic from UI, making your code easier to test, maintain, and reuse.

Inspired by [flutter_bloc](https://github.com/felangel/bloc), UniFlow brings the power of BLoC to the Swift ecosystem with first-class support for SwiftUI and UIKit.

## Features

- 🔄 Predictable state management using streams
- 🍓 First-class SwiftUI support with property wrappers and view builders
- 📱 UIKit compatibility
- 🧪 Easy to test business logic in isolation
- 🔧 Minimal boilerplate
- 📦 Zero dependencies
- 📚 Comprehensive documentation and examples

## Installation

### Swift Package Manager

Add UniFlow to your package dependencies in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/UniFlow.git", from: "1.0.0")
]
```

Or through Xcode:
1. File > Add Packages...
2. Enter `https://github.com/yourusername/UniFlow.git`
3. Select the version and add to your target

## Quick Start

### Define Events and States

```swift
// Define your events
enum CounterEvent: Event {
    case increment
    case decrement
    case reset
}

// Define your states
struct CounterState: State {
    let count: Int
    
    static let initial = CounterState(count: 0)
}
```

### Create a Bloc

```swift
import UniFlow

class CounterBloc: Bloc<CounterEvent, CounterState> {
    init() {
        super.init(initialState: CounterState.initial)
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
                let newState = CounterState.initial
                continuation.yield(newState)
                continuation.finish()
            }
        }
    }
}
```

### Use with SwiftUI

```swift
@main
struct CounterApp: App {
    var body: some Scene {
        WindowGroup {
            BlocProvider(CounterBloc()) {
                CounterView()
            }
        }
    }
}

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
            }
            
            HStack(spacing: 16) {
                Button(action: { bloc.send(.decrement) }) {
                    Text("-")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: { bloc.send(.reset) }) {
                    Text("Reset")
                        .font(.title2)
                        .frame(width: 80, height: 50)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: { bloc.send(.increment) }) {
                    Text("+")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .padding()
    }
}
```

## Documentation

For more detailed documentation, please visit our [GitHub Wiki](https://github.com/yourusername/UniFlow/wiki).

## Examples

Check out the [Examples](./Examples) directory for complete sample applications:
- [Counter Example](./Examples/CounterExample) - A simple counter demonstrating basic Bloc usage
- [Todo Example](./Examples/TodoExample) - A todo app showing more complex state management
- [Login Example](./Examples/LoginExample) - A login form with validation

## Testing

Testing business logic is straightforward with UniFlow:

```swift
import XCTest
@testable import UniFlow

final class CounterBlocTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = .init()
    }
    
    func testCounterIncrements() {
        // Arrange
        let bloc = CounterBloc()
        let expectation = self.expectation(description: "Wait for state update")
        var receivedStates: [CounterState] = []
        
        // Act
        bloc.$state
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        bloc.send(.increment)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStates.last?.count, 1)
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        super.tearDown()
    }
}
```

## Architecture

```
┌─────────────────┐    Events    ┌────────────┐    States    ┌──────────────┐
│                 │◄ ―                      │            │◄                  │              │
│     UI Layer    │              │   Bloc     │              │   State      │
│                 │                       ►            │                  ►              │
└─────────────────┘              └────────────┘┊            └──────────────┘
                                               │
                                               ▼
                                       ┌─────────────┐
                                       │             │
                                       │ Repository  │
                                       │             │
                                       └─────────────┘
```

## Platform Support

- iOS 13+
- macOS 10.15+
- tvOS 13+
- watchOS 6+

## Requirements

- Swift 5.5+
- Xcode 13+

## License

UniFlow is available under the MIT license. See the LICENSE file for more info.

## Inspiration

This library is heavily inspired by:
- [flutter_bloc](https://github.com/felangel/bloc) by Felix Angelov
- The BLoC pattern philosophy of separation of concerns
- Swift's Combine framework and AsyncSequence

## Contributing

We welcome contributions to UniFlow! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Contact

Your Name - [your website or contact info]

Project Link: [https://github.com/yourusername/UniFlow](https://github.com/yourusername/UniFlow)