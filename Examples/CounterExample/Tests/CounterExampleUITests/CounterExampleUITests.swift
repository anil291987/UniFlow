//  CounterExampleUITests.swift
//  CounterExampleUITests
//
//  Drives the real CounterExample app via the Accessibility API.
//
//  Requires the app to be wrapped as an .app bundle first (SwiftPM builds a
//  raw executable, which XCUIApplication can't launch directly):
//
//      ./scripts/build-app-bundle.sh
//      COUNTEREXAMPLE_APP_BUNDLE="$(pwd)/.build/CounterExample.app" \
//          swift test --filter CounterExampleUITests
//
//  Also requires the test runner to have Accessibility permission
//  (System Settings > Privacy & Security > Accessibility) for XCUIApplication
//  to control other processes.

import XCTest

final class CounterExampleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        guard let bundlePath = ProcessInfo.processInfo.environment["COUNTEREXAMPLE_APP_BUNDLE"] else {
            throw XCTSkip("Set COUNTEREXAMPLE_APP_BUNDLE to the .app produced by scripts/build-app-bundle.sh")
        }

        app = XCUIApplication(url: URL(fileURLWithPath: bundlePath))
        app.launch()
    }

    override func tearDownWithError() throws {
        app?.terminate()
    }

    func testInitialCountIsZero() throws {
        XCTAssertEqual(app.staticTexts["countLabel"].label, "Count: 0")
    }

    func testIncrementIncreasesCount() throws {
        app.buttons["incrementButton"].click()
        XCTAssertEqual(app.staticTexts["countLabel"].label, "Count: 1")
    }

    func testDecrementDecreasesCount() throws {
        app.buttons["decrementButton"].click()
        XCTAssertEqual(app.staticTexts["countLabel"].label, "Count: -1")
    }

    func testResetReturnsToZero() throws {
        app.buttons["incrementButton"].click()
        app.buttons["incrementButton"].click()
        app.buttons["resetButton"].click()
        XCTAssertEqual(app.staticTexts["countLabel"].label, "Count: 0")
    }

    func testMultipleOperations() throws {
        app.buttons["incrementButton"].click() // 1
        app.buttons["incrementButton"].click() // 2
        app.buttons["decrementButton"].click() // 1
        XCTAssertEqual(app.staticTexts["countLabel"].label, "Count: 1")
    }
}
