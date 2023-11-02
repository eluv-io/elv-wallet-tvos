//
//  ProfileModel.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-10-10.
//

import Foundation
import SwiftUI

struct ProfileModel: Identifiable, Codable {
    var id = ""
    var display_name = ""
    var description = ""
    var address = ""
    var image = ""
    var followers = ""
    var following = ""
    var num_sold = ""
    var tokens = ""
    var marketplaces : [MarketplaceViewModel]
}
