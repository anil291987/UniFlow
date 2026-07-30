//  CounterBlocTests.swift
//  CounterExampleTests
//
//  Created by Claude on 2024-01-01
//

import XCTest
import Combine
import UniFlow
@testable import CounterExample

@MainActor
class CounterBlocTests: XCTestCase {
    var bloc: CounterBloc!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        bloc = CounterBloc()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        bloc.close()
        bloc = nil
    }

    func testInitialState() {
        XCTAssertEqual(bloc.state.count, 0, "Initial count should be 0")
    }

    func testIncrement() {
        // Given
        let expectation = self.expectation(description: "State updated after increment")

        // When we observe state changes
        var cancellable: AnyCancellable?
        cancellable = bloc.statePublisher
            .dropFirst() // Skip initial state
            .sink { state in
                // Then
                XCTAssertEqual(state.count, 1, "Count should be 1 after increment")
                expectation.fulfill()
                cancellable?.cancel()
            }

        bloc.send(.increment)

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testDecrement() {
        // Given
        let expectation = self.expectation(description: "State updated after decrement")

        // When we observe state changes
        var cancellable: AnyCancellable?
        cancellable = bloc.statePublisher
            .dropFirst() // Skip initial state
            .sink { state in
                // Then
                XCTAssertEqual(state.count, -1, "Count should be -1 after decrement")
                expectation.fulfill()
                cancellable?.cancel()
            }

        bloc.send(.decrement)

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testReset() {
        // Given
        let expectation = self.expectation(description: "State updated after reset")

        // First increment to have a non-zero value
        bloc.send(.increment)

        // When we observe state changes
        var cancellable: AnyCancellable?
        cancellable = bloc.statePublisher
            .dropFirst(2) // Skip initial state and after increment
            .sink { state in
                // Then
                XCTAssertEqual(state.count, 0, "Count should be 0 after reset")
                expectation.fulfill()
                cancellable?.cancel()
            }

        bloc.send(.reset)

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testMultipleOperations() {
        // Given
        let expectation = self.expectation(description: "State updated after multiple operations")

        // When we observe state changes
        var count = 0
        var cancellable: AnyCancellable?
        cancellable = bloc.statePublisher
            .dropFirst() // Skip initial state
            .sink { state in
                // Then
                switch count {
                case 0:
                    XCTAssertEqual(state.count, 1, "After increment: count should be 1")
                case 1:
                    XCTAssertEqual(state.count, 0, "After decrement: count should be 0")
                case 2:
                    XCTAssertEqual(state.count, -1, "After decrement: count should be -1")
                case 3:
                    XCTAssertEqual(state.count, 0, "After increment then decrement: count should be 0")
                default:
                    break
                }

                count += 1
                if count >= 4 {
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        // Perform operations
        bloc.send(.increment)    // 0 -> 1
        bloc.send(.decrement)    // 1 -> 0
        bloc.send(.decrement)    // 0 -> -1
        bloc.send(.increment)    // -1 -> 0

        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}