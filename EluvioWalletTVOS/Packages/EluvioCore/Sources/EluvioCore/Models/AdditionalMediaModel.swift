//
//  AdditionalMediaModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-06.
//

import AVKit
import Foundation
import SwiftyJSON

public protocol FeatureProtocol: Identifiable, Codable {
  var id: String? { get }
}

public struct Features: Codable {
  public var items: [NFTModel] = []
  public var collections: [MediaCollection] = []
  public var media: [MediaItem] = []
  public var count: Int {
    return items.count + collections.count + media.count
  }

  public var isEmpty: Bool {
    return count == 0
  }

  public func unique() -> Features {
    return Features(items: items.unique(), collections: collections.unique(), media: media.unique())
  }

  public mutating func append(_ obj: any FeatureProtocol) {
    if let me = obj as? MediaItem {
      media.append(me)
    } else if let nft = obj as? NFTModel {
      items.append(nft)
    } else if let col = obj as? MediaCollection {
      collections.append(col)
    }
  }

  public mutating func append(contentsOf other: Features) {
    items.append(contentsOf: other.items)
    collections.append(contentsOf: other.collections)
    media.append(contentsOf: other.media)
  }
}

public struct AdditionalMediaModel: Identifiable, Codable {
  public var id: String? = UUID().uuidString
  public var featured_media: [MediaItem] = []
  public var sections: [MediaSection] = []
}

public struct MediaSection: Identifiable, Codable {
  public var id: String? = UUID().uuidString
  public var name: String = ""
  public var collections: [MediaCollection] = []
}

public struct TagMeta: Codable {
  public var key: String
  public var value: String
}

public struct MediaItem: FeatureProtocol, Equatable, Hashable {
  public var id: String? = UUID().uuidString
  /// There could be duplicates, bug in datamodel from fabric copy
  public var mediaId: String? = UUID().uuidString

  public var image: String? = ""
  public var poster_image: ImageLink?
  public var animation: JSON?

  public var name: String = ""
  public var description: String? = ""
  public var media_type: String? = ""
  public var media_link: JSON?
  public var media_file: JSON?
  public var gallery: [GalleryItem]? = []
  public var tags: [TagMeta]?

  // For Demo
  public var nft: NFTModel?
  public var isLive: Bool {
    return media_type == "Live Video"
  }

  public var location: String {
    for tag in tags ?? [] {
      if tag.key == "location" {
        return tag.value
      }
    }
    return ""
  }

  public func getTag(key: String) -> String {
    if let _tags = tags {
      for tag in _tags {
        if tag.key == key {
          return tag.value
        }
      }
    }
    return ""
  }

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    image = try container.decodeIfPresent(String.self, forKey: .image) ?? ""
    poster_image = try container.decodeIfPresent(ImageLink.self, forKey: .poster_image)
    animation = try container.decodeIfPresent(JSON.self, forKey: .animation)
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
    media_type = try container.decodeIfPresent(String.self, forKey: .media_type) ?? ""
    media_link = try container.decodeIfPresent(JSON.self, forKey: .media_link)
    media_file = try container.decodeIfPresent(JSON.self, forKey: .media_file)
    gallery = try container.decodeIfPresent([GalleryItem].self, forKey: .gallery) ?? []
    tags = try container.decodeIfPresent([TagMeta].self, forKey: .tags) ?? []

    mediaId = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
    id = (mediaId ?? "") + name
  }

  // TODO: Find a good id for this (using name because we have some media items with the same id due to an error in template copying)
  public static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

public struct MediaCollection: FeatureProtocol, Equatable, Hashable {
  public var id: String? = UUID().uuidString
  public var display: String?
  public var name: String = ""
  public var media: [MediaItem] = []
  public var collections: [MediaCollection]? = []

  // TODO: Find a good id for this
  public static func == (lhs: MediaCollection, rhs: MediaCollection) -> Bool {
    return lhs.name == rhs.name
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
}

public struct GalleryItem: Identifiable, Codable, Equatable, Hashable {
  public var id: String? = UUID().uuidString
  public var thumbnail: ImageLink?
  public var video: JSON?
  public var name: String = ""
  public var description: String?

  public init() {
    id = UUID().uuidString
    thumbnail = nil
    video = nil
    name = ""
    description = ""
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    video = try container.decodeIfPresent(JSON.self, forKey: .video) ?? nil
    thumbnail = try container.decodeIfPresent(ImageLink.self, forKey: .thumbnail) ?? nil
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
  }

  public static func == (lhs: GalleryItem, rhs: GalleryItem) -> Bool {
    return lhs.name == rhs.name && lhs.description == rhs.description
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(name + (description ?? ""))
  }

  public static func create(propertyMedia: MediaPropertySectionMediaItem) -> GalleryItem {
    let thumbLink: ImageLink? =
      propertyMedia.thumbnail_image_square
      ?? propertyMedia.thumbnail_image_portrait
      ?? propertyMedia.thumbnail_image_landscape

    let videoLink = propertyMedia.media_link

    var item = GalleryItem()

    item.id = propertyMedia.id
    item.thumbnail = thumbLink
    item.video = videoLink
    item.description = propertyMedia.description ?? ""
    item.name = propertyMedia.title ?? ""

    return item
  }
}
