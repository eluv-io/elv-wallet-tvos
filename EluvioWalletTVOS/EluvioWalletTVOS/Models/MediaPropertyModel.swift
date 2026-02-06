//
//  MediaPropertyModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-10.
//

import Foundation
import SwiftyJSON
import AVFoundation

class MediaProperty: Codable, Identifiable, Hashable {
    var associated_marketplaces : [AssociatedMarketplaces]?
    var header_logo : JSON?
    var id : String?
    var image : JSON?
    var image_tv : JSON?
    var start_screen_logo: JSON?
    var start_screen_background: JSON?
    var login: JSON?
    var name : String?
    var title: String?
    var page_title : String?
    var parent_id : String?
    var main_page : MediaPropertyPage?
    var media_catalogs : [String]?
    var page_ids : [String]?
    var permission_auth_state : JSON?
    var permission_auth_state_raw : JSON?
    var permission_sets : [String]?
    var permissions : JSON?
    var require_login : Bool?
    var slug : String?
    var sections : [String : MediaPropertySection]?
    var purchase_settings : JSON?
    var subproperties : [String]?
    var tenant : JSON?
    var property_selection: JSON?
    var domain: JSON?
    
    static func == (lhs: MediaProperty, rhs: MediaProperty) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AssociatedMarketplaces: Codable {
    var marketplace_id : String
    var marketplace_slug : String
    var tenant_slug : String
}

struct MediaPropertyPageLayout: Codable {
    
}

struct MediaPropertyPage: Codable {
    var id : String? = UUID().uuidString
    var label : String?
    var layout : JSON?
    var permissions : JSON?
    var slug : String?
    var sections : [String]?
}

struct MediaPropertySection: Codable, Identifiable, Hashable {
    var id : String = UUID().uuidString
    var content : [MediaPropertySectionItem]? = []
    var description : String?
    var authorized : Bool?
    var display : JSON?
    var label : String?
    var permissions : JSON?
    var type : String?
    var hero_items: JSON?
    var sections: [String]?
    var resolvedPermission : ResolvedPermission? = nil
    
    var displayLimit: Int {
        display?["display_limit"].intValue ?? 0
    }
    
    var displayTitle: String {
        display?["title"].stringValue ?? ""
    }
    
    var displaySubtitle: String {
        display?["subtitle"].stringValue ?? ""
    }
    
    var displayJustification: String {
        display?["justification"].stringValue ?? ""
    }
    
    
    static func == (lhs: MediaPropertySection, rhs: MediaPropertySection) -> Bool {
        return lhs.id == rhs.id && 
               lhs.displayTitle == rhs.displayTitle &&
               lhs.displaySubtitle == rhs.displaySubtitle &&
               lhs.content == rhs.content
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayTitle)
        hasher.combine(displaySubtitle)
        hasher.combine(content)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        content = try container.decodeIfPresent([MediaPropertySectionItem].self, forKey: .content) ?? []
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        display = try container.decodeIfPresent(JSON.self, forKey: .display) ?? nil
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        permissions = try container.decodeIfPresent(JSON.self, forKey: .permissions) ?? nil
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        hero_items = try container.decodeIfPresent(JSON.self, forKey: .hero_items) ?? nil
        sections = try container.decodeIfPresent([String].self, forKey: .sections) ?? nil
    }
    
}

struct MediaPropertySectionItem: Codable, Identifiable, Hashable  {
    var id : String? = UUID().uuidString
    var banner_image : JSON?
    var banner_image_mobile : JSON?
    var media_id : String? = UUID().uuidString
    var media_type : String?
    var type : String?
    var media : MediaPropertySectionMediaItem?
    var description : String?
    var disabled: Bool? = false
    var display : JSON?
    var label : String?
    var expand : Bool?
    var use_media_settings : Bool? = false
    var subproperty_id : String?
    var subproperty_page_id : String?
    var permissions : JSON?
    var page_id : String?
    var url : String?
    var resolvedPermission : ResolvedPermission? = nil
    
