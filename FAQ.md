# Frequently Asked Questions

## General Questions

### What is UniFlow?

UniFlow is a Swift implementation of the BLoC (Business Logic Component) pattern for state management in Swift applications. It provides a predictable way to manage state by separating business logic from UI code.

### Is UniFlow compatible with SwiftUI?

Yes! UniFlow has first-class support for SwiftUI with components like `BlocProvider`, `BlocBuilder`, `BlocListener`, and property wrappers like `@BlocProperty`.

### Does UniFlow work with UIKit?

Absolutely! UniFlow works seamlessly with UIKit. You can use Blocs and Cubits directly in your view controllers and subscribe to state changes using Combine.

### What platforms does UniFlow support?

UniFlow supports:
- iOS 13+
- macOS 10.15+
- tvOS 13+
- watchOS 6+

### Do I need to learn a new architecture pattern?

If you're familiar with MVVM, MVP, or other unidirectional data flow architectures, you'll find UniFlow intuitive. If you've used flutter_bloc or similar BLoC implementations, you'll feel right at home.

### Is UniFlow open source?

Yes! UniFlow is released under the MIT license. See the LICENSE file for details.

## Comparison Questions

### How does UniFlow compare to Combine?

Combine is a powerful reactive framework, but it can have a steep learning curve and boilerplate code for simple state management. UniFlow builds on Combine concepts but provides a more opinionated, easy-to-use architecture specifically designed for state management with the BLoC pattern.

### How does UniFlow compare to RxSwift?

RxJS and RxSwift are powerful reactive extensions, but they come with significant complexity and learning overhead. UniFlow provides a simpler, more focused solution for state management while still leveraging reactive concepts under the hood.

### How does UniFlow compare to Redux/ReSwift?

While Redux-inspired architectures like ReSwift are excellent for certain applications, they can be verbose and require significant boilerplate. UniFlow offers a more lightweight approach with less ceremonial code while maintaining predictable state transitions.

### How does UniFlow compare to @StateObject/@ObservableObject?

SwiftUI's built-in state management is great for simple UI state, but it doesn't scale well for complex business logic or when you need to share state across multiple views. UniFlow provides a scalable solution that keeps business logic separate from UI concerns.

## Usage Questions

### Should I use Bloc or Cubit?

Use **Cubit** when:
- You have simple state transitions
- You don't need to process complex events
- You want minimal boilerplate
- You're primarily emitting states directly (like a simplified ViewModel)

Use **Bloc** when:
- You need to process complex events (user actions, API responses, etc.)
- Your state transitions depend on previous states or require async operations
- You want to separate event handling from state emission
- You need more sophisticated error handling or loading states

### How do I handle asynchronous operations in a Bloc?

You can perform async operations in your `mapEventToState` method and use `AsyncStream` to emit loading, success, and error states:

```swift
override func mapEventToState(_ event: AppEvent) -> AsyncStream<AppState> {
    return AsyncStream { continuation in
        Task {
            switch event {
            case .loadUser(let userId):
                continuation.yield(.loading)
                do {
                    let user = try await userRepository.fetchUser(id: userId)
                    continuation.yield(.success(user))
                } catch {
                    continuation.yield(.error(error))
                }
                continuation.finish()
            }
        }
    }
```

### How do I prevent infinite loops in my Bloc?

Make sure you're not emitting the same state consecutively in your event handler. You can add guard conditions:

```swift
case .updateFilter(let newFilter):
    guard newFilter != state.filter else {
        // Avoid emitting the same state
        continuation.finish()
        return
    }
    
    let newState = AppState(filter: newFilter, items: state.items)
    continuation.yield(newState)
    continuation.finish()
```

### How do I share state between multiple Blocs?

While direct bloc-to-bloc communication is discouraged (it breaks encapsulation), you can:
1. Have multiple Blocs listen to the same event source
2. Use a shared repository or service that both Blocs depend on
3. Use a parent Bloc that coordinates child Blocs (though this should be used sparingly)

### How do I handle navigation with UniFlow?

Use `BlocListener` to respond to state changes that should trigger navigation:

```swift
BlocListener(authBloc) { state in
    if case .authenticated(let user) = state {
        navigator.navigateToHome(user: user)
    }
} child: {
    LoginView()
}
```

### How do I reset a Bloc to its initial state?

You can either:
1. Create a new instance of the Bloc (using `BlocProvider` with a factory)
2. Add a specific "reset" event that returns the initial state
3. Expose a public method on your Bloc to reset state (less common)

## Troubleshooting

### My Bloc isn't updating the UI

Check that:
1. Your state conforms to `Equatable` (required for Cubit, recommended for Bloc)
2. You're actually emitting a new state (not the same state instance)
3. You're using the correct publisher/subscriber mechanism
4. Your Bloc isn't being deallocated prematurely

