//
//  NFTModel.swift
//  NFTModel
//
//  Created by Wayne Tran on 2021-08-11.
//

import AVKit
import Foundation
import SwiftUI
import SwiftyJSON

public struct RedeemStatus {
  public var isRedeemed = false
  public var isActive = true
  public var transactionHash = ""
  public var redeemer = ""
  public var fulfillment: JSON?

  public init(
    isRedeemed: Bool = false,
    isActive: Bool = true,
    transactionHash: String = "",
    redeemer: String = "",
    fulfillment: JSON? = nil
  ) {
    self.isRedeemed = isRedeemed
    self.isActive = isActive
    self.transactionHash = transactionHash
    self.redeemer = redeemer
    self.fulfillment = fulfillment
  }
}

public struct RedeemVisibility: Codable {
  public var hide_if_expired: Bool = false
  public var hide: Bool = false
  public var featured: Bool = true
  public var hide_if_unreleased: Bool = false

  public init() {}
}

public class RedeemableViewModel: Identifiable, Equatable, ObservableObject {
  public var id: String? = UUID().uuidString
  public var offerId: String = ""
  public var expiresAt: String = ""
  public var name: String = ""
  public var description: String = ""
  public var animationLink: JSON?
  public var redeemAnimationLink: JSON?
  public var availableAt: String = ""
  @Published
  public var status = RedeemStatus()
  public var imageUrl: String = ""
  public var posterUrl: String = ""
  public var tags: [TagMeta] = []
  public var nft = NFTModel()
  public var isClaimed: Bool = false
  public var visibility: RedeemVisibility

