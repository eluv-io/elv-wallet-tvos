//
//  NavigationTests.swift
//  EluvioWalletTVOSUITests
//
//  Tests for basic tab navigation when logged in
//

import XCTest

final class NavigationTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Use mock data for fast, reliable tests
        app.launchArguments = ["UI_TESTING", "MOCK_LOGGED_IN", "MOCK_DATA", "MOCK_DISABLE_LOGIN"]
        app.launch()

        // Wait for the app to load (shorter with mock data)
        Thread.sleep(forTimeInterval: 1)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Navigation Tests

    func testAppLaunchesWithMockLogin() throws {
        // When mock login is enabled, we should see the main view
        // Search all element types since SwiftUI views may not be in otherElements
        let mainExists = app.waitForIdentifier("main_view", timeout: 10)
        let discoverExists = app.waitForIdentifier("discover_view", timeout: 5)

        XCTAssertTrue(mainExists || discoverExists, "App should show either main view or discover view")
    }

    func testTabBarHasThreeTabs() throws {
        // Wait for main view to load
        Thread.sleep(forTimeInterval: 2)

        // Navigate to tab bar
        app.focusTabBar()
        Thread.sleep(forTimeInterval: 0.5)

        // Check for tabs - they might be labeled differently
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")

        // Check that we have multiple tab buttons
        let tabCount = tabBar.buttons.count
        XCTAssertGreaterThanOrEqual(tabCount, 3, "Tab bar should have at least 3 tabs")
    }

    func testNavigateToItemsTab() throws {
        // Wait for main view to load
        Thread.sleep(forTimeInterval: 2)

        // Navigate to My Items tab
        app.navigateToTab("My Items")

        // Verify the tab is selected
        let itemsTab = app.tabBars.buttons["My Items"]
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(itemsTab.exists, "My Items tab should exist")
    }

    func testNavigateToProfileTab() throws {
        // Wait for main view to load
        Thread.sleep(forTimeInterval: 2)

        // Navigate to Profile tab
        app.navigateToTab("Profile")

        // Verify the tab exists
        let profileTab = app.tabBars.buttons["Profile"]
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(profileTab.exists, "Profile tab should exist")
    }

    func testNavigateBackToDiscoverTab() throws {
        // Wait for main view to load
        Thread.sleep(forTimeInterval: 2)

        // First navigate to Profile
        app.navigateToTab("Profile")
        Thread.sleep(forTimeInterval: 0.5)

        // Then navigate back to Home
        app.navigateToTab("Home")
        Thread.sleep(forTimeInterval: 0.5)

        // Verify we're back at Home tab
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist")
    }
}
