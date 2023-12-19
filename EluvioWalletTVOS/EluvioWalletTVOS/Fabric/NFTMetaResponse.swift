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

struct MetaTag: Codable {
    var key: String
    var value: String
}

struct NFTTrait: Codable {
    var trait_type : String?
    var value : String?
    var rarity : String?
}

// MARK: - NFTMetaResponse
struct NFTMetaResponse: Codable {
    var address: String? = ""
    var attributes: [NFTTrait]? = []
    var attributesDict: [String: NFTTrait] {
        if let attributes = self.attributes {
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
    
    var tags: [MetaTag]? = []
    
    //var backgroundColor: BackgroundColor = BackgroundColor()
    var copyright: String? = ""
    var createdAt: String? = ""
    var creator: String? = ""
    var description: String? = ""
    var short_description: String? = ""
    var displayName: String? = ""
    var editionName: String? = ""
    var embedURL: String? = ""
    var enableWatermark: Bool? = false
    var externalURL: String? = ""
    var image: String? = ""
    //var marketplaceAttributes: MarketplaceAttributes = MarketplaceAttributes()
    var name: String? = ""
    var packOptions: PackOptions?
    var additional_media_sections: AdditionalMediaModel? = nil
    var playable: Bool? = false
    var templateID: String? = ""
    var totalSupply: Int? = 0

    enum CodingKeys: String, CodingKey {
        case address, attributes, tags
        //case backgroundColor = "background_color"
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
        //case marketplaceAttributes = "marketplace_attributes"
        case name
        case packOptions = "pack_options"
        case playable
        case templateID = "template_id"
        case totalSupply = "total_supply"
    }

}

// MARK: - BackgroundColor
struct BackgroundColor: Codable {
    var color: String = ""
    var label: String = ""
}

// MARK: - MarketplaceAttributes
struct MarketplaceAttributes: Codable {
    var eluvio: Eluvio = Eluvio()
    var opensea: Opensea = Opensea()

    enum CodingKeys: String, CodingKey {
        case eluvio = "Eluvio"
        case opensea
    }
}

// MARK: - Eluvio
struct Eluvio: Codable {
    var marketplaceID : String = ""
    var sku: String = ""

    enum CodingKeys: String, CodingKey {
        case marketplaceID = "marketplace_id"
        case sku
    }
}

// MARK: - Opensea
struct Opensea: Codable {
    var youtubeURL: String = ""

    enum CodingKeys: String, CodingKey {
        case youtubeURL = "youtube_url"
    }
}

// MARK: - PackOptions
struct PackOptions: Codable {
    var isOpenable: Bool?
    var itemSlots: [JSONAny]? = []
    var openAnimation: JSON? = ""
    var revealAnimation: JSON? = ""
    var openButtonText: String? = ""
    var packGenerator: String? = ""

    enum CodingKeys: String, CodingKey {
        case isOpenable = "is_openable"
        case itemSlots = "item_slots"
        case openAnimation = "open_animation"
        case revealAnimation = "reveal_animation"
        case openButtonText = "open_button_text"
        case packGenerator = "pack_generator"
    }
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }

    required init?(stringValue: String) {
        key = stringValue
    }

    var intValue: Int? {
        return nil
    }

    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {

    let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
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

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
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

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
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

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
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

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
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

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
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
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
