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

struct MediaProperty: Codable {
    var associated_marketplaces : [AssociatedMarketplaces]?
    var header_logo : JSON?
    var id : String?
    var image : JSON?
    var name : String?
    var page_title : String?
    var main_page : MediaPropertyPage?
    var media_catalogs : [String]?
    var page_ids : [String]?
    var permission_sets : [String]?
    var permissions : JSON?
    var slug : String?
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
}

struct MediaPropertySectionsResponse: Codable {
    var contents : [MediaPropertySection] = []
    var paging : ResponsePaging = ResponsePaging()
}

struct MediaPropertySection: Codable, Identifiable {
    var id : String = UUID().uuidString
    var content : [MediaPropertySectionItem]? = []
    var description : String?
    var display : JSON?
    var label : String?
    var permissions : JSON?
    var type : String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        content = try container.decodeIfPresent([MediaPropertySectionItem].self, forKey: .content) ?? []
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        display = try container.decodeIfPresent(JSON.self, forKey: .display) ?? nil
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        permissions = try container.decodeIfPresent(JSON.self, forKey: .permissions) ?? nil
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
    }
    
}

struct MediaPropertySectionItem: Codable, Identifiable  {
    var id : String? = UUID().uuidString
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
}

struct MediaPropertySectionMediaItem: Codable, Identifiable  {
    var id : String? = UUID().uuidString
    var catalog_title : String? = ""
    var description : String? = ""
    var description_rich_text : String? = ""
    var end_time : String? = ""
    var offerings : [String]? = []
    var start_time : String? = ""
    var label : String? = ""
    var live : Bool? = false
    var media : [MediaPropertySectionMediaItem]? = nil
    var media_lists : [JSON]? //This is an array of media items but the item's media field is a list of strings?
    var media_catalog_id : String? = ""
    var media_file : JSON?
    var media_link : JSON?
    var media_type : String? = ""
    var poster_image : JSON?
    var thumbnail_image_square : JSON?
    var thumbnail_image_portrait : JSON?
    var thumbnail_image_landscape : JSON?
    var title : String? = ""
    var type : String? = ""
}
