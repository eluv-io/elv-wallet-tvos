//
//  MediaPropertyModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-10.
//

import Foundation
import SwiftyJSON

struct MediaPropertiesResponse: Codable {
    var contents : [MediaProperty] = []
    var paging : ResponsePaging = ResponsePaging()
}

struct ResponsePaging : Codable {
    var start : Int = 0
    var limit : Int = 0
    var total : Int = 0
}

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

struct MediaPropertySectionsResponse: Codable {
    var contents : [MediaPropertySection] = []
    var paging : ResponsePaging = ResponsePaging()
    var metadata : JSON?
}

struct MediaPropertyItemsResponse: Codable {
    var contents : [MediaPropertySectionMediaItem] = []
    var paging : ResponsePaging = ResponsePaging()
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
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

var debugTimeStatus = false
var debugStartDate = Date() + 4 * 60
var debugStreamStartDate = Date() + 3 * 60
var debugEndDate = Date() + 5 * 60

struct MediaPropertySectionMediaItem: Codable, Identifiable, Hashable  {
    var id : String? = UUID().uuidString
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
    
    func thumbnail(eluvio: EluvioAPI) -> String {
        do {
            let thumbnailSquare = try eluvio.fabric.getUrlFromLink(link: self.thumbnail_image_square)
            if !thumbnailSquare.isEmpty {
                return thumbnailSquare + "&width=400"
            }
        }catch{}
        
        do {
            let thumbnailPortrait = try eluvio.fabric.getUrlFromLink(link: self.thumbnail_image_portrait)
            if !thumbnailPortrait.isEmpty {
                return thumbnailPortrait + "&width=400"
            }
        }catch{}
        
        do {
            let thumbnailLand = try eluvio.fabric.getUrlFromLink(link: self.thumbnail_image_landscape )
            if !thumbnailLand.isEmpty {
                return thumbnailLand + "&width=400"
            }
        }catch{}
        
        return ""
    }
    
    var startDate : Date? {
        
        if debugTimeStatus {
            return debugStartDate
        }
        
        if let startTime = start_time {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [
                .withFractionalSeconds,
                .withFullDate,
                .withTime, // without time zone
                .withColonSeparatorInTime,
                .withDashSeparatorInDate
            ]
            return dateFormatter.date(from:startTime ?? "")
        }
        
        if let startTime = stream_start_time {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [
                .withFractionalSeconds,
                .withFullDate,
                .withTime, // without time zone
                .withColonSeparatorInTime,
                .withDashSeparatorInDate
            ]
            return dateFormatter.date(from:startTime ?? "")
        }
        
        return nil
    }
    
    var streamStartDate : Date? {
        
        if debugTimeStatus {
            return debugStreamStartDate
        }
        
        if var startTime = stream_start_time {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [
                .withFractionalSeconds,
                .withFullDate,
                .withTime, // without time zone
                .withColonSeparatorInTime,
                .withDashSeparatorInDate
            ]
            return dateFormatter.date(from:startTime)
        }
        return startDate
    }
    
    var endDate : Date? {
        
        if debugTimeStatus {
            return debugEndDate
        }
        
        var endTime = end_time
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withFractionalSeconds,
            .withFullDate,
            .withTime, // without time zone
            .withColonSeparatorInTime,
            .withDashSeparatorInDate
        ]
        return dateFormatter.date(from:endTime ?? "")
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
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
