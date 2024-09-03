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

struct MediaProperty: Codable, Identifiable, Hashable {
    var associated_marketplaces : [AssociatedMarketplaces]?
    var header_logo : JSON?
    var id : String?
    var image : JSON?
    var login: JSON?
    var name : String?
    var title: String?
    var page_title : String?
    var main_page : MediaPropertyPage?
    var media_catalogs : [String]?
    var page_ids : [String]?
    var permission_auth_state : JSON?
    var permission_auth_state_raw : JSON?
    var permission_sets : [String]?
    var permissions : JSON?
    var require_login : Bool?
    var slug : String?
    
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
}

struct MediaPropertyItemsResponse: Codable {
    var contents : [MediaPropertySectionMediaItem] = []
    var paging : ResponsePaging = ResponsePaging()
}

struct MediaPropertySection: Codable, Identifiable {
    var id : String = UUID().uuidString
    var content : [MediaPropertySectionItem]? = []
    var description : String?
    var authorized : Bool?
    var display : JSON?
    var label : String?
    var permissions : JSON?
    var type : String?
    var hero_items: JSON?
    
    var displayLimit: Int {
        display?["display_limit"].intValue ?? 0
    }
    
    var displayTitle: String {
        display?["title"].stringValue ?? ""
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
    }
    
}

struct MediaPropertySectionItem: Codable, Identifiable, Hashable  {
    var id : String? = UUID().uuidString
    var banner_image : JSON?
    var media_id : String? = UUID().uuidString
    var media_type : String?
    var type : String?
    var media : MediaPropertySectionMediaItem?
    var description : String?
    var display : JSON?
    var label : String?
    var expand : Bool?
    var use_media_settings : Bool? = false
    var subproperty_id : String?
    var subproperty_page_id : String?
    var permissions : JSON?
    var page_id : String?
    
    static func == (lhs: MediaPropertySectionItem, rhs: MediaPropertySectionItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

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
    var label : String? = ""
    var live : Bool? = false
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
    
    
    static func == (lhs: MediaPropertySectionMediaItem, rhs: MediaPropertySectionMediaItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
