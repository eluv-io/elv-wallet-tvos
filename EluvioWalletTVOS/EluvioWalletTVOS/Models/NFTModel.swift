//
//  NFTModel.swift
//  NFTModel
//
//  Created by Wayne Tran on 2021-08-11.
//

import Foundation
import SwiftUI
import SwiftyJSON
import AVKit

struct RedeemStatus {
    var isRedeemed = false
    var isActive = true
}

struct RedeemableViewModel: Identifiable {
    var id: String? = UUID().uuidString
    var expiresAt: String = ""
    var name: String = ""
    var animationPlayerItem: AVPlayerItem?
    var availableAt: String = ""
    var status = RedeemStatus()
    var imageUrl: String = ""
    var posterUrl: String = ""
    var tags: [TagMeta] = []
    
    var location: String {
        for tag in tags {
            if tag.key == "location" {
                return tag.value
            }
        }
        return ""
    }
    
    static func create(fabric:Fabric, redeemable: Redeemable) async throws -> RedeemableViewModel {
        
        var animationItem : AVPlayerItem? = nil
        if let animationLink = redeemable.animation?["sources"]["default"] {
            animationItem = try await MakePlayerItemFromLink(fabric: fabric, link: animationLink)
        }
        let imageUrl = try fabric.getUrlFromLink(link: redeemable.image)
        let posterUrl = try fabric.getUrlFromLink(link: redeemable.poster_image)
        
        //TODO: Find status
        let redeemStatus = RedeemStatus(isRedeemed: false, isActive: true)
        
        return RedeemableViewModel(id:redeemable.id,
                                   expiresAt: redeemable.expires_at ?? "",
                                   name: redeemable.name ?? "",
                                   animationPlayerItem: animationItem,
                                   availableAt: redeemable.available_at ?? "",
                                   status: redeemStatus,
                                   imageUrl: imageUrl, posterUrl: posterUrl, tags: redeemable.tags ?? [])
    }
    
}

struct Redeemable: FeatureProtocol {
    var id: String? {
        if let offerid = offer_id {
            if !offerid.isEmpty {
                return offerid
            }
        }
        return UUID().uuidString
    }
    var expires_at: String?
    var name: String?
    var sources: JSON?
    var animation: JSON?
    var available_at: String?
    var offer_id: String?
    var image: JSON?
    var poster_image: JSON?
    var visibilty: JSON?
    var tags: [TagMeta]? = []
    
    var location: String {
        for tag in tags ?? [] {
            if tag.key == "location" {
                return tag.value
            }
        }
        return ""
    }
}

struct NFTModel: FeatureProtocol, Equatable, Hashable {
    var id: String? = UUID().uuidString
    var block: Int?
    var created: Int?
    var cap: Int?
    var contract_name: String?
    var contract_addr: String?
    var hold: Int?
    var ordinal: Int?
    var token_id: Int?
    var token_id_str: String?
    var token_owner: String?
    var token_uri: String?
    var meta : NFTMetaResponse = NFTMetaResponse()
    
    //TODO: Move to a ViewModel
    var meta_full: JSON?
    var has_playable_feature : Bool?
    var has_album: Bool? = false
    var additional_media_sections : AdditionalMediaModel? = nil
    var property : PropertyModel? = nil
    var project : ProjectModel? = nil
    var background_image_tv: String? = "" //XXX: Demo only
    var title_image: String? = "" //XXX: Demo only
    var redeemable_offers: [Redeemable]?
    
    var has_tile: Bool {
        
        guard let image = title_image else {
            return false
        }
        
        return !image.isEmpty
    }
    
    var has_multiple_media: Bool {
        
        guard let mediaSections = additional_media_sections else {
            return false
        }
        
        var count = 0
        
        count = mediaSections.featured_media.count
        count += mediaSections.sections.count
        
        return count > 1
    }
    
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
