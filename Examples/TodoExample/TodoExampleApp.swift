//  TodoExampleApp.swift
//  TodoExample
//
//  Created by Claude on 2024-01-01
//

import SwiftUI
import UniFlow

@main
struct TodoExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                TodoListView()
            }
        }
    }
}

// MARK: - Models

struct TodoItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

// MARK: - Events

enum TodoEvent: Event {
    case addTodo(String)
    case toggleTodo(UUID)
    case deleteTodo(UUID)
    case toggleAll
    case clearCompleted
}

// MARK: - States

struct TodoState: State {
    var todos: [TodoItem] = []
    var filter: Filter = .all

    enum Filter: String, CaseIterable {
        case all, active, completed
    }

    var activeTodos: [TodoItem] {
        todos.filter { !$0.isCompleted }
    }

    var completedTodos: [TodoItem] {
        todos.filter { $0.isCompleted }
    }

    var filteredTodos: [TodoItem] {
        switch filter {
        case .all: return todos
        case .active: return activeTodos
        case .completed: return completedTodos
        }
    }

    var activeCount: Int {
        activeTodos.count
    }
}

// MARK: - Bloc

class TodoBloc: Bloc<TodoEvent, TodoState> {
    init() {
        super.init(initialState: TodoState())
    }

    override func mapEventToState(_ event: TodoEvent) -> AsyncStream<TodoState> {
        return AsyncStream { continuation in
            switch event {
            case .addTodo(let title):
                let newTodo = TodoItem(title: title)
                var newState = state
                newState.todos.append(newTodo)
                continuation.yield(newState)
                continuation.finish()

            case .toggleTodo(let id):
                var newState = state
                if let index = newState.todos.firstIndex(where: { $0.id == id }) {
                    newState.todos[index].isCompleted.toggle()
                }
                continuation.yield(newState)
                continuation.finish()

            case .deleteTodo(let id):
                var newState = state
                newState.todos.removeAll { $0.id == id }
                continuation.yield(newState)
                continuation.finish()

            case .toggleAll:
                var newState = state
                let allCompleted = !state.activeTodos.isEmpty && state.activeTodos.count == state.todos.count
                for index in newState.todos.indices {
                    newState.todos[index].isCompleted = allCompleted
                }
                continuation.yield(newState)
                continuation.finish()

            case .clearCompleted:
                var newState = state
                newState.todos = newState.activeTodos
                continuation.yield(newState)
                continuation.finish()
            }
        }
    }
}

// MARK: - Views

struct TodoListView: View {
    @StateObject private var bloc = TodoBloc()
    @State private var newTodoText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Todos")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
                    TextField("What needs to be done?", text: $newTodoText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !newTodoText.trimmingCharacters(in: .whitespaceAndNewline).isEmpty {
                                bloc.send(.addTodo(newTodoText))
                                newTodoText = ""
                            }
                        }

                    Button(action: {
                        if !newTodoText.trimmingCharacters(in: .whitespaceAndNewline).isEmpty {
                            bloc.send(.addTodo(newTodoText))
                            newTodoText = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(newTodoText.trimmingCharacters(in: .whitespaceAndNewline).isEmpty)
                }
                .padding(.horizontal, 8)
            }
            .padding()

            // Todo List
            BlocBuilder(bloc) { state in
                List {
                    ForEach(state.filteredTodos) { todo in
                        TodoRowView(todo: todo) {
                            bloc.send(.toggleTodo(todo.id))
                        } onDelete: {
                            bloc.send(.deleteTodo(todo.id))
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let todo = state.filteredTodos[index]
                            bloc.send(.deleteTodo(todo.id))
                        }
                    }
                }
                .listStyle(.plain)
            }

            // Footer
            if !(try? BlocBuilder<TodoBloc, AnyView>.self.init { _ in AnyView(EmptyView()) }.body) != nil {
                BlocBuilder(bloc) { state in
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(state.activeCount) \(state.activeCount == 1 ? "item" : "items") left")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Picker("Filter", selection: $bloc.state.filter) {
                                ForEach(TodoState.Filter.allCases, id: \Self.self) { filter in
                                    Text(filter.rawValue.capitalized)
                                        .tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)

                            Button("Clear Completed") {
                                bloc.send(.clearCompleted)
                            }
                            .disabled(state.completedTodos.isEmpty)
                            .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .strikethrough(todo.isCompleted)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct TodoExampleApp_Previews: PreviewProvider {
    static var previews: some View {
        TodoExampleApp()
    }
}