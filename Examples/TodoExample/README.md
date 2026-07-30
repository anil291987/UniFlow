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
struct TodoState: State {
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

## Learning Points

This example illustrates several advanced UniFlow concepts:

1. **Complex State Objects**: Managing state with multiple interrelated properties
2. **Immutability**: Creating new state instances rather than mutating existing ones
3. **Derived State**: Computing UI-relevant values from core state to prevent inconsistency
4. **Event-Driven Updates**: All state changes flow through explicit events
5. **Separation of Concerns**: UI concerns (filtering, display) are separated from business logic

The Todo example scales well to more complex applications while maintaining predictable state transitions and testable business logic.