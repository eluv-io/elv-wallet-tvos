//
//  NFTModel.swift
//  NFTModel
//
//  Created by Wayne Tran on 2021-08-11.
//

import Foundation
import SwiftUI
import SwiftyJSON

struct NFTModel: FeatureProtocol, Equatable, Hashable {
    var id: String? = UUID().uuidString
    var block: Int?
    var created: Int?
    var cap: Int?
    var contract_name: String?
    var contract_addr: String
    var hold: Int?
    var ordinal: Int
    var token_id: Int
    var token_id_str: String
    var token_owner: String?
    var token_uri: String
    var meta : NFTMetaResponse = NFTMetaResponse()
    var meta_full: JSON?
    var has_playable_feature : Bool?
    var has_album: Bool? = false
    var additional_media_sections : AdditionalMediaModel? = nil
    var property : PropertyModel? = nil
    var project : ProjectModel? = nil
    init(){
        block = 0
        created = 0
        cap = 0
        contract_name = "";
        contract_addr = "";
        hold = 0
        ordinal = 0
        token_id = 0
        token_id_str = ""
        token_owner = ""
        token_uri = ""
        has_playable_feature = false
        additional_media_sections = nil
    }
    
    //TODO: Find a good id for this
    static func == (lhs: NFTModel, rhs: NFTModel) -> Bool {
        return lhs.contract_addr == rhs.contract_addr
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(contract_addr)
    }
}
