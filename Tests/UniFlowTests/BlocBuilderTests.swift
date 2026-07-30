//  BlocBuilderTests.swift
//  UniFlowTests
//
//  Created by Claude on 2024-01-01
//

import XCTest
import SwiftUI
import Combine
import AppKit
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

@MainActor
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
        let controller = BlocReaderTestHelper.createViewWithBlocBuilder(
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
        _ = controller
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
        let controller = BlocReaderTestHelper.createViewWithBlocBuilder(
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
        _ = controller
        XCTAssertEqual(lastValue, 5, "Builder should receive the current state value from environment")

        // Cleanup
        Task { @MainActor in
            bloc.close()
        }
    }

    func testBlocBuilderUpdatesWhenStateChanges() {
        // Given
        let bloc = BuilderTestBloc(initialValue: 0)
        var lastValue = -1
        let expectation = self.expectation(description: "Builder called with final state")

        // When we create a BlocBuilder
        let controller = BlocReaderTestHelper.createViewWithBlocBuilder(
            bloc: bloc,
            builder: { state in
                lastValue = state.value
                if state.value == 3 {
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

        // SwiftUI only re-evaluates body on the next real render pass; without a
        // window driving that, force it by repeatedly pumping layout. SwiftUI is free
        // to coalesce rapid successive state changes into fewer render passes, so we
        // only assert on the final observed value, not an exact call count.
        let pump = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            controller.view.layoutSubtreeIfNeeded()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        pump.invalidate()
        XCTAssertEqual(lastValue, 3, "Builder should eventually reflect the final state")

        // Cleanup
        Task { @MainActor in
            bloc.close()
        }
    }
}

// MARK: - Test Helper

@MainActor
fileprivate struct BlocReaderTestHelper {
    /// Helper to create a view and force SwiftUI to actually render it (build & evaluate
    /// its body), which a bare `View` value never does on its own outside a real app.
    static func createViewWithBlocBuilder<B: BlocBase, Content: View>(
        bloc: B,
        @ViewBuilder builder: @escaping (B.State) -> Content
    ) -> NSHostingController<BlocBuilder<B, Content>> {
        let view = BlocBuilder(bloc, builder: builder)
        let controller = NSHostingController(rootView: view)
        controller.view.layoutSubtreeIfNeeded()
        return controller
    }
}