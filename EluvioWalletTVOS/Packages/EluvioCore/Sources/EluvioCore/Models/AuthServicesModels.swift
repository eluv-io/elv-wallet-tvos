//
//  AuthServicesModels.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-02-28.
//

import Foundation
import SwiftyJSON

public struct MintRequestModel: Codable {
  public var op: String? = ""
  public var entitlement: EntitlementModel?
  public var signature: String
}

public struct EntitlementModel: Codable {
  public var tenant_id: String? = ""
  public var marketplace_id: String? = ""
  public var sku: String? = ""
  public var items: [EntitlementItem]? = []
  public var user: String? = ""
  public var amount: Int? = 1
  public var purchase_id: String
}

public struct EntitlementItem: Codable {
  public var sku: String
  public var amount: Int
}