  public init(
    id: String? = UUID().uuidString,
    offerId: String = "",
    expiresAt: String = "",
    name: String = "",
    description: String = "",
    animationLink: JSON?,
    redeemAnimationLink: JSON?,
    availableAt: String = "",
    status: RedeemStatus = RedeemStatus(),
    imageUrl: String = "",
    posterUrl: String = "",
    tags: [TagMeta] = [],
    isClaimed: Bool = false,
    visibility: RedeemVisibility = RedeemVisibility(),
    nft: NFTModel = NFTModel()
  ) {
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

  public var availableAtFormatted: String {
    let dateFormatter = ISO8601DateFormatter()
    guard let date = dateFormatter.date(from: availableAt) else { return "" }
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
  }

  public var expiresAtFormatted: String {
    let dateFormatter = ISO8601DateFormatter()
    guard let date = dateFormatter.date(from: expiresAt) else { return "" }
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
  }

  public var isExpired: Bool {
    let dateFormatter = ISO8601DateFormatter()
    guard let date = dateFormatter.date(from: expiresAt) else { return false }
    return date < Date()
  }

  public var isFuture: Bool {
    let dateFormatter = ISO8601DateFormatter()
    guard let date = dateFormatter.date(from: availableAt) else { return false }

    debugPrint("\(name) date \(date) \(date > Date())")
    return date > Date()
  }

  public var isActionable: Bool {
    if !status.isActive {
      return false
    }

    if isClaimed {
      return false
    }

    if isExpired && !status.isRedeemed {
      return false
    }

    if isFuture {
      return false
    }

    return true
  }

  public func shouldDisplay(currentUserAddress _: String) -> Bool {
    return status.isActive && !visibility.hide && !(visibility.hide_if_expired && isExpired)
      && !(visibility.hide_if_unreleased && isFuture)
  }

  public func displayLabel(currentUserAddress: String) -> String {
    if status.isRedeemed && !isRedeemer(address: currentUserAddress) {
      return "CLAIMED REWARD"
    }

    if isExpired {
      return "EXPIRED REWARD"
    }

    return "REWARD"
  }

  public func isRedeemer(address: String) -> Bool {
    return !status.isRedeemed || address.lowercased() == status.redeemer.lowercased()
  }

  public var location: String {
    for tag in tags {
      if tag.key == "location" {
        return tag.value
      }
    }
    return ""
  }

  public var contentTag: String {
    for tag in tags {
      if tag.key == "content" {
        return tag.value
      }
    }
    return ""
  }

  public func getTag(key: String) -> String {
    for tag in tags {
      if tag.key == key {
        return tag.value
      }
    }
    return ""
  }

  public func checkOfferStatus(fabric: Fabric) async throws -> RedeemStatus {
    let result = try await fabric.isOfferActive(offerId: offerId, nft: nft)
    let isOfferActive = result?.active == true
    let isRedeemed = result?.offerRedeemed == true

    return RedeemStatus(isRedeemed: isRedeemed, isActive: isOfferActive)
  }

  public static func create(fabric: Fabric, redeemable: Redeemable, nft: NFTModel, address: String)
    async throws -> RedeemableViewModel
  {
    let animationLink = redeemable.animation?["sources"]["default"]

    let redeemAnimationLink = redeemable.redeem_animation?["sources"]["default"]

    let imageUrl = redeemable.image?.url ?? ""

    let posterUrl = redeemable.poster_image?.url ?? ""

    // TODO: Find status
    var isRedeemed = false
    var isOfferActive = false
    var offer: NftRedeemableOffer? = nil
    if let offerId = redeemable.offer_id {
      do {
        let offer = try await fabric.isOfferActive(offerId: offerId, nft: nft)
        isOfferActive = offer?.active == true
        isRedeemed = offer?.offerRedeemed == true
        debugPrint("OfferStatus: \(redeemable.name) ", offer)
      } catch {
        print("Error finding redeem status ", error)
      }
    }

    let redeemStatus = RedeemStatus(
      isRedeemed: isRedeemed, isActive: isOfferActive,
      transactionHash: offer?.transaction ?? "",
      redeemer: offer?.redeemer ?? "")

    var isClaimed = false
    do {
      isClaimed = isRedeemed && redeemStatus.redeemer != address
    } catch {}

    var visibility = redeemable.visibility ?? RedeemVisibility()

    return RedeemableViewModel(
      id: redeemable.id,
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
      nft: nft)
  }

  // TODO: Find a good id for this
  public static func == (lhs: RedeemableViewModel, rhs: RedeemableViewModel) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

public struct Redeemable: FeatureProtocol {
  public var id: String? {
    if let offerid = offer_id {
      return (name ?? UUID().uuidString) + " - " + offerid
    }
    return UUID().uuidString
  }

  public var expires_at: String?
  public var name: String?
  public var description: String?
  public var sources: JSON?
  public var animation: JSON?
  public var redeem_animation: JSON?
  public var available_at: String?
  public var offer_id: String?
  public var image: ImageLink?
  public var poster_image: ImageLink?
  public var visibility: RedeemVisibility?
  public var tags: [TagMeta]? = []

  public var location: String {
    for tag in tags ?? [] {
      if tag.key == "location" {
        return tag.value
      }
    }
    return ""
  }

  public var contentTag: String {
    for tag in tags ?? [] {
      if tag.key == "content" {
        return tag.value
      }
    }
    return ""
  }

  public func getTag(key: String) -> String {
    if let tags = tags {
      for tag in tags {
        if tag.key == key {
          return tag.value
        }
      }
    }

    return ""
  }
}

public struct NFTModel: FeatureProtocol, Equatable, Hashable {
  public var id: String? = UUID().uuidString
  public var block: Int?
  public var created: Int?
  public var cap: Int?
  public var contract_name: String?
  public var contract_addr: String?
  public var hold: Int?
  public var ordinal: Int?
  public var token_id: Int?
  public var token_id_str: String?
  public var token_owner: String?
  public var token_uri: String?
  public var meta: NFTMetaResponse = .init()
  public var nft_template: JSON?

  // TODO: Move to a ViewModel
  public var meta_full: JSON?
  public var has_playable_feature: Bool?
  public var has_album: Bool? = false
  public var additional_media_sections: AdditionalMediaModel?
  public var property: PropertyModel?
  public var project: ProjectModel?
  public var background_image_tv: String? = ""  // XXX: Demo only
  public var background_image: String? = ""  // XXX: Demo only
  public var title_image: String? = ""  // XXX: Demo only
  public var redeemable_offers: [Redeemable]?
  public var mediaCache: [String: MediaItem]? = [:]

  public var getFirstFeature: MediaItem? {
    if let sections = additional_media_sections {
      if !sections.featured_media.isEmpty {
        return sections.featured_media[0]
      }
    }
    return nil
  }

  public var isPack: Bool {
    // debugPrint("NFTModel isPack ", meta)
    guard let isOpenable = meta_full?["pack_options"]["is_openable"].boolValue else {
      debugPrint("could not get packOptions")
      return false
    }

    debugPrint("NFTModel isOpenable", isOpenable)
    return isOpenable
  }

  // XXX: Demo only, the layout tag is burried inside the first featured media
  public var isMovieLayout: Bool {
    if let media = getFirstFeature {
      return media.getTag(key: "layout").lowercased() == "movie"
    }

    return false
  }

  public func getTag(key: String) -> String {
    if let tags = meta.tags {
      for tag in tags {
        if tag.key == key {
          return tag.value
        }
      }
    }

    return ""
  }

  public var isSeries: Bool {
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

  public var has_tile: Bool {
    guard let image = title_image else {
      return false
    }

    return !image.isEmpty
  }

  public var has_multiple_media: Bool {
    guard let mediaSections = additional_media_sections else {
      return false
    }

    var count = 0

    count = mediaSections.featured_media.count
    count += mediaSections.sections.count

    return count > 1
  }

  /// returns the media item identified by id, or the first video feature if it's empty
  public func getMediaItem(id: String) -> MediaItem? {
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

  public init() {
    block = 0
    created = 0
    cap = 0
    contract_name = ""
    contract_addr = ""
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

  // TODO: Find a good id for this
  public static func == (lhs: NFTModel, rhs: NFTModel) -> Bool {
    return lhs.contract_addr == rhs.contract_addr
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(contract_addr)
  }
}
