//  TodoExampleUITests.swift
//  TodoExampleUITests
//
//  Drives the real TodoExample app via the Accessibility API.
//
//  Requires the app to be wrapped as an .app bundle first (SwiftPM builds a
//  raw executable, which XCUIApplication can't launch directly):
//
//      ./scripts/build-app-bundle.sh
//      TODOEXAMPLE_APP_BUNDLE="$(pwd)/.build/TodoExample.app" \
//          swift test --filter TodoExampleUITests
//
//  Also requires the test runner to have Accessibility permission
//  (System Settings > Privacy & Security > Accessibility) for XCUIApplication
//  to control other processes.

import XCTest

final class TodoExampleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        guard let bundlePath = ProcessInfo.processInfo.environment["TODOEXAMPLE_APP_BUNDLE"] else {
            throw XCTSkip("Set TODOEXAMPLE_APP_BUNDLE to the .app produced by scripts/build-app-bundle.sh")
        }

        app = XCUIApplication(url: URL(fileURLWithPath: bundlePath))
        app.launch()
    }

    override func tearDownWithError() throws {
        app?.terminate()
    }

    private func addTodo(_ title: String) {
        let field = app.textFields["newTodoTextField"]
        field.click()
        field.typeText(title)
        app.buttons["addTodoButton"].click()
    }

    func testAddingTodoShowsItInList() throws {
        addTodo("Buy milk")
        XCTAssertTrue(app.staticTexts["todoLabel-Buy milk"].exists)
        XCTAssertEqual(app.staticTexts["activeCountLabel"].label, "1 item left")
    }

    func testTogglingTodoDecrementsActiveCount() throws {
        addTodo("Buy milk")
        app.buttons["toggleButton-Buy milk"].click()
        XCTAssertEqual(app.staticTexts["activeCountLabel"].label, "0 items left")
    }

    func testDeletingTodoRemovesItFromList() throws {
        addTodo("Buy milk")
        app.buttons["deleteButton-Buy milk"].click()
        XCTAssertFalse(app.staticTexts["todoLabel-Buy milk"].exists)
    }

    func testClearCompletedRemovesCompletedTodos() throws {
        addTodo("Buy milk")
        addTodo("Walk dog")
        app.buttons["toggleButton-Buy milk"].click()
        app.buttons["clearCompletedButton"].click()
        XCTAssertFalse(app.staticTexts["todoLabel-Buy milk"].exists)
        XCTAssertTrue(app.staticTexts["todoLabel-Walk dog"].exists)
    }

    func testFilterActiveHidesCompletedTodos() throws {
        addTodo("Buy milk")
        addTodo("Walk dog")
        app.buttons["toggleButton-Buy milk"].click()

        app.segmentedControls["filterPicker"].buttons["Active"].click()

        XCTAssertFalse(app.staticTexts["todoLabel-Buy milk"].exists)
        XCTAssertTrue(app.staticTexts["todoLabel-Walk dog"].exists)
    }
}
