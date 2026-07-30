# Getting Started with UniFlow

This guide will help you get started with UniFlow, a Swift implementation of the BLoC (Business Logic Component) pattern for state management.

## Installation

### Swift Package Manager

Add UniFlow as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anil291987/UniFlow.git", branch: "main")
]
```

Or in Xcode: **File > Add Package Dependencies...** and enter the repository URL above.

### Manual Installation

If you prefer not to use Swift Package Manager, copy the `Sources/UniFlow` folder into your project and add its files to your target.

## Core Concepts

### Events and States

In UniFlow, everything flows from events to states:

- **Events**: Represent user actions or system occurrences (button presses, API responses, etc.). Conform to the `Event` protocol.
- **States**: Represent the UI state at a particular moment in time. Conform to the `StateProtocol` protocol (and typically `Equatable`, since `Cubit` uses it to skip redundant emissions).

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

### Blocs and Cubits

- **`Bloc`**: Processes events through `mapEventToState` and emits states. Ideal for complex business logic.
- **`Cubit`**: A simplified version that only requires calling `emit()` with a new state — no event type needed. Perfect for simple state transitions.

#### Creating a Bloc

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

#### Creating a Cubit

```swift
final class CounterCubit: Cubit<CounterState> {
    init() {
        super.init(initialState: CounterState(count: 0))
    }

    func increment() {
        emit(CounterState(count: state.count + 1))
    }

    func decrement() {
        emit(CounterState(count: state.count - 1))
    }

    func reset() {
        emit(CounterState(count: 0))
    }
}
```

## Usage with SwiftUI

### Providing a Bloc/Cubit

Use `BlocProvider` to put your Bloc or Cubit into the environment for the view subtree below it:

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
```

`RepositoryProvider` works the same way for any other `ObservableObject` (a data
repository, a session manager, etc.) that isn't itself a `Bloc`/`Cubit`.

### Building UI with BlocBuilder

`BlocBuilder` rebuilds its content whenever the bloc's state changes. It can take an
explicit bloc instance, or pull one from the environment (as set up by `BlocProvider`):

```swift
// Explicit instance
struct CounterView: View {
    @StateObject private var bloc = CounterBloc()

    var body: some View {
        VStack {
            BlocBuilder(bloc) { state in
                Text("Count: \(state.count)")
                    .font(.largeTitle)
            }
            HStack {
                Button("−") { bloc.send(.decrement) }
                Button("+") { bloc.send(.increment) }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// From the environment (bloc supplied by an ancestor BlocProvider)
struct CounterViewFromEnvironment: View {
    var body: some View {
        BlocBuilder<CounterBloc, Text> { state in
            Text("Count: \(state.count)")
        }
    }
}
```

For `Cubit`, use the `CubitBuilder` typealias the same way.

### Handling Side Effects with BlocListener

Use `BlocListener` to perform side effects — navigation, alerts, analytics — in
response to state changes, without rebuilding the UI yourself. The listener closure
is not called for the initial state, only for state changes after that:

```swift
BlocListener(bloc, listener: { state in
    if state.count >= 10 {
        showAchievementBadge()
    }
}, child: {
    CounterView()
})
```

`CubitListener` is the equivalent typealias for `Cubit`.

## Usage with UIKit

Blocs and Cubits are plain `ObservableObject`s under the hood, so they work outside
SwiftUI too — subscribe to `statePublisher` (a `Combine` publisher) directly:

```swift
final class CounterViewController: UIViewController {
    private let counterBloc = CounterBloc()
    private var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        cancellable = counterBloc.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.countLabel.text = "\(state.count)"
            }
    }

    @objc private func incrementTapped() {
        counterBloc.send(.increment)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancellable?.cancel()
        counterBloc.close() // release the bloc's internal event-processing task
    }
}
```

## Testing

Since `Bloc`/`Cubit` are `@MainActor`-isolated, mark test classes that call their
APIs synchronously (rather than exclusively from within a `Task`) as `@MainActor` too:

```swift
@MainActor
final class CounterCubitTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        cancellables = .init()
    }

    override func tearDown() async throws {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        try await super.tearDown()
    }

    func testCounterIncrements() {
        let cubit = CounterCubit()
        let expectation = self.expectation(description: "Wait for state update")

        cubit.statePublisher
            .dropFirst() // skip the initial state
            .sink { state in
                XCTAssertEqual(state.count, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        cubit.increment()

        wait(for: [expectation], timeout: 1.0)
    }
}
```

See `Tests/UniFlowTests/` in this repository for more complete examples, including how
`BlocBuilder`/`BlocListener` tests actually render via `NSHostingController` to exercise
`body`/`onReceive` for real.

## Best Practices

1. **Keep Blocs/Cubits focused**: each should own one distinct piece of business logic.
2. **Keep events minimal**: describe what happened, not how to respond to it.
3. **Make states immutable**: use `let` properties in your state structs.
4. **Close Blocs/Cubits when done**: call `close()` to release resources, especially in UIKit's `viewDidDisappear`.
5. **Use `Cubit` for simple cases**: reach for `Bloc` only when you need the event/`mapEventToState` pipeline.
6. **Test business logic in isolation**: subscribe to `statePublisher` directly rather than going through SwiftUI.

## Troubleshooting

### State Not Updating

- Make sure you're actually emitting a *new* state — `Cubit.emit(_:)` is a no-op if the new state equals the current one (since `StateType: Equatable`).
- Double-check you're observing `statePublisher` (or the `@Published` `state` property directly on a concrete `Bloc`/`Cubit` instance), not something disconnected from it.

### Actor-Isolation Compiler Errors

`Bloc`, `Cubit`, and `BlocBase` are all `@MainActor`-isolated. If you see errors like
*"call to main actor-isolated ... in a synchronous nonisolated context"*, the calling
code (often a test method) needs to be `@MainActor` itself, or wrapped in
`Task { @MainActor in ... }`.

### Memory Leaks

Always call `close()` on Blocs/Cubits you own once they're no longer needed.

## Next Steps

- Check out the [Examples](../Examples) directory for sample applications (note: these currently need their `Package.swift` layout fixed before they'll build — see the root `CLAUDE.md`)
- Read the [CHANGELOG](../CHANGELOG.md) for recent changes
- See the [FAQ](../FAQ.md) for common questions