    func getBannerUrl(fabric: Fabric) -> String {
        let image = banner_image
        
        if image == nil {
            return ""
        }
    
        
        if let image = image {
            if image.exists() && !image.isEmpty {
                do {
                    return try fabric.getUrlFromLink(link: image)
                }catch{
                    return ""
                }
            }
        }
        
        return ""
    }
    
    
    static func == (lhs: MediaPropertySectionItem, rhs: MediaPropertySectionItem) -> Bool {
        return lhs.id == rhs.id && 
               lhs.media?.title == rhs.media?.title &&
               lhs.media?.subtitle == rhs.media?.subtitle &&
               lhs.media?.live_video == rhs.media?.live_video &&
               lhs.disabled == rhs.disabled
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(media?.title)
        hasher.combine(media?.subtitle) 
        hasher.combine(media?.live_video)
        hasher.combine(disabled)
    }
}

var debugTimeStatus = false
var debugStartDate = Date() + 4 * 60
var debugStreamStartDate = Date() + 3 * 60
var debugEndDate = Date() + 5 * 60

struct MediaItemAdditionView: Codable, Identifiable, Hashable  {
    var id : String? = UUID().uuidString
    var image: JSON? = nil
    var image_hash: String? = ""
    var label: String? = ""
    var media_link: JSON? = nil
    var media_link_info: JSON? = nil
    static func == (lhs: MediaItemAdditionView, rhs: MediaItemAdditionView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct MediaPropertySectionMediaItem: Codable, Identifiable, Hashable  {
    var id : String? = UUID().uuidString
    var additional_views: [MediaItemAdditionView]? = nil
    var additional_views_label: String? = ""
    var catalog_title : String? = ""
    var description : String? = ""
    var description_rich_text : String? = ""
    var controls : String? = ""
    var viewed_settings : JSON?
    var tags : [JSON]?
    var end_time : String? = ""
    var offerings : [String]? = []
    var start_time : String? = ""
    var stream_start_time : String? = ""
    var label : String? = ""
    var live_video : Bool? = false
    var gallery : [GalleryItem]? = nil
    var headers : [String]? = nil
    var media : [String]? = nil
    var media_lists : [String]? //This is an array of media items but the item's media field is a list of strings?
    var media_catalog_id : String? = ""
    var media_file : JSON?
    var media_link : JSON?
    var media_type : String? = ""
    var poster_image : JSON?
    var thumbnail_image_square : JSON?
    var thumbnail_image_portrait : JSON?
    var thumbnail_image_landscape : JSON?
    var title : String? = ""
    var subtitle : String? = ""
    var type : String? = ""
    var icons : [JSON]? = nil
    var `public` : Bool? = nil
    var permissions : JSON? = nil
    
    var resolvedPermission : ResolvedPermission? = nil
    
    func additionalViews(eluvio: EluvioAPI) -> [MediaPropertySectionMediaItem] {
        guard let additionalViews = additional_views else {
            return []
        }
        
        var mediaItems: [MediaPropertySectionMediaItem] = []
        
        for view in additionalViews {
            let mediaItem = MediaPropertySectionMediaItem(
                additional_views: nil,
                additional_views_label: nil,
                catalog_title: nil,
                description: nil,
                description_rich_text: nil,
                controls: nil,
                viewed_settings: nil,
                tags: nil,
                end_time: nil,
                offerings: nil,
                start_time: nil,
                stream_start_time: nil,
                label: view.label,
                live_video: nil,
                gallery: nil,
                headers: nil,
                media: nil,
                media_lists: nil,
                media_catalog_id: nil,
                media_file: nil,
                media_link: view.media_link,
                media_type: nil,
                poster_image: nil,
                thumbnail_image_square: nil,
                thumbnail_image_portrait: nil,
                thumbnail_image_landscape: view.image,
                title: view.label,
                subtitle: nil,
                type: nil,
                icons: nil,
                public: nil,
                permissions: nil,
                resolvedPermission: nil
            )
            
            mediaItems.append(mediaItem)
        }
        
        return mediaItems
    }

    func thumbnail(eluvio: EluvioAPI) -> String {
        // Check thumbnails in priority order: square -> portrait -> landscape
        let thumbnails = [thumbnail_image_square, thumbnail_image_portrait, thumbnail_image_landscape]
        
        for thumbnail in thumbnails {
            guard let thumb = thumbnail else { continue }
            
            do {
                let url = try eluvio.fabric.getUrlFromLink(link: thumb)
                
                //svg currently fails
                if !url.isEmpty {
                    if let urlComponents = URLComponents(string: url),
                       let pathExtension = urlComponents.path.split(separator: ".").last,
                       ["jpg", "png"].contains(pathExtension.lowercased()) {
                        return url + "&width=400"
                    }else{
                        return url
                    }
                }
            } catch {
                continue
            }
        }
        
        return ""
    }
    
    func url(eluvio: EluvioAPI, propertyId:String) async throws -> String {
        let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(propertyId: propertyId, mediaId: id ?? "")
        let url = try await GetUrlFromMediaOptionsJson(fabric: eluvio.fabric, optionsJson: optionsJson)
        return url
    }
    
    func playerItem(eluvio: EluvioAPI, propertyId:String) async throws -> AVPlayerItem {
        if let link = media_link?["sources"]["default"] {
                let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(propertyId: propertyId, mediaId: id ?? "")
            let playerItem = try await MakePlayerItemFromMediaOptionsJson(fabric: eluvio.fabric, optionsJson: optionsJson, title:title ?? "", description:description ?? "", imageThumb: thumbnail(eluvio:eluvio))
                return playerItem
        }
        
        throw FabricError.badInput("Media item \(id) does not have a valid link: \(media_link)")
    }
    
    var startDate : Date? {
        
        if debugTimeStatus {
            return debugStartDate
        }
        
        if let startTime = start_time {
            return parseDateString(startTime)
        }
        
        if let startTime = stream_start_time {
            return parseDateString(startTime)
        }
        
        return nil
    }
    
    var streamStartDate : Date? {
        
        if debugTimeStatus {
            return debugStreamStartDate
        }
        
        if var startTime = stream_start_time {
            return parseDateString(startTime)
        }
        return startDate
    }
    
    var endDate : Date? {
        
        if debugTimeStatus {
            return debugEndDate
        }
        
        return parseDateString(end_time ?? "")
    }
    
    var startDateTimeString: String {
        let df = DateFormatter()
        df.dateFormat = "MM.d 'at' hh:mm a"
        df.amSymbol = "AM"
        df.pmSymbol = "PM"
        
        return df.string(from: startDate ?? Date())
    }
    
    var streamStartDateTimeString: String {
        let df = DateFormatter()
        df.dateFormat = "MMM d 'at' hh:mm a"
        df.amSymbol = "AM"
        df.pmSymbol = "PM"
        
        return df.string(from: streamStartDate ?? Date())
    }
    
    var timeUntilStart: String {
        if isUpcoming {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.zeroFormattingBehavior = .pad
            
            if let date = startDate {
                let remainingTime: TimeInterval = date.timeIntervalSince(Date())
                return formatter.string(from: remainingTime) ?? ""
            }
        }
        
        return ""
    }
    
    var timeUntilStartLong: String {
        if isUpcoming {
            if let date = startDate {
                let remainingTime: TimeInterval = date.timeIntervalSince(Date())
                
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .full
                
                if remainingTime >= 60*60*24 {
                    formatter.allowedUnits = [.day, .hour, .minute, .second]
                }else if remainingTime >= 60*60 {
                    formatter.allowedUnits = [.hour, .minute, .second]
                } else if remainingTime >= 60 {
                    formatter.allowedUnits = [.second, .minute]
                }else {
                   formatter.allowedUnits = [.second]
                }
                
                formatter.zeroFormattingBehavior = .pad
                
                return formatter.string(from: remainingTime) ?? " "
            }
        }
        
        return ""
    }
    
    var hasStarted : Bool {
        return !isUpcoming
    }
    
    var hasEnded : Bool {
        if let endDate = endDate {
            return endDate < Date()
        }
        return false
    }
    
    var isUpcoming : Bool {
        
        if hasEnded {
            //debugPrint("isUpcoming, already ended")
            return false
        }
        
        if let date = streamStartDate {
            //debugPrint("isUpcoming ", date > Date())
            return date > Date()
        }
        
        if let date = startDate {
            //debugPrint("isUpcoming ", date > Date())
            return date > Date()
        }
        
        return false
    }
    
    var currentlyLive : Bool {
        if let live = live_video {
            if !isUpcoming && live && hasStarted && !hasEnded {
                return true
            }
        }
        
        return false
    }
    
    
    static func == (lhs: MediaPropertySectionMediaItem, rhs: MediaPropertySectionMediaItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.subtitle == rhs.subtitle &&
               lhs.live_video == rhs.live_video
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(live_video)
    }
}
