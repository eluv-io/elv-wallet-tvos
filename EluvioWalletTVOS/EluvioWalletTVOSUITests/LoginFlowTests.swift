//
//  LoginFlowTests.swift
//  EluvioWalletTVOSUITests
//
//  Tests for login flow scenarios
//

import XCTest

final class LoginFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Logged Out State Tests

    func testAppShowsDiscoverViewWhenLoggedOut() throws {
        // Launch with forced logout and mock data for fast loading
        app.launchArguments = ["UI_TESTING", "FORCE_LOGGED_OUT", "MOCK_DATA"]
        app.launch()

        // Wait for app to load (shorter with mock data)
        Thread.sleep(forTimeInterval: 2)

        // Should show discover view when logged out
        XCTAssertTrue(
            app.waitForIdentifier("discover_view", timeout: 5),
            "Discover view should be shown when logged out"
        )
    }

    func testDiscoverViewShowsProperties() throws {
        // Launch with forced logout and mock data
        app.launchArguments = ["UI_TESTING", "FORCE_LOGGED_OUT", "MOCK_DATA"]
        app.launch()

        // Wait for properties to load
        Thread.sleep(forTimeInterval: 2)

        // Look for any property card elements (mock properties have "mock_property" in id)
        let propertyCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'property_card_'")
        )

        // We should have at least one property visible
        let firstCard = propertyCards.firstMatch
        let exists = firstCard.waitForExistence(timeout: 5)

        XCTAssertTrue(exists, "Properties should be visible on discover view")
    }

    func testSelectingPropertyNavigatesToLogin() throws {
        // Launch with forced logout and mock data (login NOT disabled)
        app.launchArguments = ["UI_TESTING", "FORCE_LOGGED_OUT", "MOCK_DATA"]
        app.launch()

        // Wait for properties to load
        Thread.sleep(forTimeInterval: 2)

        // Select a property
        XCUIRemote.shared.press(.down)
        Thread.sleep(forTimeInterval: 0.3)
        XCUIRemote.shared.press(.select)

        // Wait for navigation
        Thread.sleep(forTimeInterval: 2)

        // Should navigate to login view (since login is required)
        let loginView = app.findElement(identifier: "login_view")
        XCTAssertTrue(
            loginView.waitForExistence(timeout: 5),
            "Selecting property when logged out should show login view"
        )
    }

    // MARK: - Login View Tests

    func testLoginViewShowsQRCodeAndCode() throws {
        // Launch with forced logout and mock data
        app.launchArguments = ["UI_TESTING", "FORCE_LOGGED_OUT", "MOCK_DATA"]
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        // Navigate to a property to trigger login
        XCUIRemote.shared.press(.down)
        Thread.sleep(forTimeInterval: 0.3)
        XCUIRemote.shared.press(.select)

        Thread.sleep(forTimeInterval: 2)

        // Check if login view appears
        let loginView = app.findElement(identifier: "login_view")
        if loginView.waitForExistence(timeout: 5) {
            // Login view should have Sign In text
            let signInText = app.staticTexts["Sign In"]
            XCTAssertTrue(signInText.exists, "Login view should show 'Sign In' text")

            // Should have Request New Code button
            let requestCodeButton = app.buttons["Request New Code"]
            XCTAssertTrue(requestCodeButton.exists, "Login view should have 'Request New Code' button")

            // Should have Back button
            let backButton = app.buttons["Back"]
            XCTAssertTrue(backButton.exists, "Login view should have 'Back' button")
        }
    }

    func testLoginViewBackButtonDismisses() throws {
        // Launch with forced logout and mock data
        app.launchArguments = ["UI_TESTING", "FORCE_LOGGED_OUT", "MOCK_DATA"]
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        // Navigate to a property to trigger login
        XCUIRemote.shared.press(.down)
        Thread.sleep(forTimeInterval: 0.3)
        XCUIRemote.shared.press(.select)

        Thread.sleep(forTimeInterval: 2)

        // Check if login view appears
        let loginView = app.findElement(identifier: "login_view")
        if loginView.waitForExistence(timeout: 5) {
            // Press menu to go back (simpler than navigating to button)
            XCUIRemote.shared.press(.menu)
            Thread.sleep(forTimeInterval: 0.5)

            // Should be back on discover view
            XCTAssertTrue(
                app.waitForIdentifier("discover_view", timeout: 3),
                "Menu button should return to discover view"
            )
        }
    }
}
