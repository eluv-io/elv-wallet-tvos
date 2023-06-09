//
//  AdditionalMediaModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-06.
//

import Foundation
import SwiftyJSON

protocol FeatureProtocol: Identifiable, Codable {
    var id: String? {get}
}

struct Features: Codable{
    var items: [NFTModel] = []
    var collections: [MediaCollection] = []
    var media: [MediaItem] = []
    var count: Int {
        get {
            return items.count + collections.count + media.count
        }
    }
    
    var isEmpty: Bool {
        get {
            return self.count == 0
        }
    }
    
    func unique() -> Features {
        return Features(items:items.unique(), collections:collections.unique(), media:media.unique())
    }
    
    mutating func append(_ obj: any FeatureProtocol){
        if let me = obj as? MediaItem {
            media.append(me)
        }else if let nft  = obj as? NFTModel{
            items.append(nft)
        }else if let col = obj as? MediaCollection {
            collections.append(col)
        }
        
    }
    
    mutating func append(contentsOf other: Features){
        items.append(contentsOf: other.items)
        collections.append(contentsOf: other.collections)
        media.append(contentsOf: other.media)
    }
}

protocol ViewModel: Identifiable, Codable, Equatable, Hashable {
    var id: String? { get set }
    
    static func == (lhs:any ViewModel, rhs:any ViewModel)
    
    func hash(into hasher: inout Hasher)
}

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

struct MediaItem: FeatureProtocol, Equatable, Hashable {
    var id: String? = UUID().uuidString
    var image: String? = ""
    var background_image_tv: JSON? = nil
    var background_image_tv_url: String? = ""
    var poster_image: JSON? = nil
    var poster_image_url: String? = ""
    
    var name: String = ""
    var image_aspect_ratio: String? = ""
    var media_type: String? = ""
    var requires_permissions: Bool = false
    var media_link: JSON? = nil
    var media_file: JSON? = nil
    var parameters: [JSON]? = []
    var gallery: [GalleryItem]? = []
    var offerings: [String]? = []
    
    //For Demo
    var isLive: Bool = false
    var schedule: [MediaItem]? = []
    var startDateTime: Date? = nil
    var startDateTimeString: String {
        let df = DateFormatter()
        df.dateFormat = "MMM d 'at' hh:mm a"
        df.amSymbol = "AM"
        df.pmSymbol = "PM"

        return df.string(from: startDateTime ?? Date())
    }
    var endDateTime: Date? = nil
    var endDateTimeString: String {
        let df = DateFormatter()
        df.dateFormat = "MMM d 'at' hh:mm a"
        df.amSymbol = "AM"
        df.pmSymbol = "PM"
        return df.string(from: endDateTime ?? Date())
    }
    
    init (){
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        image = try container.decodeIfPresent(String.self, forKey: .image) ?? ""
        background_image_tv = try container.decodeIfPresent(JSON.self, forKey: .background_image_tv)
        background_image_tv_url = try container.decodeIfPresent(String.self, forKey: .background_image_tv_url) ?? ""
        poster_image = try container.decodeIfPresent(JSON.self, forKey: .poster_image)
        poster_image_url = try container.decodeIfPresent(String.self, forKey: .poster_image_url) ?? ""
        name = try container.decode(String.self, forKey: .name)
        media_type = try container.decodeIfPresent(String.self, forKey: .media_type) ?? ""
        requires_permissions = try container.decode(Bool.self, forKey: .requires_permissions)
        image_aspect_ratio = try container.decodeIfPresent(String.self, forKey: .image_aspect_ratio) ?? ""
        media_link = try container.decodeIfPresent(JSON.self, forKey: .media_link)
        media_file = try container.decodeIfPresent(JSON.self, forKey: .media_file)
        parameters = try container.decodeIfPresent([JSON].self, forKey: .parameters) ?? []
        gallery = try container.decodeIfPresent([GalleryItem].self, forKey: .gallery) ?? []
        offerings = try container.decodeIfPresent([String].self, forKey: .offerings) ?? []
        id = /* try container.decodeIfPresent(String.self, forKey: .id) ??*/ name + (media_type ?? "")
        
        //TODO: compute from media_type when ready
        isLive = false
        schedule = []
        startDateTime = nil
        endDateTime = nil
    }
    
    //TODO: Find a good id for this
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct MediaCollection: FeatureProtocol, Equatable, Hashable {
    var id: String? = UUID().uuidString
    var display: String?
    var name: String = ""
    var media: [MediaItem] = []
    var collections: [MediaCollection]? = []
    
    //TODO: Find a good id for this
    static func == (lhs: MediaCollection, rhs: MediaCollection) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct GalleryItem: Identifiable, Codable, Equatable, Hashable {
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
        video = try container.decodeIfPresent(String.self, forKey: .video) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        image_aspect_ratio = try container.decodeIfPresent(String.self, forKey: .image_aspect_ratio) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        image = try container.decodeIfPresent(JSON.self, forKey: .image) ?? nil
    }
    
    static func == (lhs: GalleryItem, rhs: GalleryItem) -> Bool {
        return lhs.name == rhs.name && lhs.description == rhs.description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name + (description ?? ""))
    }
}
