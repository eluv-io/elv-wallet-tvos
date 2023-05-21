//
//  PropertyModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-17.
//

import Foundation

struct PropertyModel: Identifiable {
    var id: String? = UUID().uuidString
    var title: String? = ""
    var image: String? = ""
    var heroImage: String? = ""
    var parent_id: String? = ""
    var featured: [AnyHashable] = []
    var media: [MediaCollection] = []
    var albums: [NFTModel] = [] //Temporary until we have proper albums
    var contents: [ProjectModel] = []
}

struct ProjectModel: Identifiable {
    var id: String? = UUID().uuidString
    var title: String? = ""
    var image: String? = ""
    var parent_id: String? = ""
    var contents: [NFTModel] = []
}
