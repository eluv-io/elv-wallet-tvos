//
//  PropertyModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-17.
//

import Foundation
import SwiftyJSON

public struct PropertyModel: Identifiable, Codable {
  public var id: String? = UUID().uuidString
  public var title: String? = ""
  public var logo: String? = ""
  public var image: String? = ""
  public var heroImage: String? = ""
  public var parent_id: String? = ""
  public var featured: Features = .init()
  public var media: [MediaCollection] = []
  public var albums: [NFTModel] = []  // Temporary until we have proper albums
  public var live_streams: [MediaItem]  // Temp. Need to do a new LiveMediaItem model?
  public var sections: [MediaSection] = []
  public var contents: [ProjectModel] = []

  public var isEmpty: Bool {
    if let first = contents.first {
      return first.contents.isEmpty
    } else {
      return contents.isEmpty
    }
  }
}

public struct ProjectModel: Identifiable, Codable {
  public var id: String? = UUID().uuidString
  public var title: String? = ""
  public var description: String? = ""
  public var image: String? = ""
  public var image_wide: String? = ""
  public var background_image_tv: String? = ""
  public var parent_id: String? = ""
  public var property: PropertyModel? = nil
  public var contents: [NFTModel] = []
}
