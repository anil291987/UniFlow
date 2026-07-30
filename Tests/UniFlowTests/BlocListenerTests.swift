//  BlocListenerTests.swift
//  UniFlowTests
//
//  Created by Claude on 2024-01-01
//

import XCTest
import SwiftUI
import Combine
@testable import UniFlow

// MARK: - Test Models
fileprivate enum ListenerTestEvent: Event {
    case increment
    case decrement
    case setValue(Int)
}

fileprivate struct ListenerTestState: StateProtocol, Equatable {
    var value: Int = 0

    static func == (lhs: ListenerTestState, rhs: ListenerTestState) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Test Blocs

fileprivate class ListenerTestBloc: Bloc<ListenerTestEvent, ListenerTestState> {
    init(initialValue: Int = 0) {
        super.init(initialState: ListenerTestState(value: initialValue))
    }

    override func mapEventToState(_ event: ListenerTestEvent) -> AsyncStream<ListenerTestState> {
        return AsyncStream { continuation in
            switch event {
            case .increment:
                let newState = ListenerTestState(value: state.value + 1)
                continuation.yield(newState)
                continuation.finish()

            case .decrement:
                let newState = ListenerTestState(value: state.value - 1)
                continuation.yield(newState)
                continuation.finish()

            case .setValue(let newValue):
                let newState = ListenerTestState(value: newValue)
                continuation.yield(newState)
                continuation.finish()
            }
        }
    }
}

final class BlocListenerTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        cancellables = .init()
    }

    override func tearDownWithError() throws {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
    }

    // MARK: - BlocListener Tests

    func testBlocListenerWithExplicitBloc() {
        // Given
        let bloc = ListenerTestBloc(initialValue: 0)
        var receivedValues: [Int] = []
        let expectation = self.expectation(description: "Listener called on state change")
        expectation.expectedFulfillmentCount = 2

        // When we create a BlocListener and observe state changes
        let _ = BlocListener<ListenerTestBloc, Text> { bloc, state in
            receivedValues.append(state.value)
            if receivedValues.count == 2 {
                expectation.fulfill()
            }
        } child: {
            Text("Test")
        }
        .environmentObject(bloc)

        // Send events to trigger state changes - need to use MainActor for send
        Task { @MainActor in
            bloc.send(.increment)
            bloc.send(.increment)
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [1, 2], "Listener should receive updated state values")

        // Cleanup
        Task { @MainActor in
            bloc.close()
        }
    }

    func testBlocListenerWithEnvironmentBloc() {
        // Given
        let bloc = ListenerTestBloc(initialValue: 5)
        var receivedValues: [Int] = []
        let expectation = self.expectation(description: "Listener called on state change")

        // When we create a BlocListener that gets bloc from environment
        let _ = BlocListener<ListenerTestBloc, Text> { bloc, state in
            receivedValues.append(state.value)
            if receivedValues.count >= 1 {
                expectation.fulfill()
            }
        } child: {
            Text("Test")
        }
        .environmentObject(bloc)

        // Send event to trigger state change - need to use MainActor for send
        Task { @MainActor in
            bloc.send(.decrement) // 5 -> 4
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [4], "Listener should receive updated state value")

        // Cleanup
        Task { @MainActor in
            bloc.close()
        }
    }

    func testBlocListenerInitialStateNotCalled() {
        // Given
        let bloc = ListenerTestBloc(initialValue: 10)
        var receivedValues: [Int] = []
        let expectation = self.expectation(description: "Listener called on state change")

        // When we create a BlocListener
        let _ = BlocListener<ListenerTestBloc, Text> { bloc, state in
            receivedValues.append(state.value)
            if receivedValues.count >= 1 {
                expectation.fulfill()
            }
        } child: {
            Text("Test")
        }
        .environmentObject(bloc)

        // Send event to trigger state change (initial state should not trigger listener) - need to use MainActor for send
        Task { @MainActor in
            bloc.send(.setValue(20))
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [20], "Listener should only receive updated state, not initial state")

        // Cleanup
        Task { @MainActor in
            bloc.close()
        }
    }
}