### I'm getting memory leaks

Ensure that:
1. You're calling `close()` on your Blocs/Cubits when they're no longer needed
2. In UIKit view controllers, call `close()` in `viewDidDisappear`
3. In SwiftUI, use `@StateObject` or `@EnvironmentObject` to manage the lifecycle
4. You're not retaining strong references to Blocs in closures that outlive the Bloc

### My async operations aren't completing

Verify that:
1. You're using `Task` or `async/await` correctly in your `mapEventToState`
2. You're calling `continuation.finish()` for all code paths
3. You're not accidentally creating infinite task chains

### I'm getting duplicate state updates

This can happen when:
1. You're not checking for state equality before emitting (especially in Cubit)
2. Multiple events are triggering the same state transition
3. You have multiple subscribers unintentionally

Use the `print` operator or breakpoint on state changes to debug the source.

## Performance Questions

### Is UniFlow fast enough for performance-critical applications?

Yes! UniFlow is designed to be lightweight:
- Minimal overhead over raw Combine/AsyncStream
- No unnecessary object allocations
- Efficient change detection
- Optimized for typical UI update frequencies

### How does UniFlow handle rapid state changes?

UniFlow uses Combine's built-in buffering and backpressure handling. For extremely high-frequency updates (like sensor data or animations), consider:
1. Debouncing or throttling rapid changes
2. Coalescing multiple rapid updates into a single meaningful state change
3. Using UIKit/AppKit/Core Animation directly for animations that need 60fps updates

### Does UniFlow work well with large data sets?

For large datasets:
1. Consider using pagination or virtual lists
2. Only load the data needed for the current view
3. Use immutable data structures with structural sharing when possible
4. Consider database-backed solutions for very large datasets

## Advanced Questions

### Can I use UniFlow with Core Data?

Yes! You can:
1. Create a Bloc that observes Core Data changes via `NSFetchedResultsController`
2. Use a Bloc to mediate between Core Data and your UI
3. Create repository classes that encapsulate Core Data operations

### How does UniFlow work with dependency injection?

UniFlow works well with dependency injection:
1. Inject repositories/services into your Blocs/Cubits via constructors
2. Use factory functions with `BlocProvider` for complex initialization
3. Consider using a dependency injection framework like Swinject if needed

### Can I test asynchronous Bloc operations?

Yes! Use XCTestExpectation with Combine's `sink` operator or async/await in Swift 5.5+ tests:

```swift
func testAsyncOperation() async throws {
    // Arrange
    let bloc = DataLoadingBloc()
    
    // Act
    await withCheckedContinuation { continuation in
        var cancellable: AnyCancellable?
        cancellable = bloc.statePublisher
            .dropFirst()
            .sink { state in
                if case .success = state {
                    continuation.resume()
                }
                cancellable?.cancel()
            }
        
        bloc.send(.loadData)
    }
    
    // Assert
    XCTAssertEqual(bloc.state, .success(mockData))
}
```

### How do I handle dependencies between Blocs?

Avoid direct dependencies between Blocs when possible. Instead:
1. Share dependencies through constructor injection (repositories, services)
2. Use a parent Bloc to coordinate child Blocs when absolutely necessary
3. Let each Bloc listen to the same external events (notifications, services, etc.)

If you absolutely need bloc-to-bloc communication:
1. Use it sparingly and document why it's necessary
2. Consider using a mediator pattern
3. Ensure there are no circular dependencies

## Migrating from Other State Management Solutions

### Migrating from MVVM/ViewModels

1. Identify your ViewModel's inputs (actions) and outputs (state)
2. Map inputs to Bloc events
3. Map outputs to Bloc states
4. Move business logic from ViewModel to Bloc's `mapEventToState`
5. Replace ViewModel bindings with BlocBuilder/BlocListener
6. Replace @StateObject/@ObservedObject with BlocProvider

### Migrating from Redux/ReSwift

1. Map your actions to Bloc events
2. Map your state properties to Bloc state structs
3. Convert your reducers to Bloc event handlers
4. Replace store subscriptions with BlocBuilder/BlocListener
5. Remove middleware concerns (handle them in your Bloc instead)

### Migrating from Composable Architecture (TCA)

1. Map your actions to Bloc events
2. Map your state to Bloc state structs
3. Convert your reducers to Bloc event handlers
4. Replace store observers with BlocBuilder/BlocListener
5. Replace effects with async operations in your Bloc's event handlers

## Contributing

If you'd like to contribute to the FAQ:
1. Check if your question is already answered
2. Submit a pull request with your question and answer
3. Or open an issue suggesting a new FAQ entry

We're constantly improving this document based on community feedback!