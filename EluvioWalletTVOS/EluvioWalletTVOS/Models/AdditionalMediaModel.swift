//
//  AdditionalMediaModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-06.
//

import Foundation
import SwiftyJSON
import AVKit

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

struct MediaItemViewModel:Identifiable {
    
    static func create(fabric:Fabric, mediaItem: MediaItem?) async throws -> MediaItemViewModel {
        guard let media = mediaItem else{
            return MediaItemViewModel()
        }
        
        var offering = "default"
        if let offerings = mediaItem?.offerings {
            if !offerings.isEmpty {
                if offerings[0] != "" {
                    offering = offerings[0]
                    //print("Offering:",offering)
                }
            }
        }
        
        var animationItem : AVPlayerItem? = nil
        if let animationLink = media.animation?["sources"]["default"] {
            animationItem = try await MakePlayerItemFromLink(fabric: fabric, link: animationLink)
        }
        
        var posterImage = ""
        if media.poster_image != nil {
            do{
                posterImage = try fabric.getUrlFromLink(link: media.poster_image)
            }catch{
                print("Error creating MediaItemViewModel posterImage",error)
            }
        }
        
        var backgroundImage=""
        if media.background_image_tv != nil {
            do{
                backgroundImage = try fabric.getUrlFromLink(link: media.background_image_tv)
            }catch{
                print("Error creating MediaItemViewModel backgroundImage",error)
            }
        }
        
        var backgroundLogo=""
        if media.background_image_logo_tv != nil {
            do{
                backgroundLogo = try fabric.getUrlFromLink(link: media.background_image_logo_tv)
            }catch{
                print("Error creating MediaItemViewModel backgroundImage",error)
            }
        }
        
        let optionsLink = media.media_link?["sources"]["default"]
        
        var mediaHash = ""
        if let link = media.media_link?["."]{
            mediaHash = link["source"].stringValue
        }
        
        var htmlUrl: String = ""
        if media.media_file != nil {
            if media.media_type == "HTML" {
                do{
                    htmlUrl = try fabric.getMediaHTML(link: media.media_file, params: media.parameters ?? [])
                }catch{
                    print("Error creating MediaItemViewModel",error)
                }
            }
        }
        
        var mediaCollection : MediaCollection?
        var mediaSection : MediaSection?
        
        if (media.media_type == "Media Reference"){
            if let sectionId = media.media_reference?.section_id {
                if sectionId != "" {
                    if let sections = media.nft?.additional_media_sections?.sections {
                        for section in sections {
                            if (section.id == sectionId){
                                mediaSection = section
                                break;
                            }
                        }
                    }
                }
            } else if let collectionId = media.media_reference?.collection_id {
                if collectionId != "" {
                    if let sections = media.nft?.additional_media_sections?.sections {
                        for section in sections {
                            for collection in section.collections {
                                if (collection.id == collectionId){
                                    mediaCollection = collection
                                    break;
                                }
                            }
                            if mediaCollection != nil {
                                break;
                            }
                        }
                    }
                }
            }
        }
        
        let subtitle1 = media.subtitle_1 ?? ""
        let subtitle2 = media.subtitle_2 ?? ""
        let description = media.description ?? ""
        let descriptionText = media.description_text ?? ""
        
        return MediaItemViewModel(
            id: media.id,
            mediaId: media.mediaId,
            backgroundImage: backgroundImage,
            titleLogo: backgroundLogo,
            image: media.image ?? "",
            imageRatio : media.image_aspect_ratio ?? "Square",
            posterImage: posterImage,
            animation:animationItem,
            name:media.name ,
            subtitle1: subtitle1,
            subtitle2: subtitle2,
            description: description,
            description_text: descriptionText,
            mediaType:media.media_type ?? "",
            defaultOptionsLink:optionsLink,
            parameters: media.parameters,
            htmlUrl:htmlUrl,
            tags: media.tags ?? [],
            offering: offering,
            gallery: media.gallery ?? [],
            mediaHash: mediaHash,
            mediaSection: mediaSection,
            mediaCollection: mediaCollection,
            nft: media.nft
        )
        
    }
    
    var id: String? = UUID().uuidString
    var mediaId: String? = UUID().uuidString
    var backgroundImage: String = ""
    var titleLogo: String = ""
    var image: String = ""
    var imageRatio: String = "Square"
    var posterImage: String = ""
    var animation: AVPlayerItem? = nil
    var name: String = ""
    var subtitle1: String = ""
    var subtitle2: String = ""
    var description: String = ""
    var description_text: String = ""
    var mediaType: String = ""
    var defaultOptionsLink: JSON? = nil
    var parameters: [JSON]? = []
    var htmlUrl: String = ""
    var isLive: Bool {
        return self.mediaType == "Live Video"
    }
    var tags: [TagMeta] = []
    var offering: String = "default"
    var gallery: [GalleryItem] = []
    var mediaHash: String = ""
    var mediaSection: MediaSection? = nil
    var mediaCollection: MediaCollection? = nil
    var hidden = false
    var locked = false
    
    var nft: NFTModel? = nil

    
    var contentTag: String {
        for tag in tags {
            if tag.key == "content" {
                return tag.value
            }
        }
        return ""
    }
    
    var location: String {
        for tag in tags {
            if tag.key == "location" {
                return tag.value
            }
        }
        return ""
    }
    
    var isReference: Bool {
        if mediaType == "Media Reference" {
            return true
        }
        
        return false
    }
    
