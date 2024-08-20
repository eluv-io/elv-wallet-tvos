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
    var transactionId = ""
    var transactionHash = ""
    var redeemer = ""
    var fulfillment: JSON?
}

struct RedeemVisibility: Codable {
    var hide_if_expired : Bool = false
    var hide : Bool = false
    var featured : Bool = true
    var hide_if_unreleased : Bool = false
    
}

class RedeemableViewModel: Identifiable, Equatable, ObservableObject {
    var id: String? = UUID().uuidString
    var offerId: String = ""
    var expiresAt: String = ""
    var name: String = ""
    var description: String = ""
    var animationLink: JSON?
    var redeemAnimationLink: JSON?
    var availableAt: String = ""
    @Published
    var status = RedeemStatus()
    var imageUrl: String = ""
    var posterUrl: String = ""
    var tags: [TagMeta] = []
    var nft = NFTModel()
    var isClaimed : Bool = false
    var visibility: RedeemVisibility
    
    init(id:String? = UUID().uuidString,
         offerId: String = "",
         expiresAt: String = "",
         name: String = "",
         description:String = "",
         animationLink: JSON?,
         redeemAnimationLink: JSON?,
         availableAt: String = "",
         status: RedeemStatus = RedeemStatus(),
         imageUrl: String = "",
         posterUrl: String = "",
         tags: [TagMeta] = [],
         isClaimed : Bool = false,
         visibility: RedeemVisibility = RedeemVisibility(),
         nft: NFTModel = NFTModel()
    ){
        self.id = id
        self.offerId = offerId
        self.expiresAt = expiresAt
        self.name = name
        self.description = description
        self.animationLink = animationLink
        self.redeemAnimationLink = redeemAnimationLink
        self.availableAt = availableAt
        self.status = status
        self.imageUrl = imageUrl
        self.posterUrl = posterUrl
        self.tags = tags
        self.isClaimed = isClaimed
        self.visibility = visibility
        self.nft = nft
    }
    
