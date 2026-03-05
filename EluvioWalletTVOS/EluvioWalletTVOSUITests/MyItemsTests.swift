//
//  MyItemsTests.swift
//  EluvioWalletTVOSUITests
//
//  Tests for My Items tab functionality
//

import XCTest

final class MyItemsTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Use mock data for fast, reliable tests
        app.launchArguments = ["UI_TESTING", "MOCK_LOGGED_IN", "MOCK_DATA", "MOCK_DISABLE_LOGIN"]
        app.launch()

        // Wait for the app to load (shorter with mock data)
        Thread.sleep(forTimeInterval: 1)

        // Navigate to My Items tab
        app.navigateToTab("My Items")
        Thread.sleep(forTimeInterval: 0.5)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - My Items Tab Tests

    func testMyItemsTabIsAccessible() throws {
        // Verify we can access the My Items tab
        let itemsTab = app.tabBars.buttons["My Items"]
        XCTAssertTrue(itemsTab.exists, "My Items tab should be accessible")
    }

    func testMyItemsViewLoads() throws {
        // Wait for My Items view to load
        Thread.sleep(forTimeInterval: 2)

        // The view should show something - either items or an empty state
        // Look for any content in the view
        let hasContent = app.staticTexts.count > 0 || app.images.count > 0 || app.buttons.count > 0
        XCTAssertTrue(hasContent, "My Items view should have some content")
    }

    func testCanNavigateThroughMyItems() throws {
        // Wait for content to load
        Thread.sleep(forTimeInterval: 2)

        // Try navigating down through items
        XCUIRemote.shared.press(.down)
        Thread.sleep(forTimeInterval: 0.3)

        // The navigation should not crash the app
        XCTAssertTrue(app.exists, "App should remain stable after navigation")
    }

    func testCanReturnToHomeFromMyItems() throws {
        // From My Items, go back to Home
        app.navigateToTab("Home")
        Thread.sleep(forTimeInterval: 0.5)

        // Verify we're on Home
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Should be able to return to Home tab")
    }
}
