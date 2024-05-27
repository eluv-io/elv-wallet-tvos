//
//  Fabric.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-01.
//

import Foundation
import Auth0
import SwiftEventBus
import Base58Swift
import Alamofire
import SwiftyJSON
import UUIDShortener
import CryptoKit

var APP_CONFIG : AppConfiguration = loadJsonFileFatal("configuration.json")
let POLLSECONDS = 300

func IsDemoMode()->Bool {
    return APP_CONFIG.app.mode == .demo
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
    static var CommonFabricParams = "link_depth=10&resolve=true&resolve_include_source=true&resolve_ignore_errors=true"
    
    var configUrl = ""
    var network = ""
    var isMetamask = false
    //Logged in using 3rdparty token through deep link
    var isExternal = false
    
    var createDemoProperties : Bool = true
    
    var previousRefreshHash = SHA256.hash(data:Data())
    
    @Published
    var configuration : FabricConfiguration? = nil
    @Published
    var login :  LoginResponse? = nil
    @Published
    var isLoggedOut = true
    @Published
    var signingIn = false
    @Published
    var signInResponse: SignInResponse? = nil
    var profileData: [String: Any] = [:]

    var loginExpiration = Date()
    var loginTime = Date()
    
    //Move these models to the app level
    @Published
    var library: MediaLibrary = MediaLibrary()

    @Published
    var properties: [PropertyModel] = []
    
    @Published
    var isRefreshing = false

    @Published
    var fabricToken: String = ""
    
    //TODO: Factor out authd api or rename this better
    var signer : RemoteSigner? = nil
    var currentEnpointIndex = 0
    
    var profile = Profile()
    var profileClient : ProfileClient? = nil
    
    init(createDemoProperties: Bool = true){
        print("Fabric init config_url \(self.configUrl)");
        self.createDemoProperties = createDemoProperties
    }
    
    func signOutIfExpired()  {
        if self.loginTime != self.loginExpiration {
            if Date() > self.loginExpiration {
                self.signOut()
            }
        }
    }
    
    
    
    func getEndpoint() throws -> String{
        
        if let node = APP_CONFIG.network[network]?.overrides?.fabric_url {
            if node != "" {
                print ("Found dev fabric node: ", node)
                return node
            }
        }
        
        guard let config = self.configuration else {
            throw FabricError.configError("No configuration set")
        }

        let endpoint = config.getFabricAPI()[self.currentEnpointIndex]
        if(endpoint.isEmpty){
            throw FabricError.configError("Could not get endpoint from config")
        }
        return endpoint
    }
    
    func getNetworkConfig(network: String? = nil) throws -> NetworkConfig {
        var _network = network
        if(network==nil){
            guard let savedNetwork = UserDefaults.standard.object(forKey: "fabric_network")
                    as? String else {
                throw FabricError.configError("GetNetworkConfig Error, saved network configuration not found.")
            }
            
            _network = savedNetwork
        }
        
        guard let config = APP_CONFIG.network[_network ?? "main"] else {
            throw FabricError.configError("Error, configuration network not found \(_network)")
        }
        
        return config
    }
    
    @MainActor
    func connect(network: String, signIn: Bool = true) async throws {
        debugPrint("Fabric connect: ", network)
        defer {
            self.signingIn = false
            debugPrint("Fabric connect finished")
        }
        self.signingIn = true
        
        var _network = network
        if(network.isEmpty) {
            guard let savedNetwork = UserDefaults.standard.object(forKey: "fabric_network")
                    as? String else {
                self.isLoggedOut = true
                return
            }
            _network = savedNetwork
        }
        
        guard let configUrl = APP_CONFIG.network[_network]?.config_url else {
            throw FabricError.configError("Error, configuration network not found \(network)")
        }
        
        guard let url = URL(string: configUrl) else {
            throw FabricError.invalidURL("\(self.configUrl)")
        }

        // Use the async variant of URLSession to fetch data
        // Code might suspend here
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let str = String(decoding: data, as: UTF8.self)
        
        print("Fabric config response: \(str)")

        let config = try JSONDecoder().decode(FabricConfiguration.self, from: data)
        self.setConfiguration(configuration:config)
        guard let ethereumApi = self.configuration?.getEthereumAPI() else {
            throw FabricError.configError("Error getting ethereum apis from config: \(self.configuration)")
        }
        
        guard let asApi = self.configuration?.getAuthServices() else{
            throw FabricError.configError("Error getting authority apis from config: \(self.configuration)")
        }
        self.signer = RemoteSigner(ethApi: ethereumApi, authorityApi:asApi, network:_network)
        
        self.configUrl = configUrl
        self.network = _network
        UserDefaults.standard.set(_network, forKey: "fabric_network")
        
        self.profileClient = ProfileClient(fabric: self)
        
        if signIn {
            //self.checkToken { success in
                //debugPrint("Check Token: ", success)
                if (self.isMetamask == true){
                    debugPrint("is Metamask login, skipping checkToken")
                    return
                }
                /*guard success == true else {
                    self.signingIn = false
                    self.isLoggedOut = true
                    return
                }*/
                
                guard let accessToken = UserDefaults.standard.object(forKey: "access_token") as? AnyObject else {
                    self.signingIn = false
                    self.isLoggedOut = true
                    return
                }
                
                guard let tokenType = UserDefaults.standard.object(forKey: "token_type") as? AnyObject else {
                    self.signingIn = false
                    self.isLoggedOut = true
                    return
                }
                
                guard let idToken = UserDefaults.standard.object(forKey: "id_token")
                        as? AnyObject else {
                    self.signingIn = false
                    self.isLoggedOut = true
                    return
                }
                
                var isExternal = false
                
                if let external = UserDefaults.standard.object(forKey: "is_external")
                    as? Bool {
                    isExternal = external
                    debugPrint("Found is_external in userDefaults: ", isExternal)
                }
                
                var credentials : [String: AnyObject] = [:]
                
                credentials["token_type"] = tokenType
                credentials["access_token"] = accessToken
                credentials["id_token"] = idToken
                
                debugPrint("Credentials: ", credentials)
                
                Task {
                    do {
                        try await self.signIn(credentials: credentials, external: isExternal)
                    }catch {
                        print("Could not sign In \(error.localizedDescription)")
                        self.signingIn = false
                        self.isLoggedOut = true
                        return
                    }
                }
            //}
        }
    }
    
    func getContentSpaceId() throws -> String {
        guard let spaceId = self.configuration?.qspace.id else {
            throw FabricError.configError("Error getting spaceId from config: \(self.configuration)")
        }
        return spaceId
    }
    
    func setConfiguration(configuration: FabricConfiguration){
        self.configuration = configuration
        print("QSPACE_ID: \(self.configuration?.qspace.id)")
    }
    
    func parseNftsToLibrary(_ nfts: [JSON]) async throws -> MediaLibrary {
        
        var featured = Features()
        
        var items : [NFTModel] = []
        var mediaRows: [MediaRowViewModel] = []
        for nft in nfts {
            var mediaRow = MediaRowViewModel()
            
            do {
                let data = try nft.rawData()
                let nftmodel = try JSONDecoder().decode(NFTModel.self, from: data)
                
                let parsedModels = try await self.parseNft(nftmodel)
                guard let model = parsedModels.nftModel else {
                    print("Error parsing nft: \(nft)")
                    continue
                }
                
                if(model.has_album ?? false){
                    mediaRow.albums.append(model)
                }
                items.append(model)
                
                if(!parsedModels.featured.isEmpty){
                    featured.append(contentsOf: parsedModels.featured)
                }
                
                mediaRow.features = parsedModels.featured
                mediaRow.images = parsedModels.images
                mediaRow.videos = parsedModels.videos
                mediaRow.books  = parsedModels.books
                mediaRow.liveStreams = parsedModels.liveStreams
                mediaRow.galleries = parsedModels.galleries
                mediaRow.apps = parsedModels.html
                mediaRow.item = model
                mediaRow.name = model.meta.displayName ?? model.meta.name ?? model.contract_name ?? ""
                
                mediaRows.append(mediaRow)
                
            } catch {
                print(error)
                continue
            }
        }
        
        print("Features: ", featured.unique().media.count)
        
        return MediaLibrary(features: featured.unique(), items: items, mediaRows: mediaRows)
    }
    
    func parseNfts(_ nfts: [JSON]) async throws -> (items: [NFTModel], featured:Features, albums:[NFTModel], videos: [MediaItem] , images:[MediaItem] , galleries: [MediaItem] , html: [MediaItem] , books: [MediaItem], liveStreams: [MediaItem] ) {
        
        var featured = Features()
        var videos: [MediaItem] = []
        var galleries: [MediaItem] = []
        let images: [MediaItem] = []
        var albums: [NFTModel] = []
        var html: [MediaItem] = []
        var books: [MediaItem] = []
        var liveStreams: [MediaItem] = []
        var items : [NFTModel] = []
        for nft in nfts {
            do {
                let data = try nft.rawData()
                var nftmodel = try JSONDecoder().decode(NFTModel.self, from: data)

                let parsedModels = try await self.parseNft(nftmodel)
                guard let model = parsedModels.nftModel else {
                    print("Error parsing nft: \(nft)")
                    continue
                }
                
                if(model.has_album ?? false){
                    albums.append(model)
                }
                items.append(model)
                
                if(!parsedModels.featured.isEmpty){
                    featured.append(contentsOf: parsedModels.featured)
                }
                if(!parsedModels.galleries.isEmpty){
                    galleries.append(contentsOf: parsedModels.galleries)
                }
                if(!parsedModels.images.isEmpty){
                    books.append(contentsOf: parsedModels.images)
                }
                if(!parsedModels.videos.isEmpty){
                    videos.append(contentsOf: parsedModels.videos)
                }
                if(!parsedModels.html.isEmpty){
                    html.append(contentsOf: parsedModels.html)
                }
                if(!parsedModels.books.isEmpty){
                    books.append(contentsOf: parsedModels.books)
                }
                if(!parsedModels.liveStreams.isEmpty){
                    liveStreams.append(contentsOf: parsedModels.liveStreams)
                }
                
            } catch {
                print(error)
                continue
            }
        }
        
        return (items, featured.unique(), albums.unique(), videos.unique(), images.unique(), galleries.unique(), html.unique(), books.unique(), liveStreams.unique())
    }
    
    func parseNft(_ _nftmodel: NFTModel) async throws -> (nftModel: NFTModel?, featured:Features, videos: [MediaItem] , images:[MediaItem] , galleries: [MediaItem] , html: [MediaItem] , books: [MediaItem], liveStreams: [MediaItem] ) {
        
        //print("Parse NFT")
        
        var featured = Features()
        var videos: [MediaItem] = []
        var galleries: [MediaItem] = []
        var images: [MediaItem] = []
        var html: [MediaItem] = []
        var books: [MediaItem] = []
        var liveStreams: [MediaItem] = []
        var redeemables: [Redeemable]
        
        var nftmodel = _nftmodel
        nftmodel.mediaCache = [:]
        
        //print("after decoding ", nftmodel)
        guard let contractAddr = nftmodel.contract_addr else{
            throw FabricError.invalidURL("contract_addr does not exist for \(nftmodel.contract_name)")
        }
        
        guard let tokenIdStr = nftmodel.token_id_str else{
            throw FabricError.invalidURL("token_id_str does not exist for \(nftmodel.contract_addr)")
        }
        
        if (nftmodel.id == nil){
            nftmodel.id = contractAddr + tokenIdStr
        }
        
        if (nftmodel.contract_name ?? "").contains("Run") {
            nftmodel.background_image_tv = "Dolly_NFT-Detail-View-BG_4K"
        }
        
        //print("Getting NFT DATA")
        guard let tokenUri = nftmodel.token_uri else {
            throw FabricError.invalidURL("token_uri does not exist for \(nftmodel.contract_addr)")
        }
        
        let nftData = try await self.getNFTData(tokenUri: tokenUri)
        //TODO: use the template
        /*
        var nftData = JSON()
        if let template = nftmodel.nft_template  {
            nftData = template
            debugPrint("Found template ", template)
        }else {
            nftData = try await self.getNFTData(tokenUri: tokenUri)
        }
         */
        
        nftmodel.meta_full = nftData
        //print("******")
        //print(nftData)
        //print("******")
        
        if nftData["redeemable_offers"].exists() {
            //print("redeemable_offers exists for \(nftData["display_name"].stringValue)")
            debugPrint(nftData["redeemable_offers"])
            do {
                nftmodel.redeemable_offers = try JSONDecoder().decode([Redeemable].self, from: nftData["redeemable_offers"].rawData())
                
                //print("DECODED: \(nftmodel.additional_media_sections)")
                //print("FOR JSON: \(try nftData["additional_media_sections"].rawData().prettyPrintedJSONString ?? "")")
            }catch{
                print("Error decoding redeemable_offers for \(nftmodel.contract_name ?? ""): \(error)")
            }
        }
        
        
        if nftData["additional_media_sections"].exists() {
            //print("additional_media_sections exists for \(nftData["display_name"].stringValue)")
            do {
                nftmodel.additional_media_sections = try JSONDecoder().decode(AdditionalMediaModel.self, from: nftData["additional_media_sections"].rawData())
                
                //print("DECODED: \(nftmodel.additional_media_sections)")
                //print("FOR JSON: \(try nftData["additional_media_sections"].rawData().prettyPrintedJSONString ?? "")")
            }catch{
                print("Error decoding additional_media_sections for \(nftmodel.contract_name ?? ""): \(error)")
                //print("\(try nftData["additional_media_sections"].rawData().prettyPrintedJSONString ?? "")")
            }
        }else{
            //print("additional_media_sections does not exists for \(nftData["display_name"].stringValue)")
            
            if nftData["additional_media"].exists() {
                do {
                    //print("additional_media exists: \(try nftData["additional_media"].rawData().prettyPrintedJSONString)")
                    //Try to find the old style
                    if nftData["additional_media"].exists() {
                        nftmodel.additional_media_sections = AdditionalMediaModel()
                        nftmodel.additional_media_sections?.featured_media = try JSONDecoder().decode([MediaItem].self, from: nftData["additional_media"].rawData())
                    }
                }catch{
                    print("Error decoding additional_media for \(nftmodel.contract_name ?? ""): \(error)")
                    //print("\(try nftData["additional_media"].rawData().prettyPrintedJSONString ?? "")")
                }
            }
        }

        
        var hasPlayableMedia = false
        

        if(nftmodel.meta_full?["additional_media_display"].stringValue == "Album"){
            nftmodel.has_album = true
            featured.append(nftmodel)
        }else{
            nftmodel.has_album = false
        }
        //print("additional_media_display ", nftmodel.meta_full?["additional_media_display"].stringValue)
        
        
        if let nftname = nftmodel.contract_name{
            //XXX: Demo only
            if (nftname.contains("Run")){
                nftmodel.background_image_tv = "Dolly_NFT-Detail-View-BG_4K"
            }
        }
        
        if nftmodel.additional_media_sections != nil {
            //print("additional_media_sections is not nil ", nftmodel.additional_media_sections)
            
            if let mediaSections = nftmodel.additional_media_sections {
                //Parsing featured_media to find videos
                for index in 0..<mediaSections.featured_media.count{
                    var media = mediaSections.featured_media[index]
                    media.nft = nftmodel
                    if let mediaId = media.mediaId {
                        nftmodel.mediaCache?[mediaId] = media
                    }
                    //debugPrint("Featured Media ", media.name)
                    //debugPrint("Featured Media ID", media.id)
                    if let mediaType = media.media_type {
                        if mediaType == "Video"{
                            hasPlayableMedia = true
                        }
                        if mediaType == "Audio"{
                            hasPlayableMedia = true
                        }
                        
                        if mediaType == "Live Video"{
                            liveStreams.append(media)
                        }
                        
                        nftmodel.additional_media_sections?.featured_media[index] = media
                    }
                    
                    
                    if let hasAlbum = nftmodel.has_album {
                        //print("has_album ", hasAlbum)
                        if !hasAlbum {
                            //print("inserted media")
                            featured.append(media)
                        }
                    }
                }


                //Parsing sections to find videos
                for sectionIndex in 0..<mediaSections.sections.count {
                    var section = mediaSections.sections[sectionIndex]
                    
                    for collectionIndex in 0..<section.collections.count {
                        var collection = section.collections[collectionIndex]
                        
                        for mediaIndex in 0..<collection.media.count{
                            var media = collection.media[mediaIndex]
                            if let mediaId = media.mediaId {
                                nftmodel.mediaCache?[mediaId] = media
                            }
                            
                            if let mediaType = media.media_type {
                                //XXX: Demo only until we have a proper Live mediaType
                                if mediaType == "Live Video"{
                                    hasPlayableMedia = true
                                    liveStreams.append(media)
                                }else if mediaType == "Video" {
                                    hasPlayableMedia = true
                                    videos.append(media)
                                }else if mediaType == "Audio"{
                                    hasPlayableMedia = true
                                }else if mediaType == "Image"{
                                    images.append(media)
                                }else if mediaType == "Gallery"{
                                    galleries.append(media)
                                }else if mediaType == "HTML"{
                                    html.append(media)
                                }else if mediaType == "Ebook"{
                                    books.append(media)
                                }

                                media.nft = nftmodel
                                nftmodel.additional_media_sections?.sections[sectionIndex].collections[collectionIndex].media[mediaIndex] = media
                            }
                        }
                    }
                }
            }
        }
        nftmodel.has_playable_feature = hasPlayableMedia
        
        return (nftmodel, featured, videos, images, galleries, html, books, liveStreams)
    }
    
    func isOfferActive(offerId: String, nft: NFTModel) async throws -> (isActive:Bool, isRedeemed:Bool, offerStats:JSON) {
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        var tenantId = ""

        let nftInfo = try await signer.getNftInfo(nftAddress: nft.contract_addr ?? "", tokenId: nft.token_id_str ?? "", accessCode: fabricToken)
        
        print ("NFT INFO", nftInfo)

        if let offers = nftInfo["offers"].array{
            for offer in offers {
                let offer_id = offer["id"].stringValue
                if (offerId == offer_id){
                    let offerActive = offer["active"].boolValue
                    let redeemer = offer["redeemer"].stringValue
                    let redeemed = offer["redeemed"].stringValue
                    let transaction = offer["transaction"].stringValue
                    
                    var offerRedeemed = false
                    if (!redeemer.isEmpty && !redeemed.isEmpty && !transaction.isEmpty){
                        offerRedeemed = true
                    }
                    
                    return (offerActive, offerRedeemed, offer)
                }
            }
        }
            
        return (false, false, JSON())
    }
    
    func redeemComplete(confirmationId: String, tenantId: String, pollSeconds:Int = POLLSECONDS)  async throws -> (isRedeemed:Bool, transactionId:String, transactionHash:String){
        
        print("Redeem Complete check")
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        
        var transactionId = ""
        var transactionHash = ""
        var complete = false
        
        for _ in 0...pollSeconds {
            try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
            
            let result = try await signer.getWalletStatus(tenantId: tenantId, accessCode: fabricToken)
            //print("Wallet Status Result: ", result)
            
            for status in result.arrayValue {
                let op = status["op"].stringValue
                
                let opSplit = op.split(separator: ":")
                if opSplit.count == 5 {
                    if opSplit[0] == "nft-offer-redeem" && opSplit[4] == confirmationId {
                        if (status["status"] == "complete"){
                            print("Wallet Status Result: complete: ", op)
                            transactionId = status["extra"]["trans_id"].stringValue
                            transactionHash = status["extra"]["tx_hash"].stringValue
                            complete = true
                            return (complete,
                                    transactionId,
                                    transactionHash 
                                    )
                        }
                    }
                }
            }
        }
        
        return (complete, transactionId,transactionHash)
    }
    
    //Waits for transaction for pollSeconds
    func redeemOffer(offerId: String, nft: NFTModel, pollSeconds: Int = POLLSECONDS) async throws -> (isRedeemed:Bool, transactionId:String, transactionHash:String) {
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        
        guard let tokenId = nft.token_id_str else {
            throw FabricError.badInput("Could not get token_id_str from nft \(nft)")
        }
        
        guard let contractAddr = nft.contract_addr else {
            throw FabricError.badInput("Could not get contract_addr from nft \(nft)")
        }
        
        let nftInfo = try await signer.getNftInfo(nftAddress: nft.contract_addr ?? "", tokenId: nft.token_id_str ?? "", accessCode: fabricToken)
        
        let tenantId = nftInfo["tenant"].stringValue
        
        if tenantId == "" {
            throw FabricError.unexpectedResponse("Could not get tenant ID from nft \(contractAddr)")
        }
        
        //let query = ["dry_run":"true"]
        let query:[String:String] = [:]
        let uuid = UUID()
        let confirmationId = try uuid.shortened(using: .base58)
        let body: [String: Any] = [
            "op": "nft-offer-redeem",
            "client_reference_id": confirmationId,
            "tok_addr": contractAddr,
            "tok_id": tokenId,
            "offer_id": offerId
        ]
        
        try await signer.postWalletStatus(tenantId: tenantId, accessCode: fabricToken, query: query, body: body)
        
        return try await redeemComplete(confirmationId: confirmationId, tenantId: tenantId, pollSeconds: pollSeconds)
    }
    
    //Waits for transaction for pollSeconds
    func packOpen(nft: NFTModel, pollSeconds: Int = POLLSECONDS) async throws -> (isComplete:Bool, status:String, transactionId:String,         contractAddress:String, tokenId:String) {
        
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        
        guard let tokenId = nft.token_id_str else {
            throw FabricError.badInput("Could not get token_id_str from nft \(nft)")
        }
        
        guard let contractAddr = nft.contract_addr else {
            throw FabricError.badInput("Could not get contract_addr from nft \(nft)")
        }
        
        let nftInfo = try await signer.getNftInfo(nftAddress: nft.contract_addr ?? "", tokenId: nft.token_id_str ?? "", accessCode: fabricToken)
        
        let tenantId = nftInfo["tenant"].stringValue
        
        if tenantId == "" {
            throw FabricError.unexpectedResponse("Could not get tenant ID from nft \(contractAddr)")
        }
        
        let op = "nft-open"
        let query:[String:String] = [:]
        let uuid = UUID()
        let confirmationId = ""
        let body: [String: Any] = [
            "op": op,
            "tok_addr": contractAddr,
            "tok_id": tokenId
        ]
        
        try await signer.postWalletStatus(tenantId: tenantId, accessCode: fabricToken, query: query, body: body)
        
        return try await packStatus(opString: op, tenantId: tenantId, contractAddr:contractAddr , tokenId:tokenId, pollSeconds: pollSeconds)
    }
    
    func packStatus(opString:String, tenantId: String, contractAddr: String, tokenId:String, pollSeconds:Int = POLLSECONDS)  async throws -> (isComplete:Bool, status:String, transactionId:String, contractAddress:String, tokenId:String){
        
        print("Redeem Complete check")
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        
        var transactionId = ""
        var complete = false
        var status = ""
        let address = contractAddr.starts(with: "0x") ? contractAddr.dropFirst(2).lowercased() : contractAddr.lowercased()
        
        for _ in 0...pollSeconds {
            try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
            
            let result = try await signer.getWalletStatus(tenantId: tenantId, accessCode: fabricToken)
            print("Wallet Status Result: ", result)
            
            for stat in result.arrayValue {
                let op = stat["op"].stringValue
                debugPrint("Testing op ", op)
                
                let opSplit = op.split(separator: ":")
                if opSplit.count >= 3 {
                    debugPrint("opSplit 3 ", opSplit)
                    debugPrint("operator: ", opString)
                    debugPrint("opSplit[0] ", opSplit[0])
                    if opSplit[0] == opString {
                        debugPrint("opSplit op found ", op)
                        if opSplit[1] == address {
                            debugPrint("opSplit op! found ", address)
                            if opSplit[2] == tokenId {
                                status = stat["status"].stringValue
                                debugPrint("Matched status", status)
                                if (status == "complete"){
                                    print("Wallet Status Result: complete: ", op)
                                    transactionId = stat["extra"]["trans_id"].stringValue
                                    let newContractAddr = stat["extra"]["0"]["token_addr"].stringValue
                                    let newTokenId = stat["extra"]["0"]["token_id_str"].stringValue
                                    complete = true
                                    return (complete,
                                            status,
                                            transactionId,
                                            newContractAddr,
                                            newTokenId
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return (complete, status, transactionId, "", "")
    }
    
    func findItem(marketplaceId: String, sku: String) async throws -> (item: JSON?, tenantId: String){
        let marketMeta = try await contentObjectMetadata(id: marketplaceId, metadataSubtree:"/public/asset_metadata")

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
    
    func findItemAddress(marketplaceId: String, sku: String) async throws -> String{
        let (itemJSON, _) = try await findItem(marketplaceId: marketplaceId, sku: sku)
        
        if let item = itemJSON {
            return item["nft_template"]["nft"]["address"].stringValue
        }
        
        return ""
        
    }
    
    
    //XXX: superslow
    //Gets the marketplace data from the fabric
    func getMarketplace(marketplaceId: String) async throws -> MarketplaceViewModel{
        debugPrint("getMarketplace marketplace id ", marketplaceId)
        if marketplaceId == "" {
            throw FabricError.badInput("Could not query marketplace. ID is empty.")
        }
        let marketMeta = try await contentObjectMetadata(id: marketplaceId, metadataSubtree:"/public/asset_metadata")
        /*
        let startTime = DispatchTime.now()
        let model = try JSONDecoder().decode(AssetMetadataModel.self, from: marketMeta.rawData())
        let endTime = DispatchTime.now()

        let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0
        debugPrint("getMarketplace JSONDecoder time ms: ", elapsedTimeInMilliSeconds)
        
        return try CreateMarketplaceViewModel(meta: model, fabric: self)
         */
        
        debugPrint("marketMeta: ", marketMeta)
        let title = marketMeta["info"]["title"].stringValue
        var logo = ""
        do{
            logo = try getUrlFromLink(link: marketMeta["info"]["branding"]["tv"]["logo"])
        }catch{}
        
        var image = ""
        do{
            image = try getUrlFromLink(link: marketMeta["info"]["branding"]["tv"]["image"])
        }catch{}
        
        var header = ""
        do{
            header = try getUrlFromLink(link: marketMeta["info"]["branding"]["tv"]["header_image"])
        }catch{}
        
        return MarketplaceViewModel(
            id: marketplaceId,
            title: title,
            image:image, 
            logo:logo,
            header:header
        )
    }
    
    //Returns the property stored in memory based on the id (currently using the marketplace id)
    func findProperty(marketplaceId: String) throws -> PropertyModel?{
        debugPrint("findProperty ", marketplaceId)
        for prop in properties {
            debugPrint("Property \(prop.title) ID: ", prop.id)
            if prop.id == marketplaceId {
                return prop
            }
        }
        
        return nil
    }
    
    //Waits for transaction for pollSeconds
    func mintEntitlement(tenantId: String, entitlement: String, pollSeconds: Int = POLLSECONDS) async throws -> (isRedeemed:Bool, contractAddress:String, tokenId:String) {
        debugPrint("mintEntitlement \(entitlement)")
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        
        let query:[String:String] = [:]
        
        guard let data = entitlement.data(using:.utf8) else {
            throw FabricError.badInput("Could not convert entitlement string to data.")
        }
        
        var mintRequest = try JSONDecoder().decode(MintRequestModel.self, from: data)
        mintRequest.op = "nft-claim-entitlement"
        
        let mintBody = try JSONEncoder().encode(mintRequest)
        
        let responseJson = try await signer.postWalletStatus(tenantId: tenantId, accessCode: fabricToken, query: query, bodyData: mintBody)
        let opResponse = responseJson["op"].stringValue
        let result =  try await mintEntitlementStatus(tenantId: tenantId, opResponse: opResponse, pollSeconds: pollSeconds)
        return result
    }
    
    //TODO: change pollSeconds to 120 or something. 30 is just demo
    func mintEntitlementStatus(tenantId: String, opResponse: String, pollSeconds:Int = POLLSECONDS)  async throws -> (isRedeemed:Bool, contractAddress:String, tokenId:String){
        
        print("mintEntitlementStatus check")
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        
        if opResponse.isEmpty {
            throw FabricError.badInput("mintEntitlementStatus: No op string for request")
        }
        
        //confimrationId doesn't return yet
        for _ in 0...pollSeconds {
            try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
            
            let result = try await signer.getWalletStatus(tenantId: tenantId, accessCode: fabricToken)
            debugPrint("Wallet Status Result: ", result)
            
            for status in result.arrayValue {
                let op = status["op"].stringValue
                
                if opResponse == op {
                    if (status["status"] == "complete"){
                        print("Wallet Status Result: complete: ", op)
                        return (true,
                                status["extra"]["0"]["token_addr"].stringValue,
                                status["extra"]["0"]["token_id"].stringValue
                        )
                    }
                }
            }
        }
        
        return (true, "","")
    }
    
    //Waits for transaction for pollSeconds
    func mintItem(tenantId: String, marketplaceId: String, sku: String, contract:String="", pollSeconds: Int = POLLSECONDS) async throws -> (isRedeemed:Bool, contractAddress:String, tokenId:String) {
        
        if tenantId == "" {
            throw FabricError.unexpectedResponse("Error minting item. tenantId is empty")
        }
        if marketplaceId == "" {
            throw FabricError.unexpectedResponse("Error minting item. marketplaceId is empty")
        }
        if sku == "" {
            throw FabricError.unexpectedResponse("Error minting item. sku is empty")
        }
        
        debugPrint("mintItem \(tenantId) \(marketplaceId) \(sku)")
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        
        //let query = ["dry_run":"true"]
        let query:[String:String] = [:]
        let uuid = UUID()
        let confirmationId = try uuid.shortened(using: .base58)
        let body: [String: Any] = [
            "op": "nft-claim",
            "client_reference_id": confirmationId,
            "sid": marketplaceId,
            "sku": sku,
            "email": "" //TODO
        ]
        
        //DEMO:
        if IsDemoMode() && contract != ""{
            var contractAddress = contract
            if let nft = getNFT(contract:contractAddress) {
                let result = try await mintComplete(confirmationId: confirmationId, tenantId: tenantId, marketplaceId: marketplaceId, sku:sku, pollSeconds: 5)
                return (true,contractAddress,"")
            }
        }
        
        try await signer.postWalletStatus(tenantId: tenantId, accessCode: fabricToken, query: query, body: body)
        
        let result =  try await mintComplete(confirmationId: confirmationId, tenantId: tenantId, marketplaceId: marketplaceId, sku:sku, pollSeconds: pollSeconds)
        return result
    }
    
    //TODO: change pollSeconds to 120 or something. 30 is just demo
    func mintComplete(confirmationId: String, tenantId: String, marketplaceId: String, sku:String, pollSeconds:Int = POLLSECONDS)  async throws -> (isRedeemed:Bool, contractAddress:String, tokenId:String){
        
        print("mintComplete check")
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not available")
        }
        
        //confimrationId doesn't return yet
        for _ in 0...pollSeconds {
            try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
            
            let result = try await signer.getWalletStatus(tenantId: tenantId, accessCode: fabricToken)
            debugPrint("Wallet Status Result: ", result)
            
            for status in result.arrayValue {
                let op = status["op"].stringValue
                
                let opSplit = op.split(separator: ":")
                //confimrationId doesn't return yet. Should check using that once done
                
                if opSplit[0] == "nft-claim" && opSplit[1] == marketplaceId && opSplit[2] == sku {
                    if (status["status"] == "complete"){
                        print("Wallet Status Result: complete: ", op)
                        return (true,
                                status["extra"]["0"]["token_addr"].stringValue,
                                status["extra"]["0"]["token_id"].stringValue
                        )
                    }
                }
            }
        }
        
        return (true, "","")
    }
    
    func getStateStoreUrl()->String? {
        if let urls = APP_CONFIG.network[self.network]?.state_store_urls {
            if urls.count > 0 {
                return urls[0]
            }
        }
        return nil
    }
    
    func getBadgerAddress() throws ->String {
        if let address = APP_CONFIG.network[self.network]?.badger_address {
            return address
        }
        
        throw FabricError.configError("No badger_address in configuration.")
    }
    
    func redeemFulfillment(transactionHash: String) async throws -> JSON {
        if (transactionHash.isEmpty){
            throw FabricError.configError("Redeem Fulfillment called without transaction ID")
        }
        
        if let stateUrl = getStateStoreUrl() {
            //TODO: make new state store client
            let url = stateUrl.appending("/code-fulfillment/").appending(self.network == "main" ? "main" : "demov3").appending("/fulfill/").appending(transactionHash)
            return try await getJsonRequest(url: url)
        }
        return JSON()
    }
    
    //Move this to the app level
    @MainActor
    func refresh() async {
        debugPrint("Fabric refresh")
        if self.signingIn {
            return
        }
        if self.isLoggedOut {
            return
        }
        
        if self.isRefreshing {
            return
        }
        
        guard let signer = self.signer else {
            return
        }
        
        guard let login = self.login else {
            return
        }
        
        
        self.isRefreshing = true
        defer{
            isRefreshing = false
        }
        

        do{
            try await profile.refresh()
            
            var properties: [PropertyModel] = []
            
            if (!self.isMetamask){
                self.fabricToken = try await signer.createFabricToken( address: self.getAccountAddress(), contentSpaceId: self.getContentSpaceId(), authToken: login.token, external: self.isExternal)
            }
            //print("Fabric Token: \(self.fabricToken)");
            
            let response = try await signer.getWalletData(accountAddress: try self.getAccountAddress(),
                                                          accessCode: self.fabricToken)
            let profileData = response.result

            debugPrint("Previous Hash ", previousRefreshHash.description)
            debugPrint("New Hash ", response.hash.description)
            // Same data, exit so we don't affect UI
            if !self.library.isEmpty && response.hash == self.previousRefreshHash {
                debugPrint("exiting refresh...same data.")
                return
            }
            
            let nfts = profileData["contents"].arrayValue

            let parsedLibrary = try await parseNftsToLibrary(nfts)
            self.library = parsedLibrary
            isRefreshing = false
            
            if IsDemoMode() && createDemoProperties {
                let vuduProp = try await createVuduDemoProp(nfts: nfts)
                let uefaProp = try await createUEFAProp(nfts: nfts)
                let aflProp = try await createAFLProp(nfts: nfts)
                let wbProp = try await createWbDemoProp(nfts: nfts)
                let foxEntProp = try await createFoxEntertainmentProp(nfts: nfts)
                let foxSportsProp = try await createFoxSportsDemoProp(nfts: nfts)
                let foxWeatherProp = try await createFoxWeatherProp(nfts: nfts)
                let foxNewsProp = try await createFoxNewsProp(nfts: nfts)
                let dollyDemoProp = try await createDollyDemoProp(nfts: nfts)
                let moonProp = try await createMoonProp(nfts: nfts)
                
                properties = [
                    aflProp,
                    vuduProp,
                    uefaProp,
                    wbProp,
                    foxEntProp,
                    foxSportsProp,
                    foxNewsProp,
                    foxWeatherProp,
                    dollyDemoProp,
                    moonProp
                ]
            }
            
            self.properties = properties
            
            debugPrint("Properties count ", self.properties.count)
            self.previousRefreshHash = response.hash
                
        }catch{
            print ("Refresh Error: \(error)")
            signOut()
        }
    }
    
    func createMoonProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let richText = nft["meta"]["rich_text"].stringValue
            if richText.contains("moonsault") {
                demoNfts.append(nft)
            }
        }
        
        //print("MOON NFTS: ", nfts)
        
        let demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        demoMedia.append(MediaCollection(name:"Video", media:demoLib.videos))
        demoMedia.append(MediaCollection(name:"Image Gallery", media:demoLib.galleries))
        demoMedia.append(MediaCollection(name:"Apps", media:demoLib.html))
        demoMedia.append(MediaCollection(name:"E-books", media:demoLib.books))

        
        let prop = CreateTestPropertyModel(title:"Moonsault", logo: "MoonSaultLogo_White", image:"MoonSault-search-v4", heroImage:"MoonSault TopImage-v4", items:[])
        
        return prop
    }

    func createMSDemoProp(nfts:[JSON]) async throws -> PropertyModel {
        debugPrint("createVuduDemoProp")
        var demoNfts: [JSON] = []
        for nft in nfts{
            let address = nft["contract_addr"].stringValue
            if address.lowercased() == "0x265e8cdd7dc0dc85921222e16bf472ebe6f9cf5a"{
                demoNfts.append(nft)
            }else if address.lowercased() == "0xee240128c00e0983d3e0ee1adab4da2f2393f3fb"{
                demoNfts.append(nft)
            }else if address.lowercased() == "0xd2896f45879b1a007aff5d052b9d6ab8c4933fad" {
                demoNfts.append(nft)
            }
            
            let name = nft["contract_name"].stringValue
            if name.contains("Rings") {
                demoNfts.append(nft)
                debugPrint("LOTR NFT: ", nft)
            }else if name.contains("Flash") {
                demoNfts.append(nft)
            }
        }
        
        let demoLib = try await parseNfts(demoNfts)
        
        
        var demoMedia : [MediaCollection] = []
        demoMedia.append(MediaCollection(name:"Video", media:demoLib.videos))
        demoMedia.append(MediaCollection(name:"Images", media:demoLib.galleries))
        demoMedia.append(MediaCollection(name:"Apps", media:demoLib.html))

        var newItems : [NFTModel] = []
        
        for var item in demoLib.items{
            if let name = item.contract_name {
                if name.contains("Quiet") {
                    item.title_image = "TileGroup-A Quiet Place Day One"
                }else  if name.contains("Love") {
                    item.title_image = "TileGroup-BobMarleyOneLove"
                }else if name.contains("Top"){
                    item.title_image = "TileGroup-Top Gun"
                }else if name.contains("Epic") {
                    item.title_image = "LOTR_Tile Group_Epic"
                }else  if name.contains("Shire") {
                    item.title_image = "LOTR_Tile Group_Shire"
                }else if name.contains("Superman"){
                    item.title_image = "WB_Superman_Hope_Tile Group"
                }else if name.contains("Flash"){
                    item.title_image = "Flash Premium Tile Group_trio"
                }
            }
            newItems.append(item)
        }
        
        let marketplaceId = "iq__2J6bUaQkReBrLYSFYQ7nfuPtyyA"
        //let marketplace = try await self.getMarketplace(marketplaceId: marketplaceId)
        
        let prop = CreateTestPropertyModel(id:marketplaceId, title:"Microsoft Media Wallet", logo: "" , image:"Search - Microsoft", heroImage:"Microsoft-property-header",
                                    featured: demoLib.featured, media: demoMedia, items:newItems)
        
        return prop
    }

    func createVuduDemoProp(nfts:[JSON]) async throws -> PropertyModel {
        debugPrint("createVuduDemoProp")
        var demoNfts: [JSON] = []
        for nft in nfts{
            let address = nft["contract_addr"].stringValue
            if address.lowercased() == "0xb77dd8be37c6c8a6da8feb87bebdb86efaff74f4"{
                demoNfts.append(nft)
            }else if address.lowercased() == "0x8e225b2dbe6272d136b58f94e32c207a72cdfa3b"{
                demoNfts.append(nft)
            }else if address.lowercased() == "0x86b9f9b5d26c6f111afaecf64a7c3e3e8a1736da" {
                demoNfts.append(nft)
            }else if address.lowercased() == "0x86b9f9b5d26c6f111afaecf64a7c3e3e8a1736da" {
                demoNfts.append(nft)
            }
            
            let name = nft["contract_name"].stringValue
            if name.contains("Rings") {
                demoNfts.append(nft)
            }else if name.contains("Superman") {
                demoNfts.append(nft)
            }else if name.contains("Flash") {
                demoNfts.append(nft)
            }
        }
        
        let demoLib = try await parseNfts(demoNfts)
        
        /*for media in demoLib.featured.media {
            debugPrint("WB Featured: ", media.name)
        }*/

        
        var demoMedia : [MediaCollection] = []
        demoMedia.append(MediaCollection(name:"Video", media:demoLib.videos))
        demoMedia.append(MediaCollection(name:"Images", media:demoLib.galleries))
        demoMedia.append(MediaCollection(name:"Apps", media:demoLib.html))

        var newItems : [NFTModel] = []
        
        for var item in demoLib.items{
            if let name = item.contract_name {
                if name.contains("Quiet") {
                    item.title_image = "TileGroup-A Quiet Place Day One"
                }else  if name.contains("Love") {
                    item.title_image = "TileGroup-BobMarleyOneLove"
                }else if name.contains("Top"){
                    item.title_image = "TileGroup-Top Gun"
                }else if name.contains("Epic") {
                    item.title_image = "LOTR_Tile Group_Epic"
                }else  if name.contains("Shire") {
                    item.title_image = "LOTR_Tile Group_Shire"
                }else if name.contains("Superman"){
                    item.title_image = "WB_Superman_Hope_Tile Group"
                }else if name.contains("Flash"){
                    item.title_image = "Flash Premium Tile Group_trio"
                }
                
            }
            newItems.append(item)
        }
        
        let marketplaceId = "iq__2YZajc8kZwzJGZi51HJB7TAKdio2"
        //let marketplace = try await self.getMarketplace(marketplaceId: marketplaceId)
        
        let prop = CreateTestPropertyModel(id:marketplaceId, title:"Fandango At Home", logo: "VUDU-white", image:"Search - Fandango", heroImage:"Fandango Property Page Header",
                                    featured: demoLib.featured, media: demoMedia, items:newItems)
        
        return prop
    }
    
    func createWbDemoProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.contains("Rings") {
                demoNfts.append(nft)
            }else if name.contains("Superman") {
                demoNfts.append(nft)
            }else if name.contains("Flash") {
                demoNfts.append(nft)
            }
        }
        
        let demoLib = try await parseNfts(demoNfts)
        
        /*for media in demoLib.featured.media {
            debugPrint("WB Featured: ", media.name)
        }*/

        
        var demoMedia : [MediaCollection] = []
        demoMedia.append(MediaCollection(name:"Video", media:demoLib.videos))
        demoMedia.append(MediaCollection(name:"Image Gallery", media:demoLib.galleries))
        demoMedia.append(MediaCollection(name:"Apps", media:demoLib.html))
        demoMedia.append(MediaCollection(name:"E-books", media:demoLib.books))
        
        var newItems : [NFTModel] = []
        
        for var item in demoLib.items{
            if let name = item.contract_name {
                if name.contains("Epic") {
                    item.title_image = "LOTR_Tile Group_Epic"
                }else  if name.contains("Shire") {
                    item.title_image = "LOTR_Tile Group_Shire"
                }else if name.contains("Superman"){
                    item.title_image = "WB_Superman_Hope_Tile Group"
                }else if name.contains("Flash"){
                    item.title_image = "Flash Premium Tile Group_trio"
                }
            }
            newItems.append(item)
        }
        
        let prop = CreateTestPropertyModel(title:"Movieverse", logo: "WarnerBrothersLogo", image:"Search - WB", heroImage:"Property_header_WB",
                                    featured: demoLib.featured, media: demoMedia, liveStreams: demoLib.liveStreams, items:newItems)
        
        return prop
    }
    
    func createFoxEntertainmentProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.lowercased().contains("fox") && name.lowercased().contains("entertainment"){
                demoNfts.append(nft)
            }
        }
        
        //print("MOON NFTS: ", nfts)
        
        let demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        /*
        demoMedia.append(MediaCollection(name:"Video", media:demoLib.videos))
        demoMedia.append(MediaCollection(name:"Image Gallery", media:demoLib.galleries))
        demoMedia.append(MediaCollection(name:"Apps", media:demoLib.html))
        demoMedia.append(MediaCollection(name:"E-books", media:demoLib.books))
         */
        
        var sections : [MediaSection] = []
        
        for item in demoLib.items {
            if let mediaSection = item.additional_media_sections {
                for section in mediaSection.sections {
                    sections.append(section)
                }
            }
        }

        
        //print("fox attributes: ",demoLib.items[0].meta_full)
        //print(demoLib.items[0].isSeries)

        
        let prop = CreateTestPropertyModel(title:"Fox Entertainment", logo: "FoxEntertainment_Logo", image:"Search - Fox Entertainment", heroImage:"Property_header_Fox_entertainment",  featured: demoLib.featured, media: demoMedia, sections: sections, items:demoLib.items)
        
        return prop
    }
    
    func createFoxSportsDemoProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.contains("Sports"){
                demoNfts.append(nft)
            }
        }
        
        let demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        demoMedia.append(MediaCollection(name:"Video", media:demoLib.videos))
        demoMedia.append(MediaCollection(name:"Image Gallery", media:demoLib.galleries))
        demoMedia.append(MediaCollection(name:"Apps", media:demoLib.html))
        demoMedia.append(MediaCollection(name:"E-books", media:demoLib.books))
        
        //print("videos count: ", demoLib.videos.count)
        //print("live stream count: ", demoLib.liveStreams.count)
        
        var newItems = demoLib.items
        
        
        var streams : [MediaItem] = []
        for var item in demoLib.liveStreams{
            //print("STREAM : ", item.name)
            if item.name.contains("KSAZ") {
                var schedule: [MediaItem] = []
                var media = MediaItem()
                var isoDate = "2023-06-14T19:00:00+0000"
                let dateFormatter = ISO8601DateFormatter()
                media.startDateTime = dateFormatter.date(from: isoDate)
                media.image = "ksaz01"
                schedule.append(media)
                
                isoDate = "2023-06-14T20:00:00+0000"
                var media2 = MediaItem()
                media2.startDateTime = dateFormatter.date(from: isoDate)
                media2.image = "ksaz02"
                schedule.append(media2)
                item.schedule = schedule
                
            }else if item.name.contains("KTTV") {
                var schedule: [MediaItem] = []
                var media = MediaItem()
                var isoDate = "2023-06-14T19:00:00+0000"
                let dateFormatter = ISO8601DateFormatter()
                media.startDateTime = dateFormatter.date(from: isoDate)
                media.image = "kttv01"
                schedule.append(media)
                
                isoDate = "2023-06-14T20:00:00+0000"
                var media2 = MediaItem()
                media2.startDateTime = dateFormatter.date(from: isoDate)
                media2.image = "kttv02"
                schedule.append(media2)

                
                isoDate = "2023-06-14T22:00:00+0000"
                var media3 = MediaItem()
                media3.startDateTime = dateFormatter.date(from: isoDate)
                media3.image = "kttv03"
                schedule.append(media3)
                
                isoDate = "2023-06-14T23:00:00+0000"
                var media4 = MediaItem()
                media4.startDateTime = dateFormatter.date(from: isoDate)
                media4.image = "kttv04"
                schedule.append(media4)
                
                item.schedule = schedule
            } else{
                var schedule: [MediaItem] = []
                for index in 0...4 {
                    var media = MediaItem()
                    var isoDate = "2023-06-14T1\(index):00:00+0000"
                    let dateFormatter = ISO8601DateFormatter()
                    media.startDateTime = dateFormatter.date(from: isoDate)
                    media.image = item.image
                    schedule.append(media)
                }
                item.schedule = schedule
            }
            
            
            
            streams.append(item)
        }
        
        var prop = CreateTestPropertyModel(title:"Fox Sports", logo: "FoxSportsLogo", image:"Search - Fox Sports", heroImage:"Property_header_fox_sport",  featured: demoLib.featured, media: demoMedia, liveStreams: streams, items:newItems)
        
        return prop
    }
    
    func createFoxNewsProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.contains("FOX News") {
                demoNfts.append(nft)
            }else if name.contains("FOX All USA") {
                demoNfts.append(nft)
            }
        }
        
        let demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        var sections : [MediaSection] = []
        var newItems : [NFTModel] = []
        
        for item in demoLib.items{
            if let additions = item.additional_media_sections {
                for section in additions.sections {
                    sections.append(section)
                    for collection in section.collections {
                        demoMedia.append(collection)
                    }
                }
            }
            newItems.append(item)
        }
        

        let prop = CreateTestPropertyModel(title:"Fox News", logo: "FoxLogo", image:"Search - Fox News", heroImage:"Property_header_fox_news",  featured: demoLib.featured, sections: sections, items:newItems)
        
        return prop
    }
    
    func createFoxWeatherProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.contains("FOX Weather") {
                demoNfts.append(nft)
            }
        }
        
        let demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        
        var newItems : [NFTModel] = []
        
        for item in demoLib.items{
            if let additions = item.additional_media_sections {
                for section in additions.sections {
                    for collection in section.collections {
                        demoMedia.append(collection)
                    }
                }
            }
            newItems.append(item)
        }
        
        let prop = CreateTestPropertyModel(title:"Fox Weather", logo: "FoxLogo", image:"Search - Fox Weather", heroImage:"Property_header_Fox_weather",  featured: demoLib.featured, media: demoMedia, items:newItems)
        
        return prop
    }
    
    func createDollyDemoProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.contains("Rose"){
                demoNfts.append(nft)
            }
        }
        
        var demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        demoMedia.append(MediaCollection(name:"Video", media:demoLib.videos))
        demoMedia.append(MediaCollection(name:"Image Gallery", media:demoLib.galleries))
        demoMedia.append(MediaCollection(name:"Apps", media:demoLib.html))
        demoMedia.append(MediaCollection(name:"E-books", media:demoLib.books))
        

        for index in 0..<demoLib.items.count{
            demoLib.items[index].background_image_tv = "Dolly_NFT-Detail-View-BG_4K"
        }
        
        var prop = CreateTestPropertyModel(title:"Dollyverse", logo: "DollyverseLogo", image:"Search - Dolly", heroImage:"Property_header_Dolly", featured: demoLib.featured, media: demoMedia, albums: demoLib.albums, items:demoLib.items)
        
        return prop
    }

    func createUEFAProp(nfts:[JSON]) async throws -> PropertyModel {
        debugPrint("CreateUEFAProp()")
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.lowercased().contains("uefa") {
                demoNfts.append(nft)
            }
            
            //debugPrint("UEFA NFT: ", nft)
        }
        
        let demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        var sections : [MediaSection] = []
        
        var newItems : [NFTModel] = []
        
        //debugPrint("Items ", demoLib.items.count)
        
        for item in demoLib.items{
            //debugPrint("Item ", item.contract_name)
            if let additions = item.additional_media_sections {
                //debugPrint("Additions sections number ", additions.sections.count)
                for section in additions.sections {
                    //debugPrint("Section: ", section.name)
                    sections.append(section)
                    /*for collection in section.collections {
                        demoMedia.append(collection)
                        debugPrint("Collection: ", collection.name)
                    }*/
                }
            }
            newItems.append(item)
        }

        let prop = CreateTestPropertyModel(title:"UEFA Euro2024", logo: "UEFA_light_logo", image:"UEFA", heroImage:"UEFA_property_strip",  featured: demoLib.featured, sections: sections, items:newItems)
        
        return prop
    }
    
    func createAFLProp(nfts:[JSON]) async throws -> PropertyModel {
        debugPrint("CreateAFLProp()")
        var demoNfts: [JSON] = []
        for nft in nfts{
            let address = nft["contract_addr"].stringValue
            if address.lowercased() == "0x3f50c094f5f48c87bb8c78bdb52c879aeba9ad9e" {
                demoNfts.append(nft)
            }
        }
        
        let demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        var sections : [MediaSection] = []
        
        var newItems : [NFTModel] = []
        
        for item in demoLib.items{
            if let additions = item.additional_media_sections {
                for section in additions.sections {
                    sections.append(section)
                    /*for collection in section.collections {
                        demoMedia.append(collection)
                        debugPrint("Collection: ", collection.name)
                    }*/
                }
            }
            newItems.append(item)
        }

        let prop = CreateTestPropertyModel(title:"AFL Plus", logo: "", image:"Search - AFL", heroImage:"Property_header_AFL",  featured: demoLib.featured, sections: sections, items:newItems)
        
        return prop
    }

    func setLogin(login:  LoginResponse, isMetamask: Bool = false, external: Bool = false) async throws {
        debugPrint("SetLogin ", login)
        guard let signer = self.signer else {
            return
        }

        await MainActor.run {
            self.login = login
            self.isLoggedOut = false
            self.signingIn = false
            
            self.isMetamask = isMetamask
            if(isMetamask){
                self.fabricToken = login.token
            }
            
            self.loginTime = Date()
            self.loginExpiration = Date(timeIntervalSinceNow:24*60*60)
        }
        

        if (!self.isMetamask){
            let result  = try await signer.createFabricToken( address: login.addr, contentSpaceId: self.getContentSpaceId(), authToken: login.token, external: external)
            await MainActor.run {
                self.fabricToken = result
            }
            debugPrint("get Fabric Token ", self.fabricToken)
        }
    

        if let profileClient = self.profileClient {
            let userAddress = try self.getAccountAddress()
            let userProfile = try await profileClient.getUserProfile(userAddress: userAddress)
            debugPrint("USER PROFILE: ", userProfile )
        }
        
        await self.refresh()
    }
    
    func resetWalletData(){
        self.library = MediaLibrary()
        self.properties = []

    }
    
    func signOut(){
        //print("Fabric: signOut()")
        if !self.isExternal {
            let domain = APP_CONFIG.auth0.domain
            let clientId = APP_CONFIG.auth0.client_id
            let oAuthEndpoint: String = "https://".appending(domain).appending("/oidc/logout");
            if let authRequest = ["client_id":clientId,"id_token_hint": self.signInResponse?.idToken] as? Dictionary<String,String> {
                AF.request(oAuthEndpoint , method: .post, parameters: authRequest, encoding: JSONEncoding.default)
                    .validate(statusCode: 200 ..< 299)
                    .responseData { response in
                        
                        print(response)
                        switch (response.result) {
                        case .success( _):
                            print("Logout Success!")
                        case .failure(let error):
                            print("Sign Out Request error: \(error.localizedDescription)")
                        }
                    }
            }
        }
        self.login = nil
        self.isLoggedOut = true
        self.signInResponse = nil
        self.signer = nil
        self.fabricToken = ""
        self.isMetamask = false

        resetWalletData()

        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "id_token")
        UserDefaults.standard.removeObject(forKey: "token_type")
        UserDefaults.standard.removeObject(forKey: "fabric_network")
        UserDefaults.standard.removeObject(forKey: "is_external")
    }
    
    @MainActor
    func signIn(credentials: [String: AnyObject], external: Bool = false ) async throws{

        guard let idToken: String = credentials["id_token"] as? String else {
            print("Could not retrieve id_token")
            return
        }
        
        //We do not get the refresh token with device sign in for some reason
        let refreshToken: String = credentials["refresh_token"] as? String ?? ""
        let accessToken: String = credentials["access_token"] as? String ?? ""

        var signInResponse = SignInResponse()
        signInResponse.idToken = idToken
        signInResponse.refreshToken = refreshToken
        signInResponse.accessToken = accessToken
        
        try await signIn(signInResponse: signInResponse, external: external)
    }
    
    @MainActor
    func signIn(signInResponse: SignInResponse , external: Bool = false) async throws {
        
        defer{
            self.signingIn = false
        }
        
        self.isExternal = external
        
        //print("Fabric: signIn()")
        guard let config = self.configuration else
        {
            print("Not configured.")
            throw FabricError.configError("Not configured.")
        }
        
        self.signInResponse = signInResponse
        
        var urlString = config.getAuthServices()[0] + "/wlt/login/jwt"
        
        if external {
            urlString = "https://wlt.stg.svc.eluv.io/as/wlt/login/jwt"
        }
        
        guard let url = URL(string: urlString) else {
            //throw FabricError.invalidURL
            print("Invalid URL \(urlString)")
            self.signingIn = false
            throw FabricError.invalidURL("Bad auth service url \(urlString)")
        }
        

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(signInResponse.idToken)", forHTTPHeaderField: "Authorization")
            
        let json: [String: Any] = ["ext": ["share_email":true]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        debugPrint("http request: ", request)
        
        let value = try await AF.request(request).debugLog().serializingDecodable(LoginResponse.self).value
        debugPrint("http response: ", value)
        
        UserDefaults.standard.set(signInResponse.accessToken, forKey: "access_token")
        UserDefaults.standard.set(signInResponse.idToken, forKey: "id_token")
        UserDefaults.standard.set(signInResponse.tokenType, forKey: "token_type")
        UserDefaults.standard.set(external, forKey: "is_external")
        
        try await self.setLogin(login: value, external:external)
    }
    
    
    func getAccountId() throws -> String {
        guard let address = self.login?.addr else
        {
            throw FabricError.noLogin("getAccountId")
        }
        
        guard let bytes = HexToBytes(address) else {
            throw FabricError.badInput("getAccountId error getting Bytes for address \(address)")
        }
        
        let encoded = Base58.base58Encode(bytes)
        
        return "iusr\(encoded)"
    }
    
    func getAccountAddress() throws -> String {
        guard let address = self.login?.addr else
        {
            throw FabricError.noLogin("getAccountAddress")
        }
        
        return FormatAddress(address: address)
    }
    
    func getOptionsJsonFromHash(versionHash: String) async throws -> JSON {
        var path = "/q/" + versionHash + "/meta/public/asset_metadata/sources/default"
        guard let url = URL(string:try self.getEndpoint()) else {
            throw FabricError.configError("getNFTData: could not get fabric endpoint")
        }
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.path = path
        components.queryItems = [
            URLQueryItem(name: "link_depth", value: "1"),
            URLQueryItem(name: "resolve", value: "true"),
            URLQueryItem(name: "resolve_include_source", value: "true"),
            URLQueryItem(name: "resolve_ignore_errors", value: "true")
        ]

        guard let newUrl = components.url else {
            throw FabricError.invalidURL("getNFTData: could not create url from components. \(components)")
        }
                                    
        //print("GET ",newUrl)

        return try await self.getJsonRequest(url: newUrl.absoluteString)
    }
    
    //Given a token uri with suffix /meta/public/nft, we retrieve the full one
    // with /meta/public/asset_metadata/nft
    func getNFTData(tokenUri: String ) async throws -> JSON {
            return try await withCheckedThrowingContinuation({ continuation in
                do {
                    /*
                    if !tokenUri.contains("/meta/public/nft") {
                        continuation.resume(throwing: FabricError.invalidURL("getNFTData: tokenUri does not contain /meta/public/nft. tokenUri: \(tokenUri)"))
                        return
                    }
                     */
                    
                    var path = "/meta/public/asset_metadata/nft"
                    guard let hash = FindContentHash(uri: tokenUri) else {
                        continuation.resume(throwing: FabricError.invalidURL("getNFTData: could not find content hash. tokenUri: \(tokenUri)"))
                        return
                    }
                    path = "/q/" + hash + path
                    
                    guard let url = URL(string:try self.getEndpoint()) else {
                        continuation.resume(throwing: FabricError.configError("getNFTData: could not get fabric endpoint"))
                        return
                    }
                    var components = URLComponents()
                    components.scheme = url.scheme
                    components.host = url.host
                    components.path = path
                    components.queryItems = [
                        URLQueryItem(name: "link_depth", value: "5"),
                        URLQueryItem(name: "resolve", value: "true"),
                        URLQueryItem(name: "resolve_include_source", value: "true"),
                        URLQueryItem(name: "resolve_ignore_errors", value: "true")
                    ]

                    guard let newUrl = components.url else {
                        continuation.resume(throwing: FabricError.invalidURL("getNFTData: could not create url from components. \(components)"))
                        return
                    }
                    
                    
                    let headers: HTTPHeaders = [
                        "Authorization": "Bearer \(self.fabricToken)",
                             "Accept": "application/json",
                             "Content-Type": "application/json" ]
                    
                    //print("GET ",newUrl)
                    //print("HEADERS ", headers)
                    
                    AF.request(newUrl, headers:headers)
                        .responseJSON { response in
                            //debugPrint("Response: \(response)")
                    switch (response.result) {

                        case .success( _):
                    
                            if let value = response.value {
                                continuation.resume(returning: JSON(value))
                            }else{
                                continuation.resume(throwing: FabricError.unexpectedResponse("getNFTData: could not get value from response \(response)"))
                            }
                        
                         case .failure(let error):
                            print("GetNFTData Request error: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                     }
                }
                }catch{
                    continuation.resume(throwing: error)
                }
            })
    }

    func getNFTMeta(tokenUri: String ) async throws -> NFTMetaResponse {
            return try await withCheckedThrowingContinuation({ continuation in
                    AF.request(tokenUri)
                        .validate()
                        .responseDecodable(of: NFTMetaResponse.self){ response in
                            debugPrint("Response: \(response)")
                    switch (response.result) {
                        case .success( _):
                            guard let value = response.value else {
                                continuation.resume(throwing: FabricError.unexpectedResponse("getNFTMeta: could not get value from response \(response)"))
                                return
                            }
                            continuation.resume(returning: value)
                         case .failure(let error):
                            print("Request error: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                     }
                }
            })
    }
    
    func startDeviceCodeFlow(completion: @escaping ([String: AnyObject]?, String?) -> Void){
        print("startDeviceCodeFlow")
        let domain = APP_CONFIG.auth0.domain
        let clientId = APP_CONFIG.auth0.client_id
        let oAuthEndpoint: String = "https://".appending(domain).appending("/oauth/device/code");
        let authRequest = ["client_id":clientId,"scope": "openid profile email"] as! Dictionary<String,String>
        AF.request(oAuthEndpoint , method: .post, parameters: authRequest, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch (response.result) {
                    case .success( _):
                        if let value = response.value as? [String: AnyObject] {
                            completion(value, nil)
                        }
                     case .failure(let error):
                        print("Start Device Code Flow Request error: \(error.localizedDescription)")
                        completion(nil, response.error?.localizedDescription)
                 }

                return
        }
    }
    
    private func getKeyMediaProgressContainer() throws -> String {
        return "\(try getAccountAddress()) - media_progress"
    }
    
    func getUserViewedProgressContainer() throws -> MediaProgressContainer {
        //TODO: Store these constants for user defaults somewhere
        guard let data = UserDefaults.standard.object(forKey: try getKeyMediaProgressContainer()) as? Data else {
            debugPrint("Couldn't find media_progress from defaults.")
            return MediaProgressContainer()
        }
        
        let decoder = JSONDecoder()
        guard let container = try? decoder.decode(MediaProgressContainer.self, from: data) else {
            debugPrint("Couldn't decode media_progress from defaults.")
            return MediaProgressContainer()
        }
        
        return container
    }
    
    //TODO: Retrieve from app services profile
    func getUserViewedProgress(nftContract: String, mediaId: String) throws -> MediaProgress {
        if let container = try? getUserViewedProgressContainer() {
            //TODO: create a key maker function
            let mediaProgress = container.media["nft-media-viewed-\(nftContract)-\(mediaId)-progress"] ?? MediaProgress()
            debugPrint("getUserViewedProgress \(mediaProgress)")
            return mediaProgress
        }
        debugPrint("getUserViewedProgress - could not get container")
        return MediaProgress()
    }
    
    //TODO: Set into the app services profile
    func setUserViewedProgress(nftContract: String, mediaId: String, progress:MediaProgress) throws{
        debugPrint("setUserViewedProgress contract \(nftContract) mediaId \(mediaId) progress \(progress)")
        var container = MediaProgressContainer()
        do {
            container = try getUserViewedProgressContainer()
        }catch{
            debugPrint("No previous user progress found.")
        }
        
        container.media["nft-media-viewed-\(nftContract)-\(mediaId)-progress"] = progress
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(container) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: try getKeyMediaProgressContainer())
            debugPrint("Saved to defaults")
        }else {
            debugPrint("Could not encode progress info ", container)
        }
    }
    
    func getUserInfo(domain: String, accessCode: String, completion: @escaping ([String: AnyObject]?, String?) -> Void){
        let oAuthEndpoint: String = "https://".appending(domain).appending("/userinfo");
        let headers: HTTPHeaders = [
                 "Authorization": "Bearer \(accessCode)",
                 "Accept": "application/json",
                 "Content-Type": "application/json" ]
        
        AF.request(oAuthEndpoint , method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                switch (response.result) {
                    case .success( _):
                        if let value = response.value as? [String: AnyObject] {
                            completion(value, nil)
                        }
                     case .failure(let error):
                        print("Get User Info Request error: \(error.localizedDescription)")
                        completion(nil, response.error?.localizedDescription)
                 }

                return
        }
    }
    
    func getOptions(versionHash:String , params: [JSON]? = [], offering:String="default") async throws -> JSON {
        var path = NSString.path(withComponents: ["/","q",versionHash,"rep","playout",offering,"options.json"])
        
        var urlString = try self.getEndpoint()
        
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
        
        var queryItems : [URLQueryItem] = []
        
        components.queryItems = queryItems
        
        for param in params! {
            if let name = param["name"].string {
                if let value = param["value"].string {
                    components.queryItems?.append(URLQueryItem(name: name , value: value))
                }
            }
        }
        
        guard let newUrl = components.url else {
            throw FabricError.badInput("getUrlFromLink: Could not get url from components. Hash: \(versionHash), Offering: \(offering)")
        }

        var optionsUrl = newUrl.standardized.absoluteString
        
        print("options url \(optionsUrl)")
        
        let optionsJson = try await getJsonRequest(url: optionsUrl)
        //print("options json \(optionsJson)")
        
        return optionsJson
    }
    
    func getOptionsFromLink(link: JSON?, params: [JSON]? = [], offering:String="default") async throws -> (optionsJson: JSON, versionHash:String) {
        var optionsUrl = try getUrlFromLink(link: link, params: params)

        if(offering != "default" && optionsUrl.contains("default/options.json")){
            optionsUrl = optionsUrl.replaceFirst(of: "default/options.json", with: "\(offering)/options.json")
        }
        
        //print ("Offering \(offering)")
        print("options url \(optionsUrl)")
        
        
        guard let versionsHash = FindContentHash(uri: optionsUrl) else {
            throw RuntimeError("Could not find hash from \(optionsUrl)")
        }
        
        let optionsJson = try await getJsonRequest(url: optionsUrl)
        //print("options json \(optionsJson)")
        
        return (optionsJson, versionsHash)
    }
    
    func getMediaHTML(link: JSON?, params: [JSON] = []) throws -> String {
        //FIXME: Use configuration
        let baseUrl = self.network == "demo" ? "https://demov3.net955210.contentfabric.io/s/demov3" :
            "https://main.net955305.contentfabric.io/s/main"
        return try getUrlFromLink(link:link, baseUrl: baseUrl, params: params, includeAuth: true)
    }
    
    func getUrlFromLink(link: JSON?, baseUrl: String? = nil, params: [JSON]? = [], includeAuth: Bool? = true, resolveHeaders: Bool? = false) throws -> String {
        guard let link = link else{
            throw FabricError.badInput("getUrlFromLink: Link is nil")
        }
        

        var path = link["/"].stringValue
        var hash = link["."]["container"].stringValue
        
        if (path.hasPrefix("/qfab")){
            hash = ""
            path = path.replaceFirst(of: "/qfab", with: "")
        }
                
        path = NSString.path(withComponents: ["/","q",hash,path])
        
        var urlString = baseUrl ?? ""
        
        if urlString.isEmpty {
            urlString = try self.getEndpoint()
        }
        
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
        
        var queryItems : [URLQueryItem] = []
        if includeAuth! {
            queryItems.append(URLQueryItem(name: "authorization", value: self.fabricToken))
        }
        
        if resolveHeaders! {
            queryItems.append(URLQueryItem(name: "link_depth", value: "5"))
            queryItems.append(URLQueryItem(name: "resolve_include_source", value: "true"))
            queryItems.append(URLQueryItem(name: "resolve", value: "true"))
            queryItems.append(URLQueryItem(name: "resolve_ignore_errors", value: "true"))
        }
        
        components.queryItems = queryItems
        
        for param in params! {
            if let name = param["name"].string {
                if let value = param["value"].string {
                    components.queryItems?.append(URLQueryItem(name: name , value: value))
                }
            }
        }
        
        
        guard let newUrl = components.url else {
            throw FabricError.badInput("getUrlFromLink: Could not get url from components. Link: \(link)")
        }
        
        return newUrl.standardized.absoluteString
    }
    
    //Convenience for early code
    func getJsonRequest(url: String, accessToken: String? = nil, parameters : [String: String] = [:], noAuth: Bool = false) async throws -> JSON {
        return try await httpJsonRequest(url: url, method: .get, accessToken: accessToken, parameters: parameters, noAuth: noAuth)
    }
    
    func httpJsonRequest(url: String, method: HTTPMethod, accessToken: String? = nil, parameters : [String: String] = [:], noAuth: Bool = false, body: String = "") async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            
            var token = accessToken ?? ""
            
            if token.isEmpty && noAuth == false {
                token = self.fabricToken
            }
            
            var headers: HTTPHeaders = [
                     "Accept": "application/json"]
            
            if !token.isEmpty {
                headers["Authorization"] =  "Bearer \(token)"
            }

            debugPrint("GET ",url)
            debugPrint("HEADERS ", headers)
            
            var components = URLComponents(string: url)!
            components.queryItems = parameters.map { (key, value) in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            var request = URLRequest(url: components.url!)

            request.httpMethod = method.rawValue
            request.headers = headers
            if (!body.isEmpty){
                request.httpBody = body.data(using: .utf8)
            }
            
            //AF.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers:headers)
            AF.request(request)
                .debugLog()
                .responseJSON { response in
                    
                    debugPrint("getJsonRequest response:\n")
                switch (response.result) {
                    case .success( _):
                        let value = JSON(response.value!)
                        continuation.resume(returning: value)
                     case .failure(let error):
                        print("Get JSON Request error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                 }
            }
        })
    }
    
    func httpDataRequest(url: String, method: HTTPMethod, accessToken: String? = nil, parameters : [String: String] = [:], noAuth: Bool = false, body: String = "") async throws -> Data {
        return try await withCheckedThrowingContinuation({ continuation in
            
            var token = accessToken ?? ""
            
            if token.isEmpty && noAuth == false {
                token = self.fabricToken
            }
            
            var headers: HTTPHeaders = []
            
            if !token.isEmpty {
                headers["Authorization"] =  "Bearer \(token)"
            }

            debugPrint("GET ",url)
            debugPrint("HEADERS ", headers)
            
            var components = URLComponents(string: url)!
            components.queryItems = parameters.map { (key, value) in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            var request = URLRequest(url: components.url!)

            request.httpMethod = method.rawValue
            request.headers = headers
            if (!body.isEmpty){
                request.httpBody = body.data(using: .utf8)
            }

            AF.request(request)
                .debugLog()
                .responseData { response in
                    
                    debugPrint("getJsonRequest response:\n")
                switch (response.result) {
                    case .success( _):
                        continuation.resume(returning: response.value!)
                     case .failure(let error):
                        print("Get JSON Request error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                 }
            }
        })
    }
    
    func getHlsPlaylistFromOptions(optionsJson: JSON?, hash: String, drm: String = "hls-clear", offering: String = "default") throws -> String {
        guard let link = optionsJson else{
            throw FabricError.badInput("getHlsPlaylistFromOptions: optionsJson is nil")
        }
        

        if (hash.isEmpty) {
            throw FabricError.badInput("getHlsPlaylistFromOptions: hash is empty")
        }
        

        var uri = link[drm]["uri"].stringValue
        
        guard let url = URL(string:try self.getEndpoint()) else {
            throw FabricError.badInput("getHlsPlaylistFromOptions: Could not get parse endpoint. Link: \(link)")
        }
        
        var newUrl = "\(url.absoluteString)/q/\(hash)/rep/playout/\(offering)/\(uri)"
        if(newUrl.contains("?")){
            newUrl = newUrl + "&authorization=\(self.fabricToken)"
        }else{
            newUrl = newUrl + "?authorization=\(self.fabricToken)"
        }
        
        print("HLS URL: ", newUrl)
        
        return newUrl
    }
    
    func checkToken(completion: @escaping (Bool) -> Void) {
        guard let accessToken = UserDefaults.standard.object(forKey: "access_token")
            as? String else {
                completion(false)
                return
        }
        let domain = APP_CONFIG.auth0.domain
        let userInfo: String = "https://".appending(domain).appending("/userinfo");
        let url = URL(string: userInfo)!
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        AF.request(urlRequest)
            .responseJSON { response in
                switch (response.result) {
                    case .success( _):
                        guard (response.value as? [String: AnyObject]) != nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                     case .failure(let error):
                        print("Check Token Request error: \(error.localizedDescription)")
                        completion(false)
                 }
        }
    }
    
    func getNFT(contract: String,
                token: String="") -> NFTModel?{
        debugPrint("Fabric getNFT \(contract) token: \(token)")
        for nft in library.items {
            debugPrint("Contract", nft.contract_addr)
            debugPrint("Token", nft.token_id_str)

            if token != "" {
                if nft.contract_addr == contract.lowercased() &&
                    nft.token_id_str == token {
                    debugPrint("Found NFT")
                    return nft
                }
            }else {
                if nft.contract_addr == contract.lowercased() {
                    debugPrint("Found NFT")
                    return nft
                }
            }
        }
        
        debugPrint("Could not find token")
        return nil
    }
    
    
    //Move this to ElvLive class
    func getTenants() async throws -> JSON {
        print ("getTenants")
        let objectId = try self.getNetworkConfig().main_obj_id
        let libraryId = try self.getNetworkConfig().main_obj_lib_id
        let metadataSubtree = "public/asset_metadata/tenants"
        return try await self.contentObjectMetadata(id:objectId, metadataSubtree:metadataSubtree)
    }
    
    
    //Retrieve all wallet items sorted by tenant id
    //TODO: Cache items
    func getWalletTenantItems() async throws -> [JSON]{
        print ("getWalletTenantItems")
        let tenants = try await self.getTenants()
        var tenantItems : [JSON] = []
        
        for (_, tenant) in tenants {
            let tenantId = tenant["info"]["tenant_id"].stringValue
            let tenantTitle = tenant["title"].stringValue
            print("Tenant: \(tenantTitle) : \(tenantId)")
            
            let parameters : [String: String] = ["filter":"tenant:eq:\(tenantId)"]
            
            var items : JSON
            do {
                let response = try await self.signer!.getWalletData(accountAddress: try getAccountAddress(),
                                                                    accessCode: self.fabricToken, parameters:parameters)
                items = response.result
            }catch{
                continue
            }
            //print("Items: \(items)")
            let nfts = items["contents"].arrayValue
            if !nfts.isEmpty {
                for (_, marketplace) in tenant["marketplaces"] {
                    //print(marketplace)
                    var matchedItems : [JSON] = []
                    
                    for (_, mItem) in marketplace["info"]["items"] {
                        let mAddress = mItem["nft_template"]["nft"]["address"]
                        for item in nfts {
                            print("market item address", mAddress.stringValue)
                            
                            print("item address", item["contract_addr"])
                            let address = item["contract_addr"].stringValue
                            if (mAddress.stringValue.lowercased() == address.lowercased()){
                                matchedItems.append(item)
                                print("Found item ", address)
                            }
                            
                        }
                    }
                    
                    if (!matchedItems.isEmpty){
                        print("Found nfts")
                        let tenantItem : JSON = ["tenant":tenant, "marketplace": marketplace, "nfts": matchedItems]
                        tenantItems.append(tenantItem)
                    }
                }
            }
        }
        
        return tenantItems
    }
    
    func createStaticToken() -> String {
        do {
            let qspaceId = try getContentSpaceId()
            var dict : [String: Any] = [ "qspace_id": qspaceId ]
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
            return jsonString.base64()
        }catch{
            print(error.localizedDescription)
        }
        
        return ""
    }
    
    func createUrl(path:String, token: String = "") -> String {
        do {
            return try getEndpoint() + path + "?authorization=\(token.isEmpty ? createStaticToken() : token)"
        }catch{
            print(error.localizedDescription)
        }
        return ""
    }
    
    //ELV-CLIENT API
    
    // id is objectId or versionHash
    func contentObjectMetadata(id: String, metadataSubtree: String? = "") async throws -> JSON {
        let url: String = try self.getEndpoint().appending("/s/\(network)/").appending("/q/").appending("\(id)").appending("/meta/\(metadataSubtree!)").appending("?\(Fabric.CommonFabricParams)")

        return try await self.getJsonRequest(url: url)
    }
    
    
    //TODO: Use contract call to get lib ID from objectID
    func contentObjectLibraryId(_objectId: String?) async throws -> String {
        return ""
    }
}


