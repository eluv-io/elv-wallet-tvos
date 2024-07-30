//
//  SearchModels.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-07-25.
//

import Foundation
import SwiftyJSON

struct PrimaryFilterViewModel: Identifiable, Codable {
    var id: String = ""
    var imageURL: String = ""
    var secondaryFilters: [String] = []
    var attribute: String = ""
    var seconaryAttribute: String = ""
}
