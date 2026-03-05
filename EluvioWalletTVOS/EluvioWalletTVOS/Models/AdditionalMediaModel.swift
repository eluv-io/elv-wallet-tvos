//
//  AdditionalMediaModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-06.
//

import AVKit
import Foundation
import SwiftyJSON

protocol FeatureProtocol: Identifiable, Codable {
  var id: String? { get }
}

struct Features: Codable {
  var items: [NFTModel] = []
  var collections: [MediaCollection] = []
  var media: [MediaItem] = []
  var count: Int {
    return items.count + collections.count + media.count
  }

  var isEmpty: Bool {
    return count == 0
  }

  func unique() -> Features {
    return Features(items: items.unique(), collections: collections.unique(), media: media.unique())
  }

  mutating func append(_ obj: any FeatureProtocol) {
    if let me = obj as? MediaItem {
      media.append(me)
    } else if let nft = obj as? NFTModel {
      items.append(nft)
    } else if let col = obj as? MediaCollection {
      collections.append(col)
    }
  }

  mutating func append(contentsOf other: Features) {
    items.append(contentsOf: other.items)
    collections.append(contentsOf: other.collections)
    media.append(contentsOf: other.media)
  }
}

struct AdditionalMediaModel: Identifiable, Codable {
  var id: String? = UUID().uuidString
  var featured_media: [MediaItem] = []
  var sections: [MediaSection] = []
}

struct MediaSection: Identifiable, Codable {
  var id: String? = UUID().uuidString
  var name: String = ""
  var collections: [MediaCollection] = []
}

struct TagMeta: Codable {
  var key: String
  var value: String
}

struct MediaItem: FeatureProtocol, Equatable, Hashable {
  var id: String? = UUID().uuidString
  /// There could be duplicates, bug in datamodel from fabric copy
  var mediaId: String? = UUID().uuidString

  var image: String? = ""
  var poster_image: ImageLink?
  var animation: JSON?

  var name: String = ""
  var description: String? = ""
  var media_type: String? = ""
  var media_link: JSON?
  var media_file: JSON?
  var gallery: [GalleryItem]? = []
  var tags: [TagMeta]?

  // For Demo
  var nft: NFTModel?
  var isLive: Bool {
    return media_type == "Live Video"
  }

  var location: String {
    for tag in tags ?? [] {
      if tag.key == "location" {
        return tag.value
      }
    }
    return ""
  }

  func getTag(key: String) -> String {
    if let _tags = tags {
      for tag in _tags {
        if tag.key == key {
          return tag.value
        }
      }
    }
    return ""
  }

  init() {}

  init(from decoder: Decoder) throws {
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
  static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

struct MediaCollection: FeatureProtocol, Equatable, Hashable {
  var id: String? = UUID().uuidString
  var display: String?
  var name: String = ""
  var media: [MediaItem] = []
  var collections: [MediaCollection]? = []

  // TODO: Find a good id for this
  static func == (lhs: MediaCollection, rhs: MediaCollection) -> Bool {
    return lhs.name == rhs.name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
}

struct GalleryItem: Identifiable, Codable, Equatable, Hashable {
  var id: String? = UUID().uuidString
  var thumbnail: ImageLink?
  var video: JSON?
  var name: String = ""
  var description: String?

  init() {
    id = UUID().uuidString
    thumbnail = nil
    video = nil
    name = ""
    description = ""
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    video = try container.decodeIfPresent(JSON.self, forKey: .video) ?? nil
    thumbnail = try container.decodeIfPresent(ImageLink.self, forKey: .thumbnail) ?? nil
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
  }

  static func == (lhs: GalleryItem, rhs: GalleryItem) -> Bool {
    return lhs.name == rhs.name && lhs.description == rhs.description
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(name + (description ?? ""))
  }

  static func create(propertyMedia: MediaPropertySectionMediaItem) -> GalleryItem {
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
