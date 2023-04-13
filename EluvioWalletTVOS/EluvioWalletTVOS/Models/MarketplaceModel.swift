//
//  MarketplaceModel.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-10-08.
//

import Foundation
import SwiftUI

struct MarketplaceModel: Identifiable, Codable {
    var id = ""
    var display_name = ""
    var description = ""
    var creator = ""
    var image = ""
    var subscribers = ""
    var items = ""
    var rating : Float = 0.0
}
