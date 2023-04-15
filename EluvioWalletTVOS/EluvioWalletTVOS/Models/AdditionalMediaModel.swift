//
//  AdditionalMediaModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-06.
//

import Foundation
import SwiftyJSON

struct AdditionalMediaModel: Identifiable, Codable {
    var id: String? = UUID().uuidString
    var featured_media : [MediaItem] = []
    var sections : [MediaSection] = []
}

struct MediaSection: Identifiable, Codable {
    var id: String? = UUID().uuidString
    var name : String = ""
    var collections : [MediaCollection] = []
}

struct MediaItem: Identifiable, Codable {
    var id: String? = UUID().uuidString
    var image: String?
    var name: String = ""
    var image_aspect_ratio: String?
    var media_type: String?
    var requires_permissions: Bool = false
    var media_link: JSON? = nil
    var media_file: JSON? = nil
    var parameters: [JSON] = []
    var gallery: [GalleryItem]
    var offerings: [String] = []
}

struct MediaCollection: Identifiable, Codable {
    var id: String? = UUID().uuidString
    var display: String?
    var name: String = ""
    var media: [MediaItem] = []
}

struct GalleryItem: Identifiable, Codable {
    var id: String? = UUID().uuidString
    var image: JSON?
    var video: String?
    var name: String = ""
    var image_aspect_ratio: String?
    var description: String?
    
    init (){
        id = UUID().uuidString
        image = nil
        video = ""
        name = ""
        image_aspect_ratio = ""
        description = ""
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        video = try container.decode(String.self, forKey: .video)
        name = try container.decode(String.self, forKey: .name)
        image_aspect_ratio = try container.decodeIfPresent(String.self, forKey: .image_aspect_ratio)
        description = try container.decode(String.self, forKey: .description)
        image = try container.decode(JSON.self, forKey: .image)
    }
}
