//
//  NFTMetaResponse.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-16.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let nFTModel = try? newJSONDecoder().decode(NFTMetaResponse.self, from: jsonData)

import Foundation
import SwiftyJSON

public struct MetaTag: Codable {
  public var key: String
  public var value: String
}

public struct NFTTrait: Codable {
  public var trait_type: String?
  public var value: String?
  public var rarity: String?
}

// MARK: - NFTMetaResponse

public struct NFTMetaResponse: Codable {
  public var address: String? = ""
  public var attributes: [NFTTrait]? = []
  public var attributesDict: [String: NFTTrait] {
    if let attributes = attributes {
      var dict: [String: NFTTrait] = [:]
      for attribute in attributes {
        if let trait = attribute.trait_type {
          dict[trait] = attribute
        }
      }
      return dict
    }

    return [:]
  }

  public var tags: [MetaTag]? = []

  // var backgroundColor: BackgroundColor = BackgroundColor()
  public var copyright: String? = ""
  public var createdAt: String? = ""
  public var creator: String? = ""
  public var description: String? = ""
  public var short_description: String? = ""
  public var displayName: String? = ""
  public var editionName: String? = ""
  public var embedURL: String? = ""
  public var enableWatermark: Bool? = false
  public var externalURL: String? = ""
  public var image: String? = ""
  // var marketplaceAttributes: MarketplaceAttributes = MarketplaceAttributes()
  public var name: String? = ""
  public var packOptions: PackOptions?
  public var additional_media_sections: AdditionalMediaModel? = nil
  public var playable: Bool? = false
  public var templateID: String? = ""
  public var totalSupply: Int? = 0

  public enum CodingKeys: String, CodingKey {
    case address, attributes, tags
    // case backgroundColor = "background_color"
    case copyright
    case createdAt = "created_at"
    case creator
    case description
    case short_description
    case displayName = "display_name"
    case editionName = "edition_name"
    case embedURL = "embed_url"
    case enableWatermark = "enable_watermark"
    case externalURL = "external_url"
    case image
    // case marketplaceAttributes = "marketplace_attributes"
    case name
    case packOptions = "pack_options"
    case playable
    case templateID = "template_id"
    case totalSupply = "total_supply"
  }
}

// MARK: - PackOptions

public struct PackOptions: Codable {
  public var isOpenable: Bool?
  public var itemSlots: [JSONAny]? = []
  public var openAnimation: JSON? = ""
  public var revealAnimation: JSON? = ""
  public var openButtonText: String? = ""
  public var packGenerator: String? = ""

  public enum CodingKeys: String, CodingKey {
    case isOpenable = "is_openable"
    case itemSlots = "item_slots"
    case openAnimation = "open_animation"
    case revealAnimation = "reveal_animation"
    case openButtonText = "open_button_text"
    case packGenerator = "pack_generator"
  }
}

// MARK: - Encode/decode helpers

public class JSONNull: Codable, Hashable {
  public static func == (_: JSONNull, _: JSONNull) -> Bool {
    return true
  }

  public var hashValue: Int {
    return 0
  }

  public init() {}

  public required init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if !container.decodeNil() {
      throw DecodingError.typeMismatch(
        JSONNull.self,
        DecodingError.Context(
          codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encodeNil()
  }
}

public class JSONCodingKey: CodingKey {
  public let key: String

  public required init?(intValue _: Int) {
    return nil
  }

  public required init?(stringValue: String) {
    key = stringValue
  }

  public var intValue: Int? {
    return nil
  }

  public var stringValue: String {
    return key
  }
}

public class JSONAny: Codable {
  public let value: Any

  public static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
    let context = DecodingError.Context(
      codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
    return DecodingError.typeMismatch(JSONAny.self, context)
  }

  public static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
    let context = EncodingError.Context(
      codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
    return EncodingError.invalidValue(value, context)
  }

  public static func decode(from container: SingleValueDecodingContainer) throws -> Any {
    if let value = try? container.decode(Bool.self) {
      return value
    }
    if let value = try? container.decode(Int64.self) {
      return value
    }
    if let value = try? container.decode(Double.self) {
      return value
    }
    if let value = try? container.decode(String.self) {
      return value
    }
    if container.decodeNil() {
      return JSONNull()
    }
    throw decodingError(forCodingPath: container.codingPath)
  }

  public static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
    if let value = try? container.decode(Bool.self) {
      return value
    }
    if let value = try? container.decode(Int64.self) {
      return value
    }
    if let value = try? container.decode(Double.self) {
      return value
    }
    if let value = try? container.decode(String.self) {
      return value
    }
    if let value = try? container.decodeNil() {
      if value {
        return JSONNull()
      }
    }
    if var container = try? container.nestedUnkeyedContainer() {
      return try decodeArray(from: &container)
    }
    if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
      return try decodeDictionary(from: &container)
    }
    throw decodingError(forCodingPath: container.codingPath)
  }

