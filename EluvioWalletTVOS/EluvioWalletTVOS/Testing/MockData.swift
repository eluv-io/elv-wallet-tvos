//
//  MockData.swift
//  EluvioWalletTVOS
//
//  Mock data for UI testing - loads from JSON files for easy maintenance
//

import Foundation
import SwiftyJSON

enum MockData {
  /// Check if app is running with mock data enabled
  static var isEnabled: Bool {
    ProcessInfo.processInfo.arguments.contains("MOCK_DATA")
  }

  /// Check if login should be disabled for mock properties
  static var disableLogin: Bool {
    ProcessInfo.processInfo.arguments.contains("MOCK_DISABLE_LOGIN")
  }

  /// Load mock properties from JSON file
  static var properties: [MediaProperty] {
    let response: MediaPropertiesResponse = loadJsonFileFatal("MockProperties.json")

    // Apply disable_login setting if needed
    if disableLogin {
      for property in response.contents {
        property.login?.settings?.disable_login = true
      }
    }

    return response.contents
  }

  /// Load mock sections from JSON file
  static var sections: [MediaPropertySection] {
    let response: MediaPropertySectionsResponse = loadJsonFileFatal("MockSections.json")
    return response.contents
  }

  /// Get a specific mock property by ID
  static func property(id: String) -> MediaProperty? {
    return properties.first { $0.id == id } ?? properties.first
  }
}