    func getTag(key:String)->String {
        for tag in tags {
            if(tag.key == key){
                return tag.value
            }
        }

        return ""
    }
    
    var mediaInfo: [(String,String)]{
        var info: [(String,String)] = []
        
        let director = getTag(key:"Director")
        if !director.isEmpty {
            info.append(("Director:",director))
        }
        
        let producer = getTag(key:"Producer")
        if !producer.isEmpty{
            info.append(("Producer:",producer))
        }
        
        let language = getTag(key:"Language")
        if !language.isEmpty{
            info.append(("Languages:",language))
        }
        
        let cast = getTag(key:"Cast")
        if !cast.isEmpty{
            info.append(("Cast:",language))
        }
        
        let rating = getTag(key:"Rating")
        if !rating.isEmpty{
            info.append(("Rating:",rating))
        }
        
        let release = getTag(key:"Release Date")
        if !release.isEmpty{
            info.append(("Release Date:",release))
        }
        
        let style = getTag(key:"Style")
        if !style.isEmpty{
            info.append(("Style:",style))
        }
        
        return info
    }

}

struct TagMeta: Codable {
    var key: String
    var value: String
}

struct MediaReference: Codable {
    var collection_id: String? = ""
    var section_id: String? = ""
}

struct MediaItem: FeatureProtocol, Equatable, Hashable {
    var id: String? = UUID().uuidString
    //There could be duplicates, bug in datamodel from fabric copy
    var mediaId: String? = UUID().uuidString
    
    var image: String? = ""
    var background_image_tv: JSON? = nil
    var background_image_tv_url: String? = ""
    var background_image_logo_tv: JSON? = nil
    
    var poster_image: JSON? = nil
    var poster_image_url: String? = ""
    var animation: JSON? = nil
    
    var name: String = ""
    var description: String? = ""
    var description_text: String? = ""
    var subtitle_1: String? = ""
    var subtitle_2: String? = ""
    var image_aspect_ratio: String? = ""
    var media_type: String? = ""
    var requires_permissions: Bool = false
    var media_link: JSON? = nil
    var media_file: JSON? = nil
    var parameters: [JSON]? = []
    var gallery: [GalleryItem]? = []
    var offerings: [String]? = []
    var tags: [TagMeta]?
    var media_reference: MediaReference? = nil
    var locked: Bool? = false
    var locked_state: JSON?
    
    //For Demo
    var nft: NFTModel? = nil
    var isLive: Bool {
        return self.media_type == "Live Video"
    }
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
    
    var location: String {
        for tag in tags ?? []{
            if tag.key == "location" {
                return tag.value
            }
        }
        return ""
    }
    
    func getTag(key:String)->String {
        if let _tags = self.tags {
            for tag in _tags {
                if(tag.key == key){
                    return tag.value
                }
            }
        }
        return ""
    }
    
    init (){
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        image = try container.decodeIfPresent(String.self, forKey: .image) ?? ""
        background_image_tv = try container.decodeIfPresent(JSON.self, forKey: .background_image_tv)
        background_image_tv_url = try container.decodeIfPresent(String.self, forKey: .background_image_tv_url) ?? ""
        background_image_logo_tv = try container.decodeIfPresent(JSON.self, forKey: .background_image_logo_tv)
        poster_image = try container.decodeIfPresent(JSON.self, forKey: .poster_image)
        animation = try container.decodeIfPresent(JSON.self, forKey: .animation)
        poster_image_url = try container.decodeIfPresent(String.self, forKey: .poster_image_url) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        subtitle_1 = try container.decodeIfPresent(String.self, forKey: .subtitle_1) ?? ""
        subtitle_2 = try container.decodeIfPresent(String.self, forKey: .subtitle_2) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        description_text = try container.decodeIfPresent(String.self, forKey: .description_text) ?? ""
        media_type = try container.decodeIfPresent(String.self, forKey: .media_type) ?? ""
        requires_permissions = try container.decodeIfPresent(Bool.self, forKey: .requires_permissions) ?? false
        image_aspect_ratio = try container.decodeIfPresent(String.self, forKey: .image_aspect_ratio) ?? ""
        media_link = try container.decodeIfPresent(JSON.self, forKey: .media_link)
        media_file = try container.decodeIfPresent(JSON.self, forKey: .media_file)
        parameters = try container.decodeIfPresent([JSON].self, forKey: .parameters) ?? []
        gallery = try container.decodeIfPresent([GalleryItem].self, forKey: .gallery) ?? []
        offerings = try container.decodeIfPresent([String].self, forKey: .offerings) ?? []
        tags = try container.decodeIfPresent([TagMeta].self, forKey: .tags) ?? []
        media_reference = try container.decodeIfPresent(MediaReference.self, forKey: .media_reference) ?? nil
        
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked) ?? false
        if locked ?? false {
            locked_state = try container.decodeIfPresent(JSON.self, forKey: .locked_state)
        }
        
        mediaId = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        
        id = (mediaId ?? "")  + name
        
        //TODO: compute from media_type when ready
        schedule = []
        startDateTime = nil
        endDateTime = nil
    }
    
    //TODO: Find a good id for this (using name because we have some media items with the same id due to an error in template copying)
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
    var video: JSON?
    var name: String = ""
    var image_aspect_ratio: String?
    var description: String?
    
    init (){
        id = UUID().uuidString
        image = nil
        video = nil
        name = ""
        image_aspect_ratio = ""
        description = ""
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        video = try container.decodeIfPresent(JSON.self, forKey: .video) ?? nil
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
