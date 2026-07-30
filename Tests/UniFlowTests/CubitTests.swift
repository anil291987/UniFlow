//  CubitTests.swift
//  UniFlowTests
//
//  Created by Claude on 2024-01-01
//

import XCTest
import Combine
@testable import UniFlow

// MARK: - Tests

@MainActor
final class CubitTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        cancellables = .init()
    }

    override func tearDown() async throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        try await super.tearDown()
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
        var cancellable: AnyCancellable?
        cancellable = cubit.statePublisher
            .dropFirst() // Skip initial state
            .sink { state in
                // Then
                XCTAssertEqual(state.value, 1, "Value should be 1 after increment")
                expectation.fulfill()
                cancellable?.cancel()
            }

        // Increment
        cubit.increment()

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testCubitMultipleOperations() {
        // Given
        let cubit = TestCubit(initialValue: 5)
        let expectation = self.expectation(description: "State updated after multiple operations")

        // When we observe state changes
        var step = 0
        var cancellable: AnyCancellable?
        cancellable = cubit.statePublisher
            .dropFirst() // Skip initial state
            .sink { state in
                // Then
                switch step {
                case 0:
                    XCTAssertEqual(state.value, 6, "After increment: should be 6")
                case 1:
                    XCTAssertEqual(state.value, 5, "After first decrement: should be 5")
                case 2:
                    XCTAssertEqual(state.value, 4, "After second decrement: should be 4")
                case 3:
                    XCTAssertEqual(state.value, 10, "After setValue: should be 10")
                default:
                    break
                }

                step += 1
                if step >= 4 {
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        // Perform operations
        cubit.increment()  // 5 -> 6
        cubit.decrement()  // 6 -> 5
        cubit.decrement()  // 5 -> 4
        cubit.setValue(10) // 4 -> 10

        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}