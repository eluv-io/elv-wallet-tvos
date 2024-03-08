//
//  Entitlement.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-02-28.
//

import Foundation
import SwiftyJSON


struct MintRequestModel: Codable {
    var op: String? = ""
    var entitlement: EntitlementModel?
    var signature: String
}

struct EntitlementModel: Codable {
    var tenant_id : String? = ""
    var marketplace_id : String? = ""
    var sku : String? = ""
    var items: [EntitlementItem]? = []
    var user: String? = ""
    var amount: Int? = 1
    var purchase_id: String
}

struct EntitlementItem: Codable {
    var sku: String
    var amount: Int
}
 
