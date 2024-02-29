//
//  Entitlement.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-02-28.
//

import Foundation
import SwiftyJSON


struct MintRequestModel: Codable {
    var op: String
    var entitlement: EntitlementModel?
    var signature: String
}

struct EntitlementModel: Codable {
    var marketplace_id : String = ""
    var items: [EntitlementItem]
    var nonce: String
    var purchase_id: String
}

struct EntitlementItem: Codable {
    var sku: String
    var amount: Int
}
 
