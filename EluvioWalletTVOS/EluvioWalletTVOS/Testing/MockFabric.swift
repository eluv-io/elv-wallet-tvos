//
//  MockFabric.swift
//  EluvioWalletTVOS
//
//  Mock implementation of FabricDataSource for UI testing.
//  Returns data from JSON files for fast, reliable tests.
//

import Foundation
import SwiftyJSON

class MockFabric: Fabric {

  override func getProperty(
    property: String,
    newFetch: Bool = false
  ) async throws -> MediaProperty? {
    debugPrint("MockFabric: returning mock property for \(property)")
    return MockData.property(id: property)
  }

  override func getUrlFromLink(
    link: JSON?,
    baseUrl: String? = nil,
    params: [JSON]? = [],
    includeAuth: Bool? = true,
    resolveHeaders: Bool? = false,
    staticUrl: Bool = false,
    hash: String = ""
  ) throws -> String {
    // Build placeholder URL from mock data structure
    let color = link?["color"].stringValue ?? "1a1a2e"
    let text = link?["text"].stringValue ?? "Mock"
    let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
    return "https://placehold.co/400x600/\(color)/ffffff.png?text=\(encodedText)"
  }

  override func getMediaItem(mediaId: String) -> MediaPropertySectionMediaItem? {
    debugPrint("MockFabric: returning mock media item for \(mediaId)")
    // Return a basic mock media item
    var item = MediaPropertySectionMediaItem()
    item.id = mediaId
    item.title = "Mock Media \(mediaId)"
    item.media_type = "video"
    return item
  }
}
