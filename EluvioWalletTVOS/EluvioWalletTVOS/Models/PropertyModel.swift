//
//  PropertyModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-17.
//

import Foundation
import SwiftyJSON

struct PropertyModel: Identifiable, Codable  {
    var id: String? = UUID().uuidString
    var title: String? = ""
    var logo: String? = ""
    var image: String? = ""
    var heroImage: String? = ""
    var parent_id: String? = ""
    var featured: Features = Features()
    var media: [MediaCollection] = []
    var albums: [NFTModel] = [] //Temporary until we have proper albums
    var live_streams: [MediaItem] //Temp. Need to do a new LiveMediaItem model?
    var contents: [ProjectModel] = []
}

struct ProjectModel: Identifiable, Codable {
    var id: String? = UUID().uuidString
    var title: String? = ""
    var description: String? = ""
    var image: String? = ""
    var image_wide: String? = ""
    var background_image_tv: String? = ""
    var parent_id: String? = ""
    var property: PropertyModel? = nil
    var contents: [NFTModel] = []
}
