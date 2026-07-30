# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- Build the library: `swift build`
- Run all tests: `swift test`
- Run one test class: `swift test --filter BlocListenerTests`
- Run one test method: `swift test --filter BlocListenerTests/testBlocListenerWithExplicitBloc`
- Lint: `swiftlint` (config at `.swiftlint.yml`; not installed in this environment)

The `Examples/` packages (`CounterExample`, `TodoExample`) are standalone SwiftPM
executable packages with sources under `Sources/<TargetName>/` (and, for
`CounterExample`, tests under `Tests/<TargetName>Tests/`), each depending on the root
package via `.package(path: "../../")`. Build/test them from inside their own directory,
e.g. `cd Examples/CounterExample && swift build && swift test`. They require
`swift-tools-version: 5.9`+ and `.macOS(.v12)` (TodoExample uses `onSubmit`, both use
SwiftUI APIs unavailable before macOS 11).

## Architecture

UniFlow is a single-target SwiftPM library (`Package.swift`: target `UniFlow`, source path
`Sources/`, zero dependencies) implementing the BLoC pattern, modeled on `flutter_bloc`. All
core types live in `Sources/UniFlow/`:

- **`BlocBase`** (`BlocBase.swift`) — the `@MainActor` protocol both `Bloc` and `Cubit`
  conform to; requires `state` and a Combine `statePublisher`. Generic SwiftUI plumbing
  (`BlocBuilder`, `BlocListener`) is written against this protocol, not concrete
  `Bloc`/`Cubit` types.
- **`Bloc<EventType, StateType>`** (`Bloc.swift`) — event-driven: `send(_:)` yields into an
  internal `AsyncStream<EventType>`, consumed by a `Task` started in `init` that calls the
  overridden `mapEventToState(_:)` and applies each yielded state via `await MainActor.run`.
  `close()` cancels that task and finishes the stream.
- **`Cubit<StateType>`** (`Cubit.swift`) — simpler: `emit(_:)` sets `state` directly (no-op
  if `newState == state`, since `StateType: Equatable`).
- **`Event`** / **`StateProtocol`** (`Event.swift`, `State.swift`) — marker protocols
  (`Sendable`) that user-defined event/state types conform to.
- **`BlocObserver`** (`BlocObserver.swift`) — lifecycle hook protocol (`didCreate`/
  `didChange`/`didClose`). Both `Bloc` and `Cubit` expose an overridable `blocObserver`
  property defaulting to the `BlocObserverImpl.shared` singleton; their own `init`,
  state-mutation, and `close()` code paths call through `self.blocObserver`, not a
  hardcoded reference to the singleton — keep it that way so a per-instance override
  actually takes effect.
- **`BlocProvider`** / **`RepositoryProvider`** (`BlocProvider.swift`,
  `RepositoryProvider.swift`) — thin SwiftUI wrappers around `@StateObject` +
  `.environmentObject(_:)`.
- **`BlocBuilder`** / **`BlocListener`** (`BlocBuilder.swift`, `BlocListener.swift`) — each
  supports two construction paths: an explicit bloc instance, or one pulled from the
  SwiftUI environment. Each is a thin dispatcher (`enum Source { case explicit(B);
  case environment }`) that forwards to one of two *separate* private child view structs
  (`_ExplicitBlocBuilder`/`_EnvironmentBlocBuilder`,
  `_ExplicitBlocListener`/`_EnvironmentBlocListener`). This split is load-bearing: SwiftUI
  validates every dynamic property (`@EnvironmentObject`, `@StateObject`, etc.) on a view
  when its `body` runs, even on branches that go untaken. Putting both an explicit bloc
  property and `@EnvironmentObject` on one view type crashes at runtime ("No
  ObservableObject of type X found") whenever the explicit path is used without also
  supplying `.environmentObject(_:)`. Don't collapse these back into a single view type.
  `BlocListener` also relies on `bloc.statePublisher.dropFirst()` to skip the initial
  state — `@Published` republishes the current value to any new subscriber, so removing
  `dropFirst()` reintroduces a bug where the listener fires once on subscribe with
  whatever the current state happens to be.
- `CubitProvider`/`CubitBuilder`/`CubitListener` are typealiases specializing the
  corresponding `Bloc*` type to `Cubit<StateType>`.

### Concurrency model

Every core type (`Bloc`, `Cubit`, `BlocBase`) is `@MainActor`-isolated. Any code —
including tests — that constructs or calls into them synchronously must itself run on
`@MainActor`, or the compiler rejects it with actor-isolation errors. See
`Tests/UniFlowTests/*Tests.swift` for the pattern: test classes are marked `@MainActor`
(this is compatible with `XCTestCase` overrides like `setUpWithError`/`tearDownWithError`).

### Testing the SwiftUI-facing types

`BlocBuilder`, `BlocListener`, `BlocProvider`, and `RepositoryProvider` are `View`s.
Constructing one and never rendering it means `body`/`.onReceive`/`.onAppear` never run,
so a test that just builds the view and sends events is a no-op. `BlocBuilderTests.swift`
and `BlocListenerTests.swift` host the view for real via `NSHostingController(rootView:)`
and force a render with `controller.view.layoutSubtreeIfNeeded()`, following state changes
with either a small delay or a repeating layout "pump" (`Timer`) to give SwiftUI a chance
to re-render. Don't assert an exact number of body-evaluations after several rapid state
changes — SwiftUI is free to coalesce them into fewer render passes; assert on the final
observed value instead.

Also watch for: `XCTestExpectation.expectedFulfillmentCount` must equal the exact number
of `fulfill()` calls actually made. Setting it to N while only calling `fulfill()` once
inside an `if count == N` check compiles fine but silently times out at runtime.
