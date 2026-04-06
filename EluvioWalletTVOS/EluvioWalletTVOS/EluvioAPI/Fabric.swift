//
//  Fabric.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-01.
//

import Alamofire
import Base58Swift
import CryptoKit
import Foundation
import SwiftyJSON

var APP_CONFIG: AppConfiguration = loadJsonFileFatal("configuration.json")
let POLLSECONDS = 300

func IsDemoMode() -> Bool {
  return NetworkStore.shared.selectedNetwork == .demo
}

struct MintInfo {
  var tenantId: String = ""
  var marketplaceId: String = ""
  var sku: String = ""
  var entitlement: String = ""
}

enum FabricError: Error {
  case invalidURL(String)
  case configError(String)
  case unexpectedResponse(String)
  case noLogin(String)
  case badInput(String)
  case apiError(code: Int, response: JSON, error: Error)
}

struct RuntimeError: LocalizedError {
  let description: String

  init(_ description: String) {
    self.description = description
  }

  var errorDescription: String? {
    description
  }
}

class Fabric: ObservableObject {
  static var CommonFabricParams =
    "link_depth=10&resolve=true&resolve_include_source=true&resolve_ignore_errors=true"

  var network: String {
    NetworkStore.shared.selectedNetwork.rawValue
  }

  private var configuration: FabricConfiguration {
    FabricConfigStore.shared.config
  }

  var fabricToken: String {
    AccountStore.shared.bestToken
  }

  var profile = Profile()

  var debugNode = "https://host-76-74-91-2.contentfabric.io/"
  var isDebugNode = false

  func getFabricEndpoint() -> String {
    if isDebugNode {
      return debugNode
    }

    return FabricConfigStore.shared.fabricBaseUrl
  }

  func parseNfts(_ nfts: [JSON], propertyId: String) async throws -> [NFTModel] {
    var items: [NFTModel] = []
    for nft in nfts {
      do {
        let data = try nft.rawData()
        var nftmodel = try JSONDecoder().decode(NFTModel.self, from: data)

        if nftmodel.id == nil {
          if let contract = nftmodel.contract_addr {
            if let token = nftmodel.token_id_str {
              nftmodel.id = "\(contract) : \(token)"
            }
          }

          if nftmodel.id == nil {
            continue
          }
        }

        if !propertyId.isEmpty {
          if let nftTemplate = nftmodel.nft_template {
            debugPrint("bundled_id: ", nftTemplate["bundled_property_id"].stringValue)
            if nftTemplate["bundled_property_id"].stringValue == propertyId {
              items.append(nftmodel)
            }
          }
        } else {
          items.append(nftmodel)
        }
      } catch {
        print("NFT Parsing problem for \(nft): \n\n", error)
        continue
      }
    }

    return items
  }

  func isOfferActive(offerId: String, nft: NFTModel) async throws -> NftRedeemableOffer? {
    guard let address = nft.contract_addr?.nilIfEmpty(),
      let tokenId = nft.token_id_str?.nilIfEmpty()
    else {
      return nil
    }

    let nftInfo = try await RemoteSigner.getNftInfo(nftAddress: address, tokenId: tokenId)

    // print ("NFT INFO", nftInfo)
    return nftInfo.offers?.first(where: { $0.id == offerId })
  }

  private func getWalletStatus(tenantId: String) async throws -> [RedemptionStatus] {
    debugPrint("****** getWalletStatus ******")
    return try await NetworkManager.shared.request("alt/status/act/\(tenantId)")
  }

  private func postWalletStatus(tenantId: String, body: InitiateRedemptionRequest) async throws {
    let _: JSON = try await NetworkManager.shared.request("wlt/act/\(tenantId)")
    return
  }

  func redeemComplete(confirmationId: String, tenantId: String, pollSeconds: Int = POLLSECONDS)
    async throws -> (isRedeemed: Bool, transactionHash: String)
  {
    print("Redeem Complete check")

    var transactionHash = ""
    var complete = false

    for _ in 0...pollSeconds {
      try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))

      let result = try await getWalletStatus(tenantId: tenantId)
      // print("Wallet Status Result: ", result)

