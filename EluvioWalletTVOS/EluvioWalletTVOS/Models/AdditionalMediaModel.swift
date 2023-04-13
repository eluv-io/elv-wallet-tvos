//
//  AdditionalMediaModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-06.
//

import Foundation
import SwiftyJSON

struct FeaturedMediaModel: Identifiable, Codable {
    var id: String? = UUID().uuidString
    var image: String?
    var name: String = ""
    var image_aspect_ratio: String?
    var media_type: String?
    var requires_permissions: Bool = false
    var media_link: JSON? = nil
    var media_file: JSON? = nil
    var parameters: [JSON] = []
}

struct MediaCollection: Identifiable, Codable {
    var id: String? = UUID().uuidString
    var display: String?
    var name: String = ""
    var media: [FeaturedMediaModel] = []
}
