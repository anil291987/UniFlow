# UniFlow

A Swift implementation of the BLoC (Business Logic Component) pattern for state management in SwiftUI and UIKit applications.

## Using Claude Code

You can use Claude Code to help with development:

- Use `/help` to see available commands.
- Use `/doc` to generate documentation.
- Use `/test` to run tests.
- Use `/code-review` to review changes.
- Use `/simplify` to simplify code.
- Use `/plan` to create a plan for implementing features.

For more information, see the [Claude Code documentation](https://docs.anthropic.com/claude/docs/claude-code).

## Project Structure

- `Sources/`: Contains the main library code.
- `Tests/`: Contains unit tests.
- `Examples/`: Contains example applications.
- `Documentation/`: Additional documentation.

## Swift/Bloc Development Best Practices

### Bloc Design Principles
- **Single Responsibility**: Each Bloc should handle one distinct aspect of business logic
- **Stateless Events**: Events should be immutable data classes/structs representing user actions or system events
- **Immutable States**: States should be immutable data structures representing the UI state
- **Unidirectional Flow**: Events → Bloc (mapEventToState) → States → UI → Events
- **No UI Dependencies**: Blocs should never reference UI components directly

### Event Design
- Make events enum cases with associated values when needed
- Keep events minimal and focused on user intent
- Consider using structs instead of enums for complex events with multiple parameters
- Avoid putting UI-specific data in events

### State Design
- Make states structs with `let` properties (immutable)
- Derive state from previous state + event, never from external sources
- Consider using `Equatable` conformance to prevent unnecessary UI updates
- Include loading/error states explicitly in your state hierarchy

### Stream Management
- Close streams properly in `onClose()` or equivalent cleanup
- Avoid doing heavy computation in `mapEventToState` - offload to background when needed
- Use `AsyncStream` correctly - remember to call `continuation.finish()` when done
- Handle errors gracefully in your event mapping

## UniFlow-Specific Guidelines

### Bloc Implementation
- Always call `super.init(initialState:)` in your Bloc init
- Override `mapEventToState` to transform events to states
- Use `emit()` method to add new states to the stream
- Override `onChange()` to observe state changes (for logging/analytics)
- Override `onEvent()` to observe incoming events
- Override `onClose()` to clean up resources

### State Management
- Provide a clear `initialState` static property or computed property
- Consider making states `Equatable` for efficient UI updates
- Use `@MainActor` for Blocs that will be used from SwiftUI (when needed)
- For complex state transitions, consider using a dedicated state reducer function

### SwiftUI Integration
- Use `@StateObject` for Blocs that should live as long as the owning view
- Use `@ObservedObject` when passing Blocs down to child views
- Consider creating custom ViewModifiers for common Bloc patterns
- Remember that `@StateObject` won't recreate the Bloc when the view recreates

### UIKit Integration
- Use Blocs as properties in ViewControllers/ViewModels
- Subscribe to stream in `viewDidLoad()` and unsubscribe in `deinit`
- Consider using Combine or RxSwift bridges if needed
- Remember to handle threading - UI updates must happen on main thread

## Testing Strategies for UniFlow

### Unit Testing Blocs
- Test event-to-state transformation in isolation
- Use `await` to collect values from the AsyncStream
- Test edge cases: empty event streams, rapid events, error conditions
- Mock any dependencies injected into your Bloc
- Test that `onChange` and `onEvent` callbacks work correctly

### Integration Testing
- Test Bloc interactions with actual SwiftUI views
- Verify that state changes trigger UI updates correctly
- Test navigation and state persistence scenarios
- Consider using snapshot testing for complex UI states

### Testing Best Practices
- Keep Bloc tests focused on business logic, not UI
- Use descriptive test names that specify the event and expected outcome
- Test both positive and negative cases
- Reset any global state between tests

## Claude Code Workflows for Swift Development

### Using /plan for Feature Development
1. Start with `/plan` to outline your Bloc implementation
2. Define events and states first
3. Outline the `mapEventToState` logic
4. Plan any dependencies or services needed
5. Consider testing strategy in your plan

### Using /code-review for UniFlow Code
- Focus on Bloc adherence to BLoC principles
- Check for proper state immutability
- Verify proper stream management and cleanup
- Look for potential retain cycles or memory issues
- Ensure proper threading (UI updates on main thread)

### Using /simplify for UniFlow Code
- Look for complex `mapEventToState` implementations that can be broken down
- Simplify complex state transition logic
- Reduce boilerplate in Bloc implementations
- Simplify event handling with pattern matching

### Common Refactorings for UniFlow
- Extract complex state transition logic to private methods
- Create base Bloc classes for common patterns (loading, error states)
- Extract event handling to separate methods for better readability
- Create utility functions for common state transformations

## Common Patterns and Anti-patterns

### Recommended Patterns
- **Loading States**: Include explicit loading states in your state hierarchy
- **Error Handling**: Use either error states or a separate error stream
- **Pagination**: Include pagination state in your Bloc state (current page, hasMore, etc.)
- **Form Validation**: Create dedicated FormBlocs with field-level validation states
- **Authentication**: Create authentication Blocs that manage user session state

### Anti-patterns to Avoid
- **Putting UI Logic in Blocs**: Blocs**: Don't put view-specific logic (animations, navigation) in Blocs
- **Blocking the Main Thread**: Avoid synchronous network calls or heavy computation in `mapEventToState`
- **Mutable State**: Never mutate state objects directly - always create new instances
- **Overly Complex Events**: Keep events focused on user intent, not UI specifics
- **Memory Leaks**: Always clean up subscriptions, timers, and other resources in `onClose()`

## SwiftUI Specific Tips

### Property Wrappers
- Use `@StateObject` for Blocs owned by a view
- Use `@ObservedObject` for Blocs passed down from parent views
- Consider `@EnvironmentObject` for app-wide Blocs (like authentication)

### View Construction
- Keep views focused on presentation logic only
- Use `BlocBuilder` for rebuilding UI on state changes
- Use `BlocListener` for side effects (navigation, snackbar, etc.)
- Consider creating custom view modifiers for reusable Bloc patterns

### Animation and Transitions
- Handle animations in the view layer, not in Blocs
- Use state changes to trigger view animations
- Consider using `withAnimation` in response to Bloc state changes

## UIKit Specific Tips

### View Controller Integration
- Create Bloc properties in your ViewController
- Subscribe to streams in `viewDidLoad()` and unsubscribe in `deinit`
- Use `weak self` in closures to avoid retain cycles
- Update UI on main thread using `DispatchQueue.main.async` when needed

### Storyboard/XIB Considerations
- Consider using Blocs as properties rather than instantiating in awakeFromNib
- Be careful with outlet connections when using Blocs for view configuration
- Consider using a configurator pattern for complex view setups

## Resources

- [UniFlow Documentation](/Documentation)
- [Examples Directory](/Examples)
- [flutter_bloc](https://github.com/felangel/bloc) - Original Flutter bloc library
- [Apple's Combine Framework Documentation](https://developer.apple.com/documentation/combine)
- [Swift Concurrency Documentation](https://developer.apple.com/documentation/swift/concurrency)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.