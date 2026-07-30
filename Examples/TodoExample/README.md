# Todo Example

A Todo application demonstrating more advanced UniFlow concepts including:
- Complex state management with filtering
- Multiple event types
- Derived state computation
- List manipulation
- Persistence concepts (in-memory in this example)

## Features

- Add, toggle, and delete todos
- Mark all todos as complete/incomplete
- Filter todos (all, active, completed)
- Clear completed todos
- Dynamic item count

## Implementation Details

### State Management

The Todo example demonstrates how to manage complex state with multiple properties:

```swift
struct TodoState: StateProtocol, Equatable {
    var todos: [TodoItem] = []
    var filter: Filter = .all

    enum Filter: String, CaseIterable {
        case all, active, completed
    }

    // Computed properties for derived state
    var activeTodos: [TodoItem] { /* ... */ }
    var completedTodos: [TodoItem] { /* ... */ }
    var filteredTodos: [TodoItem] { /* ... */ }
    var activeCount: Int { /* ... */ }
}
```

### Event Handling

The Bloc handles various user interactions through distinct event types:

```swift
enum TodoEvent: Event {
    case addTodo(String)
    case toggleTodo(UUID)
    case deleteTodo(UUID)
    case toggleAll
    case clearCompleted
    case setFilter(TodoState.Filter)
}
```

Each event is processed immutably, creating new state instances rather than mutating existing state.

### Derived State

Instead of storing all possible UI states, the TodoBloc calculates derived properties:
- `activeTodos`: Todos that are not completed
- `completedTodos`: Todos that are completed  
- `filteredTodos`: Todos based on current filter
- `activeCount`: Number of active todos for display

This approach prevents state synchronization issues and keeps the single source of truth principle.

## Running the Example

1. Make sure you have Xcode 13 or later installed
2. Open `TodoExample/Package.swift` in Xcode
3. Build and run the project

Or from the command line: `swift run` (or `swift build && swift test` to run the tests).

## Testing

`Tests/TodoExampleUITests/` holds `XCUIApplication`-based UI tests exercising the real
app (accessibility identifiers `newTodoTextField`, `addTodoButton`, `activeCountLabel`,
`filterPicker`, `clearCompletedButton`, and per-row `toggleButton-<title>`/
`todoLabel-<title>`/`deleteButton-<title>`). **These cannot run under `swift test`** —
SwiftPM only produces XCTest *unit*-test bundles, and macOS refuses to let
`XCUIApplication` run outside a proper Xcode UI Testing Bundle target ("Device is not
configured for UI testing"). Under `swift test` they no-op via `XCTSkip` unless
`TODOEXAMPLE_APP_BUNDLE` is set, in which case they fail with that same error — they're
kept here as a documented, ready-to-port reference, not a runnable suite. To actually run
them, wrap this target in an Xcode project with a UI Testing Bundle target, point it at
the app target, and run via Xcode or `xcodebuild test`. `scripts/build-app-bundle.sh`
wraps the SwiftPM-built executable into a minimal `.app` bundle for manual/exploratory
driving with `XCUIApplication(url:)` if you want to experiment outside Xcode.

## Learning Points

This example illustrates several advanced UniFlow concepts:

1. **Complex State Objects**: Managing state with multiple interrelated properties
2. **Immutability**: Creating new state instances rather than mutating existing ones
3. **Derived State**: Computing UI-relevant values from core state to prevent inconsistency
4. **Event-Driven Updates**: All state changes flow through explicit events
5. **Separation of Concerns**: UI concerns (filtering, display) are separated from business logic

The Todo example scales well to more complex applications while maintaining predictable state transitions and testable business logic.