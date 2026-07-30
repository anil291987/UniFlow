# UniFlow

![CI](https://github.com/anil291987/UniFlow/actions/workflows/ci.yml/badge.svg)
![Swift](https://img.shields.io/badge/swift-6.2-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)

A Swift implementation of the BLoC (Business Logic Component) pattern for state management in SwiftUI and UIKit applications.

## Overview

UniFlow is a predictable state management library that helps you implement the BLoC pattern in your Swift applications. It separates business logic from UI, making your code easier to test, maintain, and reuse.

Inspired by [flutter_bloc](https://github.com/felangel/bloc), UniFlow brings the power of BLoC to the Swift ecosystem with first-class support for SwiftUI and UIKit.

## Features

- Predictable state management using `AsyncStream`/Combine
- First-class SwiftUI support: `BlocProvider`, `BlocBuilder`, `BlocListener`, `RepositoryProvider`
- UIKit compatibility via Combine's `statePublisher`
- Easy to test business logic in isolation
- Minimal boilerplate
- Zero dependencies

## Installation

### Swift Package Manager

Add UniFlow to your package dependencies in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anil291987/UniFlow.git", branch: "main")
]
```

Or through Xcode: **File > Add Package Dependencies...** and enter the repository URL above.

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
struct CounterState: StateProtocol, Equatable {
    let count: Int
}
```

### Create a Bloc

```swift
import UniFlow

final class CounterBloc: Bloc<CounterEvent, CounterState> {
    init() {
        super.init(initialState: CounterState(count: 0))
    }

    override func mapEventToState(_ event: CounterEvent) -> AsyncStream<CounterState> {
        return AsyncStream { continuation in
            switch event {
            case .increment:
                continuation.yield(CounterState(count: state.count + 1))

            case .decrement:
                continuation.yield(CounterState(count: state.count - 1))

            case .reset:
                continuation.yield(CounterState(count: 0))
            }
            continuation.finish()
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

- **[Wiki](https://github.com/anil291987/UniFlow/wiki)** — Getting Started, Architecture, Testing, and FAQ
- [Getting Started guide](Documentation/GettingStarted.md) (same content, versioned alongside the code)
- [CHANGELOG](CHANGELOG.md)

## Examples

Check out the [Examples](./Examples) directory:
- [Counter Example](./Examples/CounterExample) — a simple counter demonstrating basic Bloc usage
- [Todo Example](./Examples/TodoExample) — a todo app showing more complex state management

> **Note:** these example packages currently need their `Package.swift` layout fixed
> (sources need to live under `Sources/<TargetName>/`) before they'll build as-is.

## Testing

Since `Bloc`/`Cubit` are `@MainActor`-isolated, mark test classes that call their APIs
synchronously as `@MainActor`:

```swift
import XCTest
import Combine
@testable import UniFlow

@MainActor
final class CounterBlocTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        cancellables = .init()
    }

    func testCounterIncrements() {
        // Arrange
        let bloc = CounterBloc()
        let expectation = self.expectation(description: "Wait for state update")
        var receivedStates: [CounterState] = []

        // Act
        bloc.statePublisher
            .dropFirst() // skip the initial state
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        bloc.send(.increment)

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStates.last?.count, 1)
    }

    override func tearDown() async throws {
        cancellables.forEach { $0.cancel() }
        try await super.tearDown()
    }
}
```

## Architecture

Events flow into a `Bloc`, which transforms them into new states via `mapEventToState`;
the UI observes those states and reacts, and events triggered by the UI complete the
loop. A `Cubit` is a simpler variant that skips events entirely — you call `emit(_:)`
with a new state directly.

```
Events ──▶ Bloc (mapEventToState) ──▶ States ──▶ UI
  ▲                                                │
  └────────────────────────────────────────────────┘
```

See the [Architecture wiki page](https://github.com/anil291987/UniFlow/wiki/Architecture)
for how the pieces in `Sources/UniFlow/` fit together.

## Platform Support

- iOS 13+
- macOS 10.15+
- tvOS 13+
- watchOS 6+

## Requirements

- Swift 6.2+
- Xcode 16+ (or a toolchain supporting `swift-tools-version: 6.2`)

## License

UniFlow is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

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
