//
//  Response.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2026-01-31.
//

import SwiftyJSON

struct ResponsePaging : Codable {
    var start : Int = 0
    var limit : Int = 0
    var total : Int = 0
}

struct MediaPropertiesResponse: Codable {
    var contents : [MediaProperty] = []
    var paging : ResponsePaging = ResponsePaging()
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

struct MultiviewResponse: Codable {
    var errors : JSON?
    var contents : [MediaPropertySectionMediaItem] = []
    var paging : ResponsePaging = ResponsePaging()
}
