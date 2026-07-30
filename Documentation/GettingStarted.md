# Getting Started with UniFlow

This guide will help you get started with UniFlow, a Swift implementation of the BLoC (Business Logic Component) pattern for state management.

## Installation

### Swift Package Manager

1. Open your Xcode project
2. Go to File > Add Packages...
3. Enter the repository URL: `https://github.com/yourusername/UniFlow.git`
4. Select the version you want to use
5. Choose which targets to add the package to
6. Click "Add Package"

### Manual Installation

If you prefer not to use Swift Package Manager, you can manually add the UniFlow sources to your project:

1. Download or clone this repository
2. Copy the `Sources/UniFlow` folder to your project
3. Add the files to your Xcode target

## Core Concepts

### Events and States

In UniFlow, everything flows from events to states:

- **Events**: Represent user actions or system occurrences (button presses, API responses, etc.)
- **States**: Represent the UI state at a particular moment in time

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

### Blocs and Cubits

- **Bloc**: Processes events and emits states. Ideal for complex business logic.
- **Cubit**: A simplified version that only requires emitting states. Perfect for simple state transitions.

#### Creating a Bloc

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

#### Creating a Cubit

```swift
class CounterCubit: Cubit<CounterState> {
    init() {
        super.init(initialState: CounterState.initial)
    }
    
    func increment() {
        emit(CounterState(count: state.count + 1))
    }
    
    func decrement() {
        emit(CounterState(count: state.count - 1))
    }
    
    func reset() {
        emit(CounterState.initial)
    }
}
```

## Usage with SwiftUI

### Providing a Bloc/Cubit

Use `BlocProvider` to provide your Bloc or Cubit to the widget tree:

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

### Building UI with BlocBuilder

`BlocBuilder` automatically rebuilds your UI when the state changes:

```swift
struct CounterView: View {
    @StateObject private var bloc = CounterBloc()
    
    var body: some View {
        VStack {
            Text("Count: \(bloc.state.count)")
                .font(.largeTitle)
            
            HStack {
                Button("−") { bloc.send(.decrement) }
                Button("+") { bloc.send(.increment) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

Alternatively, get the Bloc from the environment:

```swift
struct CounterView: View {
    @EnvironmentObject var bloc: CounterBloc
    
    var body: some View {
        BlocBuilder(bloc) { state in
            Text("Count: \(state.count)")
                .font(.largeTitle)
        }
    }
}
```

### Handling Side Effects with BlocListener

Use `BlocListener` to perform side effects like navigation, showing dialogs, or analytics:

```swift
BlocListener(bloc) { state in
    if state.count >= 10 {
        // Show achievement badge
        showAchievementBadge()
    }
} child: {
    CounterView()
}
```

### Direct Access with @BlocProperty

Access your bloc directly in SwiftUI views:

```swift
struct CounterView: View {
    @BlocProperty(CounterBloc.self) var bloc
    
    var body: some View {
        VStack {
            Text("Count: \(bloc.state.count)")
                .font(.largeTitle)
            
            Button("Increment") {
                bloc.send(.increment)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## Usage with UIKit

### Providing a Bloc/Cubit

In your view controller's `viewDidLoad`:

```swift
class CounterViewController: UIViewController {
    private let counterBloc = CounterBloc()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindBloc()
    }
    
    private func bindBloc() {
        // Subscribe to state changes
        cancellable = counterBloc.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.countLabel.text = "\(state.count)"
            }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        counterBloc.close() // Clean up resources
    }
}
```

### Handling Events

Connect your UI controls to send events to the bloc:

```swift
@objc private func incrementTapped() {
    counterBloc.send(.increment)
}

@objc private func decrementTapped() {
    counterBloc.send(.decrement)
}

@objc private func resetTapped() {
    counterBloc.send(.reset)
}
```

## Testing

### Testing Blocs

```swift
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
        
        // Act
        bloc.$state
            .sink { state in
                if state.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        bloc.send(.increment)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        super.tearDown()
    }
}
```

### Testing Cubits

```swift
final class CounterCubitTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = .init()
    }
    
    func testCounterIncrements() {
        // Arrange
        let cubit = CounterCubit()
        let expectation = self.expectation(description: "Wait for state update")
        
        // Act
        cubit.statePublisher
            .dropFirst()
            .sink { state in
                if state.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        cubit.increment()
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        super.tearDown()
    }
}
```

## Best Practices

1. **Keep Blocs focused**: Each Bloc should have a single responsibility
2. **Keep events minimal**: Events should describe what happened, not how to respond
3. **Make states immutable**: Use `let` properties in your state structs
4. **Close Blocs/Cubits**: Always close them when no longer needed to prevent memory leaks
5. **Use Cubit for simple cases**: If you don't need event processing, use Cubit instead of Bloc
6. **Test your business logic**: Blocs and Cubits are easy to test in isolation
7. **Separate concerns**: Keep UI code in views, business logic in Blocs/Cubits

## Common Patterns

### Loading State

```swift
enum AppState: State {
    case loading
    case success(Data)
    case failure(Error)
}

// In your Bloc
case .loadData:
    continuation.yield(.loading)
    // Fetch data...
    if let data = fetchedData {
        continuation.yield(.success(data))
    } else {
        continuation.yield(.failure(error))
    }
    continuation.finish()
```

### Form Validation

```swift
enum FormEvent: Event {
    case emailChanged(String)
    case passwordChanged(String)
    case submitAttempted
}

struct FormState: State {
    let email: String
    let password: String
    let isEmailValid: Bool
    let isPasswordValid: Bool
    let isSubmitting: Bool
    let submitResult: Result<Void, Error>?
}

// In your Bloc
case .emailChanged(let email):
    let isEmailValid = isValidEmail(email)
    let newState = FormState(
        email: email,
        password: state.password,
        isEmailValid: isEmailValid,
        isPasswordValid: state.isPasswordValid,
        isSubmitting: state.isSubmitting,
        submitResult: state.submitResult
    )
    continuation.yield(newState)
    continuation.finish()
```

## Troubleshooting

### "Publisher is already subscribed to" Error

This usually happens when you're trying to subscribe to a bloc's publisher multiple times in SwiftUI. Use `@StateObject` or `@EnvironmentObject` to ensure the bloc is instantiated only once.

### Memory Leaks

Always call `close()` on your Blocs and Cubits when they're no longer needed, especially in UIKit view controllers' `viewDidDisappear`.

### State Not Updating

Make sure:
1. You're actually emitting new states (not the same state)
2. Your state struct conforms to `Equatable` (for Cubit's duplicate state prevention)
3. You're using the correct publisher (`$state` for Combine, `statePublisher` for AsyncStream)

## Next Steps

- Check out the [Examples](./Examples) directory for complete sample applications
- Read the [API Documentation](https://yourusername.github.io/UniFlow/documentation/uniflow/)
- Look at the [CHANGELOG](CHANGELOG.md) for recent changes
- Join the [Discussions](https://github.com/yourusername/UniFlow/discussions) to ask questions and share ideas

## Support

If you encounter any issues or have questions, please:
1. Check the [FAQ](FAQ.md)
2. Search existing [Issues](https://github.com/yourusername/UniFlow/issues)
3. Open a new issue if needed

Happy coding with UniFlow! 🚀