    var availableAtFormatted: String {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: availableAt) else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var expiresAtFormatted: String {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: expiresAt) else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var isExpired: Bool {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: expiresAt) else { return false}
        return date < Date()
    }
    
    var isFuture: Bool {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: availableAt) else { return false}
        
        debugPrint("\(name) date \(date) \(date > Date())")
        return date > Date()
    }
    
    var isActionable: Bool {
        if !status.isActive {
            return false
        }
        
        if isClaimed {
            return false
        }
        
        if isExpired && !status.isRedeemed{
            return false
        }
        
        if isFuture {
            return false
        }
        
        return true
    }
    
    func shouldDisplay(currentUserAddress:String) -> Bool {
        return status.isActive && !visibility.hide && !(visibility.hide_if_expired && isExpired) && !(visibility.hide_if_unreleased && isFuture)
    }
    
    func displayLabel(currentUserAddress:String) -> String {
        if status.isRedeemed && !isRedeemer(address: currentUserAddress) {
            return "CLAIMED REWARD"
        }
        
        if isExpired {
            return "EXPIRED REWARD"
        }
        
        return "REWARD"
    }

    func isRedeemer(address:String) -> Bool {
        return !status.isRedeemed || address.lowercased() == status.redeemer.lowercased()
    }
    
    var location: String {
        for tag in tags {
            if tag.key == "location" {
                return tag.value
            }
        }
        return ""
    }
    
    var contentTag: String {
        for tag in tags {
            if tag.key == "content" {
                return tag.value
            }
        }
        return ""
    }
    
    func getTag(key:String)->String {
        for tag in tags {
            if(tag.key == key){
                return tag.value
            }
        }
        return ""
    }
    
    func checkOfferStatus(fabric:Fabric) async throws -> RedeemStatus {
        var isOfferActive = false
        var isRedeemed = false
        
        let result = try await fabric.isOfferActive(offerId: offerId, nft: self.nft)
        isOfferActive = result.isActive
        isRedeemed = result.isRedeemed

        let redeemStatus = RedeemStatus(isRedeemed: isRedeemed, isActive: isOfferActive)
        
        return redeemStatus

    }

    static func create(fabric:Fabric, redeemable: Redeemable, nft:NFTModel) async throws -> RedeemableViewModel {

        let animationLink = redeemable.animation?["sources"]["default"]

        let redeemAnimationLink = redeemable.redeem_animation?["sources"]["default"]
        
        var imageUrl = ""
        if let image = redeemable.image {
            do{
                imageUrl = try fabric.getUrlFromLink(link: image)
            }catch{}
        }
        
        var posterUrl = ""
        
        if let image = redeemable.poster_image {
            do{
                posterUrl = try fabric.getUrlFromLink(link: image)
            }catch{}
        }
        
        
        //TODO: Find status
        var isRedeemed = false
        var isOfferActive = false
        var offer = JSON()
        if let offerId = redeemable.offer_id {
            do{
                let result = try await fabric.isOfferActive(offerId: offerId, nft: nft)
                isOfferActive = result.isActive
                isRedeemed = result.isRedeemed
                offer = result.offerStats
                debugPrint("OfferStatus: \(redeemable.name) ", result)
            }catch{
                print ("Error finding redeem status ", error)
            }
        }


        let redeemStatus = RedeemStatus(isRedeemed: isRedeemed, isActive: isOfferActive,
                                        transactionHash: offer["transaction"].stringValue,
                                        redeemer: offer["redeemer"].stringValue)
        
        var isClaimed = false
        do {
            let address = try fabric.getAccountAddress()
            isClaimed = isRedeemed && redeemStatus.redeemer != address
        }catch{}
        
        var visibility = redeemable.visibility ?? RedeemVisibility()

        
        return RedeemableViewModel(id:redeemable.id,
                                   offerId: redeemable.offer_id ?? "",
                                   expiresAt: redeemable.expires_at ?? "",
                                   name: redeemable.name ?? "",
                                   description: redeemable.description ?? "",
                                   animationLink: animationLink,
                                   redeemAnimationLink: redeemAnimationLink,
                                   availableAt: redeemable.available_at ?? "",
                                   status: redeemStatus,
                                   imageUrl: imageUrl, 
                                   posterUrl: posterUrl,
                                   tags: redeemable.tags ?? [],
                                   isClaimed: isClaimed,
                                   visibility: visibility,
                                   nft:nft)
    }
    
    //TODO: Find a good id for this
    static func == (lhs: RedeemableViewModel, rhs: RedeemableViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

struct Redeemable: FeatureProtocol {
    var id: String? {
        if let offerid = offer_id {
            return (name ?? UUID().uuidString) + " - " + offerid
        }
        return UUID().uuidString
    }
    var expires_at: String?
    var name: String?
    var description: String?
    var sources: JSON?
    var animation: JSON?
    var redeem_animation: JSON?
    var available_at: String?
    var offer_id: String?
    var image: JSON?
    var poster_image: JSON?
    var visibility: RedeemVisibility?
    var tags: [TagMeta]? = []
    
    var location: String {
        for tag in tags ?? [] {
            if tag.key == "location" {
                return tag.value
            }
        }
        return ""
    }
    
    var contentTag: String {
        for tag in tags ?? [] {
            if tag.key == "content" {
                return tag.value
            }
        }
        return ""
    }
    
    func getTag(key:String)->String {
        if let tags = tags {
            for tag in tags {
                if(tag.key == key){
                    return tag.value
                }
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
    var nft_template: JSON?
    
    //TODO: Move to a ViewModel
    var meta_full: JSON?
    var has_playable_feature : Bool?
    var has_album: Bool? = false
    var additional_media_sections : AdditionalMediaModel? = nil
    var property : PropertyModel? = nil
    var project : ProjectModel? = nil
    var background_image_tv: String? = "" //XXX: Demo only
    var background_image: String? = "" //XXX: Demo only
    var title_image: String? = "" //XXX: Demo only
    var redeemable_offers: [Redeemable]?
    
    var mediaCache : [String: MediaItem]? = [:]
    
    var getFirstFeature: MediaItem? {
        if let sections = additional_media_sections {
            if !sections.featured_media.isEmpty {
                return sections.featured_media[0]
                
            }
        }
        return nil
    }
    
    var isPack: Bool {
        //debugPrint("NFTModel isPack ", meta)
        guard let isOpenable = meta_full?["pack_options"]["is_openable"].boolValue else {
            debugPrint("could not get packOptions")
            return false
        }
        
        debugPrint("NFTModel isOpenable", isOpenable)
        return isOpenable
    }
    
    //XXX: Demo only, the layout tag is burried inside the first featured media
    var isMovieLayout : Bool {
        if let media = getFirstFeature {
            return media.getTag(key: "layout").lowercased() == "movie"
        }
        
        return false
    }

    func getTag(key:String)->String {
        if let tags = self.meta.tags {
            for tag in tags {
                if(tag.key == key){
                    return tag.value
                }
            }
        }
        
        return ""
    }
    
    var isSeries:Bool {
        return false
        /*
        if let attributes = meta_full?["attributes"].array {
            for attribute in attributes {
                let name = attribute["name"].stringValue
                let value = attribute["value"].stringValue
                    if name == "series" && value == "true"{
                        return value == "true"
                    }
            }
        }
        return false
         */
    }

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
    
    // returns the media item identified by id, or the first video feature if it's empty
    func getMediaItem(id:String) -> MediaItem?{
        if id == "" {
            guard let mediaSections = additional_media_sections else {
                return nil
            }
            
            for item in mediaSections.featured_media {
                if item.isLive || item.media_type == "Video" {
                    return item
                }
            }
            
            return nil
        }
        
        debugPrint("getMediaItem mediaCache ", mediaCache?.keys)
        
        return mediaCache?[id]
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
        mediaCache = [:]
        id = contract_addr
    }
    
    //TODO: Find a good id for this
    static func == (lhs: NFTModel, rhs: NFTModel) -> Bool {
        return lhs.contract_addr == rhs.contract_addr
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(contract_addr)
    }
    
}
