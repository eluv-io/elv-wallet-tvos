//
//  XCUIRemoteHelpers.swift
//  EluvioWalletTVOSUITests
//
//  Helpers for simulating tvOS Siri Remote interactions
//

import XCTest

extension XCUIRemote {
  /// Press a button multiple times with a delay between presses
  func press(_ button: Button, times: Int, delay: TimeInterval = 0.3) {
    for _ in 0..<times {
      press(button)
      Thread.sleep(forTimeInterval: delay)
    }
  }
}

extension XCUIApplication {
  /// Check if any tab bar button currently has focus
  func isTabBarFocused() -> Bool {
    let tabBar = tabBars.firstMatch
    guard tabBar.exists else { return false }
    let buttons = tabBar.buttons
    for i in 0..<buttons.count {
      if buttons.element(boundBy: i).hasFocus {
        return true
      }
    }
    return false
  }

  /// Navigate to the tab bar by pressing up repeatedly until focused
  func focusTabBar(maxPresses: Int = 10) {
    for _ in 0..<maxPresses {
      if isTabBarFocused() {
        return
      }
      XCUIRemote.shared.press(.up)
      Thread.sleep(forTimeInterval: 0.2)
    }
  }

  /// Navigate to a specific tab by name
  func navigateToTab(_ tabName: String) {
    let tabButton = tabBars.buttons[tabName]

    // If tab already has focus, just select it
    if tabButton.hasFocus {
      XCUIRemote.shared.press(.select)
      Thread.sleep(forTimeInterval: 0.5)
      return
    }

    focusTabBar()
    Thread.sleep(forTimeInterval: 0.3)

    guard tabButton.exists else { return }

    // Navigate left until we can't go further (at leftmost position)
    for _ in 0..<5 {
      if tabBars.buttons.element(boundBy: 0).hasFocus {
        break
      }
      XCUIRemote.shared.press(.left)
      Thread.sleep(forTimeInterval: 0.2)
    }

    // Navigate right until we find our tab
    for _ in 0..<5 {
      if tabButton.hasFocus {
        XCUIRemote.shared.press(.select)
        Thread.sleep(forTimeInterval: 0.5)
        return
      }
      XCUIRemote.shared.press(.right)
      Thread.sleep(forTimeInterval: 0.2)
    }
  }

  /// Wait for an element to exist with timeout
  func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
    return element.waitForExistence(timeout: timeout)
  }

  /// Navigate down and select an item, with optional focus target verification
  func navigateDownAndSelect(presses: Int = 1, target: XCUIElement? = nil) {
    for i in 0..<presses {
      // If target provided and already focused, stop navigating
      if let target = target, target.hasFocus {
        break
      }
      XCUIRemote.shared.press(.down)
      Thread.sleep(forTimeInterval: 0.2)
    }
    Thread.sleep(forTimeInterval: 0.1)
    XCUIRemote.shared.press(.select)
  }

  /// Go back using menu button, with optional verification
  func goBack(verifyElement: XCUIElement? = nil, timeout: TimeInterval = 2) {
    XCUIRemote.shared.press(.menu)
    if let element = verifyElement {
      _ = element.waitForExistence(timeout: timeout)
    } else {
      Thread.sleep(forTimeInterval: 0.5)
    }
  }

  /// Find any element by accessibility identifier (searches all element types)
  func findElement(identifier: String) -> XCUIElement {
    return descendants(matching: .any)[identifier]
  }

  /// Wait for any element with identifier to exist
  func waitForIdentifier(_ identifier: String, timeout: TimeInterval = 10) -> Bool {
    return findElement(identifier: identifier).waitForExistence(timeout: timeout)
  }
}
