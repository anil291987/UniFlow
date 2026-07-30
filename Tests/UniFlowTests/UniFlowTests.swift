//  UniFlowTests.swift
//  UniFlowTests
//
//  Created by Claude on 2024-01-01
//

import XCTest
import Combine
@testable import UniFlow

// MARK: - Test Models

enum TestEvent: Event {
    case increment
    case decrement
    case reset
    case setValue(Int)
}

struct TestState: StateProtocol, Equatable {
    var value: Int = 0

    static func == (lhs: TestState, rhs: TestState) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Test Blocs

class TestBloc: Bloc<TestEvent, TestState> {
    init(initialValue: Int = 0) {
        super.init(initialState: TestState(value: initialValue))
    }

    override func mapEventToState(_ event: TestEvent) -> AsyncStream<TestState> {
        return AsyncStream { continuation in
            switch event {
            case .increment:
                let newState = TestState(value: state.value + 1)
                continuation.yield(newState)
                continuation.finish()

            case .decrement:
                let newState = TestState(value: state.value - 1)
                continuation.yield(newState)
                continuation.finish()

            case .reset:
                let newState = TestState(value: 0)
                continuation.yield(newState)
                continuation.finish()

            case .setValue(let newValue):
                let newState = TestState(value: newValue)
                continuation.yield(newState)
                continuation.finish()
            }
        }
    }
}

class TestCubit: Cubit<TestState> {
    init(initialValue: Int = 0) {
        super.init(initialState: TestState(value: initialValue))
    }

    func increment() {
        emit(TestState(value: state.value + 1))
    }

    func decrement() {
        emit(TestState(value: state.value - 1))
    }

    func setValue(_ newValue: Int) {
        emit(TestState(value: newValue))
    }
}

// MARK: - Tests

@MainActor
final class UniFlowTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        cancellables = .init()
        // Note: We don't modify the shared BlocObserver instance directly in tests
        // to avoid affecting other tests
    }

    override func tearDown() async throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        try await super.tearDown()
    }

    func testBlocInitialState() {
        // Given
        let bloc = TestBloc(initialValue: 5)

        // Then
        XCTAssertEqual(bloc.state.value, 5, "Initial value should be 5")

        // Cleanup
        bloc.close()
    }

    func testBlocIncrement() {
        // Given
        let bloc = TestBloc()
        let expectation = self.expectation(description: "State updated after increment")

        // When we observe state changes
        var receivedValues: [Int] = []
        var cancellable: AnyCancellable?

        // Observe state changes on MainActor
        Task { @MainActor in
            cancellable = bloc.statePublisher
                .dropFirst() // Skip initial state
                .sink { state in
                    receivedValues.append(state.value)
                    if receivedValues.count == 1 {
                        // Then
                        XCTAssertEqual(state.value, 1, "Value should be 1 after increment")
                        expectation.fulfill()
                        cancellable?.cancel()
                    }
                }
        }

        // Send increment event
        bloc.send(.increment)

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testBlocDecrement() {
        // Given
        let bloc = TestBloc(initialValue: 5)
        let expectation = self.expectation(description: "State updated after decrement")

        // When we observe state changes
        var cancellable: AnyCancellable?

        // Observe state changes on MainActor
        Task { @MainActor in
            cancellable = bloc.statePublisher
                .dropFirst() // Skip initial state
                .sink { state in
                    // Then
                    XCTAssertEqual(state.value, 4, "Value should be 4 after decrement from 5")
                    expectation.fulfill()
                    cancellable?.cancel()
                }
        }

        // Send decrement event
        bloc.send(.decrement)

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testBlocReset() {
        // Given
        let bloc = TestBloc(initialValue: 5)
        let expectation = self.expectation(description: "State updated after reset")

        // When we observe state changes
        var cancellable: AnyCancellable?

        // Observe state changes on MainActor
        Task { @MainActor in
            cancellable = bloc.statePublisher
                .dropFirst() // Skip initial state
                .sink { state in
                    // Then
                    XCTAssertEqual(state.value, 0, "Value should be 0 after reset")
                    expectation.fulfill()
                    cancellable?.cancel()
                }
        }

        // Send reset event
        bloc.send(.reset)

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testBlocSetValue() {
        // Given
        let bloc = TestBloc()
        let expectation = self.expectation(description: "State updated after setValue")

        // When we observe state changes
        var cancellable: AnyCancellable?

        // Observe state changes on MainActor
        Task { @MainActor in
            cancellable = bloc.statePublisher
                .dropFirst() // Skip initial state
                .sink { state in
                    // Then
                    XCTAssertEqual(state.value, 42, "Value should be 42 after setValue(42)")
                    expectation.fulfill()
                    cancellable?.cancel()
                }
        }

        // Send setValue event
        bloc.send(.setValue(42))

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testCubitInitialState() {
        // Given
        let cubit = TestCubit(initialValue: 3)

        // Then
        XCTAssertEqual(cubit.state.value, 3, "Initial value should be 3")

        // Cleanup
        cubit.close()
    }

    func testCubitIncrement() {
        // Given
        let cubit = TestCubit()
        let expectation = self.expectation(description: "State updated after increment")

        // When we observe state changes
        var receivedValues: [Int] = []
        var cancellable: AnyCancellable?

        // Observe state changes
        cancellable = cubit.statePublisher
            .dropFirst() // Skip initial state
            .sink { state in
                receivedValues.append(state.value)
                if receivedValues.count == 1 {
                    // Then
                    XCTAssertEqual(state.value, 1, "Value should be 1 after increment")
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        // Increment
        cubit.increment()

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testCubitDecrement() {
        // Given
        let cubit = TestCubit(initialValue: 5)
        let expectation = self.expectation(description: "State updated after decrement")

        // When we observe state changes
        var cancellable: AnyCancellable?

        // Observe state changes
        cancellable = cubit.statePublisher
            .dropFirst() // Skip initial state
            .sink { state in
                // Then
                XCTAssertEqual(state.value, 4, "Value should be 4 after decrement from 5")
                expectation.fulfill()
                cancellable?.cancel()
            }

        // Decrement
        cubit.decrement()

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testCubitSetValue() {
        // Given
        let cubit = TestCubit()
        let expectation = self.expectation(description: "State updated after setValue")

        // When we observe state changes
        var cancellable: AnyCancellable?

        // Observe state changes
        cancellable = cubit.statePublisher
            .dropFirst() // Skip initial state
            .sink { state in
                // Then
                XCTAssertEqual(state.value, 42, "Value should be 42 after setValue(42)")
                expectation.fulfill()
                cancellable?.cancel()
            }

        // Set value
        cubit.setValue(42)

        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Test Helper

class TestBlocObserver: BlocObserverBase, @unchecked Sendable {
    var createCount = 0
    var changeCount = 0
    var closeCount = 0

    override func didCreate<Bloc: BlocBase>(_ bloc: Bloc) {
        createCount += 1
    }

    override func didChange<Bloc: BlocBase>(_ bloc: Bloc, previousState: Bloc.State) {
        changeCount += 1
    }

    override func didClose<Bloc: BlocBase>(_ bloc: Bloc) {
        closeCount += 1
    }
}