      for status in result {
        let op = status.op

        let opSplit = op.split(separator: ":")
        if opSplit.count == 5 {
          if opSplit[0] == "nft-offer-redeem", opSplit[4] == confirmationId {
            if status.status == "complete" {
              print("Wallet Status Result: complete: ", op)
              transactionHash = status.extra?.tx_hash ?? ""
              complete = true
              return (complete, transactionHash)
            }
          }
        }
      }
    }

    return (complete, transactionHash)
  }

  /// Waits for transaction for pollSeconds
  func redeemOffer(offerId: String, nft: NFTModel, pollSeconds: Int = POLLSECONDS) async throws -> (
    isRedeemed: Bool, transactionHash: String
  ) {
    guard let tokenId = nft.token_id_str else {
      throw FabricError.badInput("Could not get token_id_str from nft \(nft)")
    }

    guard let contractAddr = nft.contract_addr else {
      throw FabricError.badInput("Could not get contract_addr from nft \(nft)")
    }

    let nftInfo = try await RemoteSigner.getNftInfo(
      nftAddress: nft.contract_addr ?? "", tokenId: nft.token_id_str ?? "")

    let tenantId = nftInfo.tenant

    if tenantId == "" {
      throw FabricError.unexpectedResponse("Could not get tenant ID from nft \(contractAddr)")
    }
    let confirmationId = UUID().uuidString
    let body = InitiateRedemptionRequest(
      op: "nft-offer-redeem",
      client_reference_id: confirmationId,
      tok_addr: contractAddr,
      tok_id: tokenId,
      offer_id: offerId,
    )

    try await postWalletStatus(tenantId: tenantId, body: body)

    return try await redeemComplete(
      confirmationId: confirmationId, tenantId: tenantId, pollSeconds: pollSeconds)
  }

  func findItem(marketplaceId: String, sku: String) async throws -> (item: JSON?, tenantId: String)
  {
    let marketMeta = try await contentObjectMetadata(
      id: marketplaceId, metadataSubtree: "/public/asset_metadata")

    let items = marketMeta["info"]["items"].arrayValue

    var foundItem: JSON?
    for item in items {
      if item["sku"].stringValue == sku {
        foundItem = item
      }
    }

    if foundItem == nil {
      throw FabricError.badInput("Could not find item from sku: \(sku)")
    }

    let tenantId = marketMeta["info"]["tenant_id"].stringValue

    return (foundItem, tenantId)
  }

  func findItemAddress(marketplaceId: String, sku: String) async throws -> String {
    let (itemJSON, _) = try await findItem(marketplaceId: marketplaceId, sku: sku)

    if let item = itemJSON {
      return item["nft_template"]["nft"]["address"].stringValue
    }

    return ""
  }

  // XXX: superslow
  // Gets the marketplace data from the fabric
  func getMarketplace(marketplaceId: String) async throws -> MarketplaceViewModel {
    debugPrint("getMarketplace marketplace id ", marketplaceId)
    if marketplaceId == "" {
      throw FabricError.badInput("Could not query marketplace. ID is empty.")
    }
    let marketMeta = try await contentObjectMetadata(
      id: marketplaceId, metadataSubtree: "/public/asset_metadata")
    /*
     let startTime = DispatchTime.now()
     let model = try JSONDecoder().decode(AssetMetadataModel.self, from: marketMeta.rawData())
     let endTime = DispatchTime.now()
    
     let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
     let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0
     debugPrint("getMarketplace JSONDecoder time ms: ", elapsedTimeInMilliSeconds)
    
     return try CreateMarketplaceViewModel(meta: model, fabric: self)
      */
    let model = try JSONDecoder().decode(AssetMetadataModel.self, from: marketMeta.rawData())
    debugPrint("marketMeta: ", marketMeta)
    let title = marketMeta["info"]["title"].stringValue
    let logo = model.info?.branding?.tv?.logo?.url ?? ""
    let image = model.info?.branding?.tv?.image?.url ?? ""
    let header = model.info?.branding?.tv?.header_image?.url ?? ""

    return MarketplaceViewModel(
      id: marketplaceId,
      title: title,
      image: image,
      logo: logo,
      header: header
    )
  }

  func getStateStoreUrl() -> String? {
    APP_CONFIG.network[network]?.state_store_urls.first
  }

  func redeemFulfillment(transactionHash: String) async throws -> JSON {
    if transactionHash.isEmpty {
      throw FabricError.configError("Redeem Fulfillment called without transaction ID")
    }

    if let stateUrl = getStateStoreUrl() {
      // TODO: make new state store client
      let url = stateUrl.appending("/code-fulfillment/").appending(
        network == "main" ? "main" : "demov3"
      ).appending("/fulfill/").appending(transactionHash)
      return try await httpJsonRequest(url: url)
    }
    return JSON()
  }

  func getEnvironment() -> APIEnvironment {
    return NetworkStore.shared.environment
  }

  func getWalletBaseUrl() -> String {
    let env = getEnvironment()

    if network == "demo" {
      return "https://wallet.demov3.contentfabric.io"
    } else if env == .staging {
      return "https://wallet.preview.contentfabric.io"
    } else {
      return "https://wallet.contentfabric.io"
    }
  }

  func createWalletAuthorization(
    address: String? = "",
    email: String? = "",
    expiresAt: Int64? = nil,
    walletType: String? = "Custodial",
    walletName: String? = "Eluvio",
    clusterToken: String? = "",
    fabricToken: String? = "",
    provider: String? = ""
  ) throws -> String {
    var paramDict: [String: Any?] = [
      "address": address?.nilIfEmpty(),
      "email": email?.nilIfEmpty(),
      "expiresAt": expiresAt,
      "walletType": walletType?.nilIfEmpty(),
      "walletName": walletName?.nilIfEmpty(),
      "clusterToken": clusterToken?.nilIfEmpty(),
      "fabricToken": fabricToken?.nilIfEmpty(),
      "provider": provider?.nilIfEmpty(),
    ]
    let json = JSON(paramDict)

    debugPrint("wallet authorization: ", json)
    let array = try [UInt8](json.rawData())

    return Base58.base58Encode(array)
  }

  func createWalletPurchaseUrl(
    id: String,
    propertyId: String,
    pageId: String,
    listingId _: String = "",
    sectionId: String = "",
    sectionItemId: String = "",
    actionId _: String = "",
    permissionIds: [String] = [],
    secondaryPurchaseOption: String = "",
    authorization: String = ""
  ) throws -> String {
    var paramDict = [String: Any]()
    paramDict["id"] = id
    paramDict["type"] = "purchase"
    if !sectionId.isEmpty {
      paramDict["sectionSlugOrId"] = sectionId
    }
    if !sectionItemId.isEmpty {
      paramDict["sectionItemId"] = sectionItemId
    }
    if !permissionIds.isEmpty {
      paramDict["permissionItemIds"] = permissionIds
    }
    if !secondaryPurchaseOption.isEmpty {
      paramDict["secondaryPurchaseOption"] = secondaryPurchaseOption
    }

    // paramDict["gate"] = false
    let json = JSON(paramDict)

    debugPrint("wallet purchase params: ", json)
    let array = try [UInt8](json.rawData())

    let params = Base58.base58Encode(array)
    var url = getWalletBaseUrl() + "/" + propertyId + "/" + pageId + "?" + "p=\(params)"
    if authorization.isEmpty {
      return url
    }

    return url + "&authorization=\(authorization)"
  }

  func createWalletPageLink(propertyId: String, pageId: String, authorization: String = "")
    -> String
  {
    let url = getWalletBaseUrl() + "/" + propertyId + "/" + pageId
    if authorization.isEmpty {
      return url
    }
    return url + "?authorization=\(authorization)"
  }

  func getNFTs(
    address: String, propertyId: String = "", description: String = "", name: String = ""
  ) async throws -> [NFTModel] {
    var path = "apigw/nfts?limit=100"

    if !propertyId.isEmpty {
      path = path.appending("&property_id=\(propertyId)")
    }

    if !description.isEmpty {
      path = path.appending("&filter=meta/description:co:\(description)")
    }

    if !name.isEmpty {
      path = path.appending("&name_like=\(name)")
    }
    let response: JSON = try await NetworkManager.shared.request(path)
    let profileData = response
    return try await parseNfts(profileData["contents"].arrayValue, propertyId: propertyId)
  }

  func getProperty(property: String, newFetch: Bool = false) async throws
    -> MediaProperty?
  {
    var result = await PropertyStore.shared.getProperty(id: property)
    if result == nil {
      await PropertyStore.shared.fetchProperty(id: property)
      result = await PropertyStore.shared.getProperty(id: property)
    }
    return result
  }

  func getMediaItem(mediaId: String) -> MediaPropertySectionMediaItem? {
    // This only serves deeplinking.
    // After the big refactor we left this non-functional until we need it again.
    return nil
  }

  private func getKeyMediaProgressContainer(address: String) throws -> String {
    return "\(address) - media_progress"
  }

  func getUserViewedProgressContainer(address: String) throws -> MediaProgressContainer {
    // TODO: Store these constants for user defaults somewhere
    guard
      let data = try UserDefaults.standard.object(
        forKey: getKeyMediaProgressContainer(address: address)) as? Data
    else {
      // debugPrint("Couldn't find media_progress from defaults.")
      return MediaProgressContainer()
    }

    let decoder = JSONDecoder()
    guard let container = try? decoder.decode(MediaProgressContainer.self, from: data) else {
      debugPrint("Couldn't decode media_progress from defaults.")
      return MediaProgressContainer()
    }

    return container
  }

  // TODO: Retrieve from app services profile
  func getUserViewedProgress(address: String, mediaId: String) throws -> MediaProgress {
    if let container = try? getUserViewedProgressContainer(address: address) {
      // TODO: create a key maker function
      return container.media["media-viewed-\(mediaId)-progress"] ?? MediaProgress()
      // debugPrint("getUserViewedProgress \(mediaProgress)")
    }
    // debugPrint("getUserViewedProgress - could not get container")
    return MediaProgress()
  }

  // TODO: Set into the app services profile
  func setUserViewedProgress(address: String, mediaId: String, progress: MediaProgress) throws {
    // debugPrint("setUserViewedProgress mediaId \(mediaId) progress \(progress)")
    var container = MediaProgressContainer()
    do {
      container = try getUserViewedProgressContainer(address: address)
    } catch {
      debugPrint("No previous user progress found.")
    }

    container.media["media-viewed-\(mediaId)-progress"] = progress

    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(container) {
      let defaults = UserDefaults.standard
      try defaults.set(encoded, forKey: getKeyMediaProgressContainer(address: address))
      // debugPrint("Saved to defaults")
    } else {
      debugPrint("Could not encode progress info ", container)
    }
  }

  func getOptionsFromHash(versionHash: String) async throws -> JSON {
    let path = "mw/playout_options/" + versionHash
    return try await NetworkManager.shared.request(path)
  }

  /// New API for media item playout
  func getMediaPlayoutOptions(propertyId: String, mediaId: String) async throws -> JSON {
    return try await NetworkManager.shared.request(
      "mw/properties/\(propertyId)/media_items/\(mediaId)/offerings/any/playout_options")
  }

  // Deprectated: Doesn't work with Live
  func getOptionsFromLink(
    link: JSON?, params: [JSON]? = [], offering: String = "default", hash: String = ""
  ) async throws -> (optionsJson: JSON, versionHash: String) {
    var optionsUrl = try getUrlFromLink(link: link, params: params, hash: hash)

    if offering != "default", optionsUrl.contains("default/options.json") {
      optionsUrl = optionsUrl.replaceFirst(
        of: "default/options.json", with: "\(offering)/options.json")
    }

    // print ("Offering \(offering)")
    // print("options url \(optionsUrl)")

    if !optionsUrl.contains("rep/playout/default/options.json") {
      optionsUrl = optionsUrl.replaceFirst(
        of: "meta/public/asset_metadata", with: "rep/playout/default/options.json")
    }

    guard let versionsHash = FindContentHash(uri: optionsUrl) else {
      throw RuntimeError("Could not find hash from \(optionsUrl)")
    }

    let optionsJson = try await httpJsonRequest(url: optionsUrl)
    // print("options json \(optionsJson)")

    return (optionsJson, versionsHash)
  }

  func getUrlFromLink(
    link: JSON?, baseUrl: String? = nil, params: [JSON]? = [], includeAuth: Bool? = true,
    resolveHeaders: Bool? = false, staticUrl: Bool = false, hash: String = ""
  ) throws -> String {
    guard let link = link else {
      throw FabricError.badInput("getUrlFromLink: Link is nil")
    }

    if link.isEmpty {
      throw FabricError.badInput("getUrlFromLink: Link is nil")
    }

    var path = link["/"].stringValue
    var hash = hash

    if hash.isEmpty {
      hash = link["."]["source"].stringValue
    }

    if hash.isEmpty {
      hash = link["."]["container"].stringValue
    }

    if hash.isEmpty {
      hash = link["sources"]["default"]["."]["container"].stringValue
    }

    if hash.isEmpty {
      throw FabricError.badInput("getUrlFromLink: Could not find hash")
    }

    if path.isEmpty {
      debugPrint("searching sources.default for link path")
      path = link["sources"]["default"]["/"].stringValue
    }

    if path.isEmpty {
      throw FabricError.badInput("getUrlFromLink: Could not find path")
    }

    if path.hasPrefix("/qfab") {
      hash = ""
      path = path.replaceFirst(of: "/qfab", with: "")
    }

    path = NSString.path(withComponents: ["q", hash, path])

    if staticUrl {
      path = "/s/main\(path)"
    }

    let urlString = FabricConfigStore.shared.fabricBaseUrl

    guard let url = URL(string: urlString) else {
      throw FabricError.invalidURL("\(urlString)")
    }

    var pathComponents = url.pathComponents
    pathComponents.append(path)
    path = NSString.path(withComponents: pathComponents)

    var components = URLComponents()
    components.scheme = url.scheme
    components.host = url.host
    components.path = path

    var queryItems: [URLQueryItem] = []
    if includeAuth! {
      queryItems.append(URLQueryItem(name: "authorization", value: AccountStore.shared.bestToken))
    }

    if resolveHeaders! {
      queryItems.append(URLQueryItem(name: "link_depth", value: "5"))
      queryItems.append(URLQueryItem(name: "resolve_include_source", value: "true"))
      queryItems.append(URLQueryItem(name: "resolve", value: "true"))
      queryItems.append(URLQueryItem(name: "resolve_ignore_errors", value: "true"))
    }

    if getEnvironment() == .staging {
      queryItems.append(URLQueryItem(name: "env", value: "staging"))
    }

    components.queryItems = queryItems

    for param in params! {
      if let name = param["name"].string {
        if let value = param["value"].string {
          components.queryItems?.append(URLQueryItem(name: name, value: value))
        }
      }
    }

    guard let newUrl = components.url else {
      throw FabricError.badInput("getUrlFromLink: Could not get url from components. Link: \(link)")
    }

    return newUrl.standardized.absoluteString
  }

  private func httpJsonRequest(url: String) async throws -> JSON {
    return try await NetworkManager.shared.requestUrl(url: url)
  }

  func getHlsPlaylistFromOptions(
    uri: String, hash: String, offering: String = "default"
  ) throws -> String {
    let url = getFabricEndpoint()
    var newUrl: String
    if uri.hasPrefix("q/") {
      // URI already contains the full path
      newUrl = "\(url)\(uri)"
    } else {
      if hash.isEmpty {
        throw FabricError.badInput(
          "getHlsPlaylistFromOptions: hash is empty and required for relative URI")
      }
      newUrl = "\(url)q/\(hash)/rep/playout/\(offering)/\(uri)"
    }
    // print("HLS URL: ", newUrl)

    return newUrl
  }

  // ELV-CLIENT API

  /// id is objectId or versionHash
  func contentObjectMetadata(id: String, metadataSubtree: String? = "") async throws -> JSON {
    let url = "\(getFabricEndpoint())q/\(id)/meta/\(metadataSubtree!)?\(Fabric.CommonFabricParams)"
    return try await httpJsonRequest(url: url)
  }
}
