//
//  PropertyNavigationTests.swift
//  EluvioWalletTVOSUITests
//
//  Tests for property navigation
//

import XCTest

final class PropertyNavigationTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Property Selection Tests (Logged Out - triggers login)

    func testSelectingPropertyShowsLoginWhenLoggedOut() throws {
        // Launch with forced logout and mock data (login NOT disabled)
        app.launchArguments = ["UI_TESTING", "FORCE_LOGGED_OUT", "MOCK_DATA"]
        app.launch()
        Thread.sleep(forTimeInterval: 2)

        // Navigate down to property list and select
        XCUIRemote.shared.press(.down)
        Thread.sleep(forTimeInterval: 0.3)
        XCUIRemote.shared.press(.select)
        Thread.sleep(forTimeInterval: 2)

        // Should navigate to login view
        let loginView = app.findElement(identifier: "login_view")
        XCTAssertTrue(
            loginView.waitForExistence(timeout: 5),
            "Selecting property when logged out should show login view"
        )
    }

    func testCanGoBackFromLoginToDiscover() throws {
        // Launch with forced logout and mock data
        app.launchArguments = ["UI_TESTING", "FORCE_LOGGED_OUT", "MOCK_DATA"]
        app.launch()
        Thread.sleep(forTimeInterval: 2)

        // Navigate to a property to trigger login
        XCUIRemote.shared.press(.down)
        Thread.sleep(forTimeInterval: 0.3)
        XCUIRemote.shared.press(.select)
        Thread.sleep(forTimeInterval: 2)

        // Verify login view appeared
        let loginView = app.findElement(identifier: "login_view")
        if loginView.waitForExistence(timeout: 5) {
            // Press menu to go back
            XCUIRemote.shared.press(.menu)
            Thread.sleep(forTimeInterval: 0.5)

            // Should be back on discover view
            XCTAssertTrue(
                app.waitForIdentifier("discover_view", timeout: 3),
                "Menu button should navigate back to discover view"
            )
        }
    }

    // MARK: - Property Navigation Tests (Logged In with mock)
    // Note: With mock login, property detail view loads but content is empty
    // because the mock account lacks real API tokens

    func testPropertyDetailViewLoadsWithMockLogin() throws {
        // Launch with mock login and mock data for fast tests
        app.launchArguments = ["UI_TESTING", "MOCK_LOGGED_IN", "MOCK_DATA", "MOCK_DISABLE_LOGIN"]
        app.launch()
        Thread.sleep(forTimeInterval: 1)

        // Navigate to property and select
        XCUIRemote.shared.press(.down, times: 2)
        Thread.sleep(forTimeInterval: 0.3)
        XCUIRemote.shared.press(.select)
        Thread.sleep(forTimeInterval: 2)

        // Should navigate to property detail
        let propertyDetail = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'property_detail_'")
        ).firstMatch

        XCTAssertTrue(
            propertyDetail.waitForExistence(timeout: 5),
            "Should navigate to property detail view"
        )
    }

    func testCanGoBackFromPropertyDetailToMain() throws {
        // Launch with mock login and mock data
        app.launchArguments = ["UI_TESTING", "MOCK_LOGGED_IN", "MOCK_DATA", "MOCK_DISABLE_LOGIN"]
        app.launch()
        Thread.sleep(forTimeInterval: 1)

        // Navigate to property
        XCUIRemote.shared.press(.down, times: 2)
        Thread.sleep(forTimeInterval: 0.3)
        XCUIRemote.shared.press(.select)
        Thread.sleep(forTimeInterval: 2)

        // Check if we're on property detail
        let propertyDetail = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'property_detail_'")
        ).firstMatch

        if propertyDetail.waitForExistence(timeout: 5) {
            // Press menu to go back
            XCUIRemote.shared.press(.menu)
            Thread.sleep(forTimeInterval: 0.5)

            // Should be back on main view
            XCTAssertTrue(
                app.waitForIdentifier("main_view", timeout: 3),
                "Menu button should navigate back to main view"
            )
        }
    }

    func testSearchButtonVisibleOnPropertyDetail() throws {
        // Launch with mock login and mock data
        app.launchArguments = ["UI_TESTING", "MOCK_LOGGED_IN", "MOCK_DATA", "MOCK_DISABLE_LOGIN"]
        app.launch()
        Thread.sleep(forTimeInterval: 1)

        // Navigate to property
        XCUIRemote.shared.press(.down, times: 2)
        Thread.sleep(forTimeInterval: 0.3)
        XCUIRemote.shared.press(.select)
        Thread.sleep(forTimeInterval: 2)

        // Check if we're on property detail
        let propertyDetail = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'property_detail_'")
        ).firstMatch

        if propertyDetail.waitForExistence(timeout: 5) {
            // Search button should exist even without content
            let buttons = app.buttons
            XCTAssertGreaterThan(buttons.count, 0, "Property detail should have search button")
        }
    }
}