  public static func decode(
    from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey
  ) throws -> Any {
    if let value = try? container.decode(Bool.self, forKey: key) {
      return value
    }
    if let value = try? container.decode(Int64.self, forKey: key) {
      return value
    }
    if let value = try? container.decode(Double.self, forKey: key) {
      return value
    }
    if let value = try? container.decode(String.self, forKey: key) {
      return value
    }
    if let value = try? container.decodeNil(forKey: key) {
      if value {
        return JSONNull()
      }
    }
    if var container = try? container.nestedUnkeyedContainer(forKey: key) {
      return try decodeArray(from: &container)
    }
    if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
      return try decodeDictionary(from: &container)
    }
    throw decodingError(forCodingPath: container.codingPath)
  }

  public static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
    var arr: [Any] = []
    while !container.isAtEnd {
      let value = try decode(from: &container)
      arr.append(value)
    }
    return arr
  }

  public static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws
    -> [String: Any]
  {
    var dict = [String: Any]()
    for key in container.allKeys {
      let value = try decode(from: &container, forKey: key)
      dict[key.stringValue] = value
    }
    return dict
  }

  public static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
    for value in array {
      if let value = value as? Bool {
        try container.encode(value)
      } else if let value = value as? Int64 {
        try container.encode(value)
      } else if let value = value as? Double {
        try container.encode(value)
      } else if let value = value as? String {
        try container.encode(value)
      } else if value is JSONNull {
        try container.encodeNil()
      } else if let value = value as? [Any] {
        var container = container.nestedUnkeyedContainer()
        try encode(to: &container, array: value)
      } else if let value = value as? [String: Any] {
        var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
        try encode(to: &container, dictionary: value)
      } else {
        throw encodingError(forValue: value, codingPath: container.codingPath)
      }
    }
  }

  public static func encode(
    to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]
  ) throws {
    for (key, value) in dictionary {
      let key = JSONCodingKey(stringValue: key)!
      if let value = value as? Bool {
        try container.encode(value, forKey: key)
      } else if let value = value as? Int64 {
        try container.encode(value, forKey: key)
      } else if let value = value as? Double {
        try container.encode(value, forKey: key)
      } else if let value = value as? String {
        try container.encode(value, forKey: key)
      } else if value is JSONNull {
        try container.encodeNil(forKey: key)
      } else if let value = value as? [Any] {
        var container = container.nestedUnkeyedContainer(forKey: key)
        try encode(to: &container, array: value)
      } else if let value = value as? [String: Any] {
        var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        try encode(to: &container, dictionary: value)
      } else {
        throw encodingError(forValue: value, codingPath: container.codingPath)
      }
    }
  }

  public static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
    if let value = value as? Bool {
      try container.encode(value)
    } else if let value = value as? Int64 {
      try container.encode(value)
    } else if let value = value as? Double {
      try container.encode(value)
    } else if let value = value as? String {
      try container.encode(value)
    } else if value is JSONNull {
      try container.encodeNil()
    } else {
      throw encodingError(forValue: value, codingPath: container.codingPath)
    }
  }

  public required init(from decoder: Decoder) throws {
    if var arrayContainer = try? decoder.unkeyedContainer() {
      value = try JSONAny.decodeArray(from: &arrayContainer)
    } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
      value = try JSONAny.decodeDictionary(from: &container)
    } else {
      let container = try decoder.singleValueContainer()
      value = try JSONAny.decode(from: container)
    }
  }

  public func encode(to encoder: Encoder) throws {
    if let arr = value as? [Any] {
      var container = encoder.unkeyedContainer()
      try JSONAny.encode(to: &container, array: arr)
    } else if let dict = value as? [String: Any] {
      var container = encoder.container(keyedBy: JSONCodingKey.self)
      try JSONAny.encode(to: &container, dictionary: dict)
    } else {
      var container = encoder.singleValueContainer()
      try JSONAny.encode(to: &container, value: value)
    }
  }
}
