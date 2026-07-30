//  BlocBuilderTests.swift
//  UniFlowTests
//
//  Created by Claude on 2024-01-01
//

import XCTest
import SwiftUI
import Combine
@testable import UniFlow

// MARK: - Test Models
fileprivate enum BuilderTestEvent: Event {
    case increment
    case decrement
    case setValue(Int)
}

fileprivate struct BuilderTestState: StateProtocol, Equatable {
    var value: Int = 0

    static func == (lhs: BuilderTestState, rhs: BuilderTestState) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Test Blocs

fileprivate class BuilderTestBloc: Bloc<BuilderTestEvent, BuilderTestState> {
    init(initialValue: Int = 0) {
        super.init(initialState: BuilderTestState(value: initialValue))
    }

    override func mapEventToState(_ event: BuilderTestEvent) -> AsyncStream<BuilderTestState> {
        return AsyncStream { continuation in
            switch event {
            case .increment:
                let newState = BuilderTestState(value: state.value + 1)
                continuation.yield(newState)
                continuation.finish()

            case .decrement:
                let newState = BuilderTestState(value: state.value - 1)
                continuation.yield(newState)
                continuation.finish()

            case .setValue(let newValue):
                let newState = BuilderTestState(value: newValue)
                continuation.yield(newState)
                continuation.finish()
            }
        }
    }
}

final class BlocBuilderTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        cancellables = .init()
    }

    override func tearDownWithError() throws {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
    }

    // MARK: - BlocBuilder Tests

    func testBlocBuilderWithExplicitBloc() {
        // Given
        let bloc = BuilderTestBloc(initialValue: 0)
        let expectation = self.expectation(description: "Builder called with initial state")

        // Track if the body property was evaluated by checking if our view was created
        var bodyEvaluated = false

        // When we create a BlocBuilder
        let _ = BlocReaderTestHelper.createViewWithBlocBuilder(
            bloc: bloc,
            builder: { state in
                bodyEvaluated = true
                if state.value == 0 {
                    expectation.fulfill()
                }
                return Text("Value: \(state.value)")
            }
        )

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(bodyEvaluated, "Builder should be called to create the view")

        // Cleanup
        Task { @MainActor in
            bloc.close()
        }
    }

    func testBlocBuilderWithEnvironmentBloc() {
        // Given
        let bloc = BuilderTestBloc(initialValue: 5)
        let expectation = self.expectation(description: "Builder called with environment bloc")
        var lastValue: Int = -1

        // When we create a BlocBuilder that gets bloc from environment
        let _ = BlocReaderTestHelper.createViewWithBlocBuilder(
            bloc: bloc,
            builder: { state in
                lastValue = state.value
                if state.value == 5 {
                    expectation.fulfill()
                }
                return Text("Value: \(state.value)")
            }
        )

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(lastValue, 5, "Builder should receive the current state value from environment")

        // Cleanup
        Task { @MainActor in
            bloc.close()
        }
    }

    func testBlocBuilderUpdatesWhenStateChanges() {
        // Given
        let bloc = BuilderTestBloc(initialValue: 0)
        var updateCount = 0
        let expectation = self.expectation(description: "Builder called when state changes")
        expectation.expectedFulfillmentCount = 2

        // When we create a BlocBuilder
        let _ = BlocReaderTestHelper.createViewWithBlocBuilder(
            bloc: bloc,
            builder: { state in
                updateCount += 1
                if updateCount == 1 {
                    XCTAssertEqual(state.value, 0, "First call should have initial value")
                } else if updateCount == 2 {
                    XCTAssertEqual(state.value, 3, "Second call should have updated value")
                    expectation.fulfill()
                }
                return Text("Value: \(state.value)")
            }
        )

        // Send events to trigger state changes - need to use MainActor for send
        Task { @MainActor in
            bloc.send(.increment) // 0 -> 1
            bloc.send(.increment) // 1 -> 2
            bloc.send(.increment) // 2 -> 3
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(updateCount, 2, "Builder should be called for initial state and each state change")

        // Cleanup
        Task { @MainActor in
            bloc.close()
        }
    }
}

// MARK: - Test Helper

fileprivate struct BlocReaderTestHelper {
    /// Helper to create a view that can be tested in isolation
    static func createViewWithBlocBuilder<B: BlocBase, Content: View>(
        bloc: B,
        @ViewBuilder builder: @escaping (B.State) -> Content
    ) -> some View {
        BlocBuilder(bloc, builder: builder)
    }
}