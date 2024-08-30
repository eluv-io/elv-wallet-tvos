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
    //var isMetamask = false
    //Logged in using 3rdparty token through deep link
    //var isExternal = false
    
    var createDemoProperties : Bool = true
    
    var previousRefreshHash = SHA256.hash(data:Data())
    
    @Published
    var configuration : FabricConfiguration? = nil
    
    /*
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
     
     */
    
    //Move these models to the app level
    @Published
    var library: MediaLibrary = MediaLibrary()

    //DEMO ONLY
    @Published
    var properties: [PropertyModel] = []
    
    //Media Properties from Creator Studio
    @Published
    var mediaProperties: MediaPropertiesResponse = MediaPropertiesResponse()
    
    @Published
    var mediaPropertiesCache : [String: MediaProperty] = [:]
    @Published
    var mediaPropertiesPageCache : [String: MediaPropertyPage] = [:]
    @Published
    var mediaPropertiesSectionCache : [String: MediaPropertySection] = [:]
    @Published
    var mediaPropertiesMediaItemCache : [String: MediaPropertySectionMediaItem] = [:]
    
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
    
    /*
    func signOutIfExpired()  {
        if self.loginTime != self.loginExpiration {
            if Date() > self.loginExpiration {
                self.signOut()
            }
        }
    }
    */
    
    
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
        /*defer {
            self.signingIn = false
            debugPrint("Fabric connect finished")
        }
        self.signingIn = true
         */
        
        var _network = network
        if(network.isEmpty) {
            guard let savedNetwork = UserDefaults.standard.object(forKey: "fabric_network")
                    as? String else {
                //self.isLoggedOut = true
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
        debugPrint("Static token: ", fabricToken)
        
        if signIn {
            /*
                if (self.isMetamask == true){
                    debugPrint("is Metamask login, skipping checkToken")
                    return
                }
                
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
             */
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
    
    func parseNfts(_ nfts: [JSON], propertyId: String) async throws -> [NFTModel] {
        var items : [NFTModel] = []
        for nft in nfts {
            do {
                let data = try nft.rawData()
                var nftmodel = try JSONDecoder().decode(NFTModel.self, from: data)
                
                if (nftmodel.id == nil){
                    if let contract = nftmodel.contract_addr {
                        if let token = nftmodel.token_id_str {
                            nftmodel.id = "\(contract) : \(token )"
                        }
                    }
                    
                    if nftmodel.id == nil {
                        continue
                    }
                }

                if !propertyId.isEmpty {
                    if let nftTemplate = nftmodel.nft_template{
                        debugPrint("bundled_id: ", nftTemplate["bundled_property_id"].stringValue)
                        if nftTemplate["bundled_property_id"].stringValue == propertyId{
                            items.append(nftmodel)
                        }
                    }
                }else {
                    items.append(nftmodel)
                }
            } catch {
                print(error)
                continue
            }
        }
        
        return items
    }
    
    func parseNftsToLibrary(_ nfts: [JSON]) async throws -> MediaLibrary {
        
        var featured = Features()
        
        var items : [NFTModel] = []
        //var mediaRows: [MediaRowViewModel] = []
        for nft in nfts {
            //var mediaRow = MediaRowViewModel()
            
            do {
                let data = try nft.rawData()
                let nftmodel = try JSONDecoder().decode(NFTModel.self, from: data)
                
                let parsedModels = try await self.parseNft(nftmodel)
                guard let model = parsedModels.nftModel else {
                    print("Error parsing nft: \(nft)")
                    continue
                }
                /*
                if(model.has_album ?? false){
                    mediaRow.albums.append(model)
                }
                 */
                items.append(model)
                /*
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
                 */
                
            } catch {
                print(error)
                continue
            }
        }
        
        print("Features: ", featured.unique().media.count)
        
        return MediaLibrary(features: featured.unique(), items: items/*, mediaRows: mediaRows*/)
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
                items.append(nftmodel)
/*
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
 */
                
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
            //debugPrint(nftData["redeemable_offers"])
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
        /*if self.signingIn {
            return
        }
         */
        
        if self.isRefreshing {
            return
        }
        
        guard let signer = self.signer else {
            print("Signer was not initialized!")
            return
        }
        
        self.isRefreshing = true
        defer{
            isRefreshing = false
        }
        

        do{
            try await profile.refresh()
            /*
            if (!self.isMetamask && self.login != nil){
                if let login = self.login {
                    self.fabricToken = try await signer.createFabricToken( address: self.getAccountAddress(), contentSpaceId: self.getContentSpaceId(), authToken: login.token, external: self.isExternal)
                }
            }else{
                self.fabricToken = createStaticToken()
            }
             */

            /*
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
             */

            do {
                let mediaProperties = try await signer.getProperties(accessCode: self.fabricToken)
                
                try await cacheMediaProperties(properties: mediaProperties)
                
                //debugPrint("MEDIA PROPERTIES: ", mediaProperties)
                self.mediaProperties = mediaProperties
            }catch {
                print ("error getting mediaProperties: \(error)")
            }
            
            isRefreshing = false
        }catch{
            print ("Refresh Error: \(error)")
            //signOut()
        }
    }
    
    func getNFTs(address:String, propertyId:String="", description:String="") async throws -> [NFTModel]{
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not initialized.")
        }
        let response = try await signer.getWalletData(accountAddress: address,
                                                      propertyId:propertyId,
                                                      description:description,
                                                      accessCode: self.fabricToken)
        let profileData = response.result
        return try await parseNfts(profileData["contents"].arrayValue, propertyId:propertyId)
    }
    
    func getProperties(includePublic: Bool) async throws -> [MediaProperty] {
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not initialized.")
        }
        
        let response = try await signer.getProperties(includePublic:includePublic, accessCode: self.fabricToken)
        return response.contents
    }
    
    func getPropertyPage(property: String, page: String) async throws -> MediaPropertyPage? {
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not initialized.")
        }
        
        if mediaPropertiesCache.isEmpty {
            let mediaProperties = try await signer.getProperties(accessCode: self.fabricToken)
            try await cacheMediaProperties(properties: mediaProperties)
        }
        
        if let property = try await getProperty(property: property) {
            
            //return mediaPropertiesPageCache["\(property)\(page)"]
            //TODO: Do page caching and use other pages when ids are unique. Right now it's always "main"
            return property.main_page
        }
        
        return nil
    }
    
    func getMediaCatalogJSON(mediaId: String) async throws -> JSON? {
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not initialized.")
        }
        
        return try await signer.getMediaCatalogJSON(accessCode: self.fabricToken, mediaId: mediaId)
    }
    
    func getProperty(property: String, noCache:Bool=false) async throws -> MediaProperty? {
        guard let signer = self.signer else {
            throw FabricError.configError("Signer not initialized.")
        }
        
        if mediaPropertiesCache.isEmpty || noCache {
            let mediaProperties = try await signer.getProperties(accessCode: self.fabricToken)
            try await cacheMediaProperties(properties: mediaProperties)
        }
        
        return mediaPropertiesCache[property]
    }
    
    func getPropertyItems(property: String, sections: [String]) async throws -> JSON {
        guard let signer = self.signer else {
            throw FabricError.configError("Could not get signer.")
        }
        
        let result = try await signer.getPropertySectionsJSON(property: property, sections: sections, accessCode: self.fabricToken)
        
        return result
    }
    
    func getPropertySectionsJSON(property: String, sections: [String]) async throws -> JSON {
        guard let signer = self.signer else {
            throw FabricError.configError("Could not get signer.")
        }
        
        let result = try await signer.getPropertySectionsJSON(property: property, sections: sections, accessCode: self.fabricToken)
        
        return result
    }
    
    
    func getPropertySections(property: String, sections: [String]) async throws -> [MediaPropertySection] {
        if mediaPropertiesSectionCache.isEmpty {
            try await cachePropertySections(property: property, sections: sections)
        }
        
        var retValue: [MediaPropertySection] = []
        
        for id in sections {
            if let section = self.mediaPropertiesSectionCache[id] {
                retValue.append(section)
            }else {
                try await cachePropertySections(property: property, sections: [id])
                if let section = self.mediaPropertiesSectionCache[id] {
                    retValue.append(section)
                }
            }
        }
        
        return retValue
    }
    
    func getPropertyMediaItems(property: String, mediaItems: [String]) async throws -> [MediaPropertySectionMediaItem] {
        if mediaPropertiesMediaItemCache.isEmpty {
            try await cacheMediaItems(property: property, mediaItems: mediaItems)
        }
        
        var retValue: [MediaPropertySectionMediaItem] = []
        
        for id in mediaItems {
            if let item = self.mediaPropertiesMediaItemCache[id] {
                retValue.append(item)
            }else {
                try await cacheMediaItems(property: property, mediaItems: [id])
                if let item = self.mediaPropertiesMediaItemCache[id] {
                    retValue.append(item)
                }
            }
        }
        
        return retValue
    }
    
    
    func cacheMediaItems(property: String, mediaItems: [String]) async throws{
        guard let signer = self.signer else {
            throw FabricError.configError("Could not get signer.")
        }

        let result = try await signer.getMediaItems(property: property, mediaItems: mediaItems, accessCode: self.fabricToken)

        await MainActor.run {
            for item in result.contents {
                if let id = item.id {
                    self.mediaPropertiesMediaItemCache[id] = item
                }
            }
        }
    }
    
    func cachePropertySections(property: String, sections: [String]) async throws{
        guard let signer = self.signer else {
            throw FabricError.configError("Could not get signer.")
        }

        let result = try await signer.getPropertySections(property: property, sections: sections, accessCode: self.fabricToken)
        
        
        await MainActor.run {
            for section in result.contents {
                self.mediaPropertiesSectionCache[section.id] = section
                if let sectionContents = section.content {
                    for item in sectionContents {
                        if let media = item.media {
                            //debugPrint("Adding media item to cache", media.id)
                            if let id = media.id {
                                self.mediaPropertiesMediaItemCache[id] = media
                            }
                        }
                    }
                }
            }
        }
            
            //self.mediaPropertiesSectionCache = self.mediaPropertiesSectionCache
            //self.mediaPropertiesMediaItemCache = self.mediaPropertiesMediaItemCache
    }
    
    func cacheMediaProperties(properties: MediaPropertiesResponse) async throws{
        
        var mediaProperties : [String : MediaProperty] = [:]
        
        for property in properties.contents {
            if let id = property.id {
                if id.isEmpty {
                    continue
                }
                mediaProperties[id] = property
                
                /*
                var sections: [String] = []
                
                do {
                    let sec = property.main_page?.layout?["sections"].arrayValue ?? []
                    for s in sec {
                        sections.append(s.stringValue)
                    }
                }
                
                //try await cachePropertySections(property: id, sections: sections)
                 */
            }
        }
        
        let props = mediaProperties
        
        await MainActor.run {
            self.mediaPropertiesCache = props
        }
    }
    
    func getMediaItem(mediaId:String) -> MediaPropertySectionMediaItem? {
        if let item = self.mediaPropertiesMediaItemCache[mediaId] {
            return item
        }
        debugPrint("Couldn't find media item", mediaId)
        return nil
    }
    
    func searchProperty(property: String, tags:[String] = [], attributes: [String: Any] = [:], searchTerm: String = "", limit:Int=30) async throws -> [MediaPropertySection] {
        
        guard let signer = self.signer else {
            throw FabricError.configError("Could not get signer.")
        }

        let result = try await signer.searchProperty(property: property, tags:tags, attributes: attributes, searchTerm: searchTerm, limit:limit, accessCode: self.fabricToken)
        
        return result
    }
    
    func getPropertyFilters(property: String, primaryFilter: String = "") async throws -> JSON {
        
        guard let signer = self.signer else {
            throw FabricError.configError("Could not get signer.")
        }

        let result = try await signer.getPropertyFilters(property: property, primaryFilter: primaryFilter, accessCode: self.fabricToken)
        
        return result
    }
    
    //exchanges id token for cluster token
    func login(idToken: String, address: String = "", external: Bool = false) async throws -> LoginResponse {
        var login = LoginResponse()
        if !external {
            
            guard let config = self.configuration else
            {
                print("Not configured.")
                throw FabricError.configError("Not configured.")
            }
            
            var urlString = config.getAuthServices()[0] + "/wlt/login/jwt"
            
            if external {
                urlString = "https://wlt.stg.svc.eluv.io/as/wlt/login/jwt"
            }
            
            guard let url = URL(string: urlString) else {
                //throw FabricError.invalidURL
                print("Invalid URL \(urlString)")
                throw FabricError.invalidURL("Bad auth service url \(urlString)")
            }
            
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
            let json: [String: Any] = ["ext": ["share_email":true]]
            request.httpBody = try! JSONSerialization.data(withJSONObject: json, options: [])
            
            debugPrint("http request: ", request)
            
            login = try await AF.request(request).debugLog().serializingDecodable(LoginResponse.self).value
            debugPrint("http response: ", login)
            
            //UserDefaults.standard.set(signInResponse.accessToken, forKey: "access_token")
            //UserDefaults.standard.set(signInResponse.idToken, forKey: "id_token")
            //UserDefaults.standard.set(signInResponse.tokenType, forKey: "token_type")
            //UserDefaults.standard.set(external, forKey: "is_external")
        }else {
            login.token = idToken
            login.addr = address
        }
        
        return login
    }
    
    
    
    func createFabricToken(idToken: String, address: String = "", external: Bool = false) async throws -> String {
        guard let signer = self.signer else {
            throw FabricError.configError("Could not get signer.")
        }
        
        guard let config = self.configuration else
        {
            print("Not configured.")
            throw FabricError.configError("Not configured.")
        }
        
        var response = try await login(idToken:idToken, address:address, external: external)
        var authToken = ""
        return try await signer.createFabricToken( address:response.addr, contentSpaceId: self.getContentSpaceId(), authToken: response.token, external: external)
    }
    
    func createFabricToken(login:LoginResponse, external: Bool = false) async throws -> String {
        guard let signer = self.signer else {
            throw FabricError.configError("Could not get signer.")
        }
        
        guard let config = self.configuration else
        {
            print("Not configured.")
            throw FabricError.configError("Not configured.")
        }

        return try await signer.createFabricToken( address:login.addr, contentSpaceId: self.getContentSpaceId(), authToken: login.token, external: external)
    }
    
/*
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
        Task{
            await self.refresh()
        }
    }
    */
    
    func resetWalletData(){
        self.library = MediaLibrary()
        self.properties = []
        self.mediaProperties = MediaPropertiesResponse()
        self.mediaPropertiesCache = [:]
        self.mediaPropertiesMediaItemCache = [:]
        self.mediaPropertiesSectionCache = [:]
    }
    
    func reset(){
        self.signer = nil
        self.fabricToken = ""
        //self.isMetamask = false

        resetWalletData()

        UserDefaults.standard.removeObject(forKey: "fabric_network")
        UserDefaults.standard.removeObject(forKey: "is_external")
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
    
    private func getKeyMediaProgressContainer(address:String) throws -> String {
        return "\(address) - media_progress"
    }
    
    func getUserViewedProgressContainer(address:String) throws -> MediaProgressContainer {
        //TODO: Store these constants for user defaults somewhere
        guard let data = UserDefaults.standard.object(forKey: try getKeyMediaProgressContainer(address:address)) as? Data else {
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
    func getUserViewedProgress(address:String, nftContract: String, mediaId: String) throws -> MediaProgress {
        if let container = try? getUserViewedProgressContainer(address:address) {
            //TODO: create a key maker function
            let mediaProgress = container.media["nft-media-viewed-\(nftContract)-\(mediaId)-progress"] ?? MediaProgress()
            debugPrint("getUserViewedProgress \(mediaProgress)")
            return mediaProgress
        }
        debugPrint("getUserViewedProgress - could not get container")
        return MediaProgress()
    }
    
    //TODO: Set into the app services profile
    func setUserViewedProgress(address: String, nftContract: String, mediaId: String, progress:MediaProgress) throws{
        debugPrint("setUserViewedProgress contract \(nftContract) mediaId \(mediaId) progress \(progress)")
        var container = MediaProgressContainer()
        do {
            container = try getUserViewedProgressContainer(address: address)
        }catch{
            debugPrint("No previous user progress found.")
        }
        
        container.media["nft-media-viewed-\(nftContract)-\(mediaId)-progress"] = progress
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(container) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: try getKeyMediaProgressContainer(address:address))
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
    
    //New API for media item playout
    func getMediaPlayoutOptions(propertyId:String, mediaId:String) async throws -> JSON {
        let path = "/as/mw/properties/" + propertyId + "/media_items/" + mediaId + "/offerings/any/playout_options"
        
        guard let signer = self.signer else {
            throw FabricError.configError("getPlayoutFromMediaId: could not get authD endpoint")
        }
        
        guard let url = URL(string:try signer.getAuthEndpoint()) else {
            throw FabricError.configError("getPlayoutFromMediaId: could not get fabric endpoint")
        }
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.path = path

        guard let newUrl = components.url else {
            throw FabricError.invalidURL("getPlayoutFromMediaId: could not create url from components. \(components)")
        }
                                    
        print("GET ",newUrl)

        return try await self.getJsonRequest(url: newUrl.absoluteString)
    }
    
    
    //New API for media item playout. optionsJson is from the media api, not from fabric options
    func getHlsPlaylistFromMediaOptions(optionsJson: JSON?, drm: String = "hls-clear", offering: String = "default") throws -> String {
        guard let link = optionsJson else{
            throw FabricError.badInput("getHlsPlaylistFromOptions: optionsJson is nil")
        }
        
        debugPrint("getHlsPlaylistFromMediaOptions ", optionsJson)
        debugPrint("drm ", drm)

        let uri = link[drm]["uri"].stringValue
        debugPrint("uri ", drm)
        
        guard let url = URL(string:try self.getEndpoint()) else {
            throw FabricError.badInput("getHlsPlaylistFromOptions: Could not get parse endpoint. Link: \(link)")
        }
        
        var newUrl = "\(url.absoluteString)/\(uri)"
        if(newUrl.contains("?")){
            newUrl = newUrl + "&authorization=\(self.fabricToken)"
        }else{
            newUrl = newUrl + "?authorization=\(self.fabricToken)"
        }
        
        print("HLS URL: ", newUrl)
        
        return newUrl
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
    
    //Deprectated: Doesn't work with Live
    func getOptionsFromLink(link: JSON?, params: [JSON]? = [], offering:String="default", hash:String="") async throws -> (optionsJson: JSON, versionHash:String) {
        var optionsUrl = try getUrlFromLink(link: link, params: params, hash:hash)

        if(offering != "default" && optionsUrl.contains("default/options.json")){
            optionsUrl = optionsUrl.replaceFirst(of: "default/options.json", with: "\(offering)/options.json")
        }
        
        //print ("Offering \(offering)")
        print("options url \(optionsUrl)")
        
        
        guard let versionsHash = FindContentHash(uri: optionsUrl) else {
            throw RuntimeError("Could not find hash from \(optionsUrl)")
        }
        
        let optionsJson = try await getJsonRequest(url: optionsUrl)
        print("options json \(optionsJson)")
        
        return (optionsJson, versionsHash)
    }
    
    func getMediaHTML(link: JSON?, params: [JSON] = []) throws -> String {
        //FIXME: Use configuration
        let baseUrl = self.network == "demo" ? "https://demov3.net955210.contentfabric.io/s/demov3" :
            "https://main.net955305.contentfabric.io/s/main"
        return try getUrlFromLink(link:link, baseUrl: baseUrl, params: params, includeAuth: true)
    }
    
    func getVersionHashFromLink(link: JSON?) -> String  {
        return link?["."]["container"].stringValue ?? ""
    }
    
    func getUrlFromLink(link: JSON?, baseUrl: String? = nil, params: [JSON]? = [], includeAuth: Bool? = true, resolveHeaders: Bool? = false, staticUrl: Bool = false, hash:String = "") throws -> String {
        guard let link = link else{
            throw FabricError.badInput("getUrlFromLink: Link is nil")
        }
        
        if link.isEmpty {
            throw FabricError.badInput("getUrlFromLink: Link is nil")
        }
        
        var path = link["/"].stringValue
        var hash = hash
        
        if hash.isEmpty {
            hash = link["."]["container"].stringValue
        }
        
        if (path.hasPrefix("/qfab")){
            hash = ""
            path = path.replaceFirst(of: "/qfab", with: "")
        }
        
        path = NSString.path(withComponents: ["/","q",hash,path])

        if staticUrl {
            path = "/s/main\(path)"
        }
        
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
            var auth = self.fabricToken
            if auth.isEmpty {
                auth = createStaticToken()
            }
            queryItems.append(URLQueryItem(name: "authorization", value: auth))
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
        //let libraryId = try self.getNetworkConfig().main_obj_lib_id
        let metadataSubtree = "public/asset_metadata/tenants"
        return try await self.contentObjectMetadata(id:objectId, metadataSubtree:metadataSubtree)
    }
    
    func createStaticToken() -> String {
        do {
            let qspaceId = try getContentSpaceId()
            let dict : [String: Any] = [ "qspace_id": qspaceId ]
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
    
    func resolvePermission(propertyId:String,
                           _pageId:String,
                           sectionId:String,
                           sectionItemId:String,
                           mediaCollectionId:String,
                           mediaListId:String,
                           mediaItemId:String
    ) async throws -> ResolvedPermission {

        var result = ResolvedPermission()
        
        let mediaProperty = try await getProperty(property: propertyId)
        if let _behavior = mediaProperty?.permissions?["behavior"] {
            do{
                result.behavior = try getBehavior(json:_behavior)
                if let altPageId = mediaProperty?.permissions?["alternate_page_id"] {
                    if result.behavior == .showAlternativePage && !altPageId.stringValue.isEmpty{
                        result.alternatePageId = altPageId.stringValue
                    }
                }
                
                if let secondaryPurchaseOption = mediaProperty?.permissions?["secondary_market_purchase_option"] {
                    if result.behavior == .showPurchase && secondaryPurchaseOption.boolValue{
                        result.secondaryPurchaseOption = true
                    }
                }
            }catch{}
        }
        
        var pageId = _pageId
        if pageId.isEmpty {
            pageId = "main"
        }
        
        if let page = try await getPropertyPage(property: propertyId, page:pageId) {
            if let _behavior = page.permissions?["behavior"] {
                do{
                    result.behavior = try getBehavior(json:_behavior)
                    if let secondaryPurchaseOption = page.permissions?["secondary_market_purchase_option"] {
                        if result.behavior == .showPurchase && secondaryPurchaseOption.boolValue {
                            result.secondaryPurchaseOption = true
                        }
                    }
                }catch{}
            }
        }
        
        if !sectionId.isEmpty {
            var response : [MediaPropertySection] = []
            do {
                response = try await getPropertySections(property: propertyId, sections: [sectionId])
            }catch{
                print("Could not get property sections response, ",error.localizedDescription)
            }
            
            if !response.isEmpty {
                let section = response[0]
                if let _behavior = section.permissions?["behavior"] {
                    do{
                        result.behavior = try getBehavior(json:_behavior)
                        if let altPageId = section.permissions?["alternate_page_id"] {
                            if result.behavior == .showAlternativePage && !altPageId.stringValue.isEmpty{
                                result.alternatePageId = altPageId.stringValue
                            }
                        }
                        
                        if let secondaryPurchaseOption = section.permissions?["secondary_market_purchase_option"] {
                            if result.behavior == .showPurchase && secondaryPurchaseOption.boolValue{
                                result.secondaryPurchaseOption = true
                            }
                        }
                        
                    }catch{}
                    
                    if let authorized = section.authorized {
                        result.authorized = authorized
                    }
                    if !result.authorized {
                        result.cause = "Section permissions"
                    }
                    
                    if let permissionItemsArr = section.permissions?["permission_item_ids"] {
                        result.permissionItemIds = []
                        for item in permissionItemsArr.arrayValue {
                            result.permissionItemIds.append(item.stringValue)
                        }
                    }
                    
                    if result.authorized && !sectionItemId.isEmpty {
                        if let sectionItem = section.content?.first(where: {$0.id == sectionItemId}) {
                            if let _behavior = sectionItem.permissions?["behavior"] {
                                do{
                                    result.behavior = try getBehavior(json:_behavior)
                                    
                                    if let altPageId = sectionItem.permissions?["alternate_page_id"] {
                                        if result.behavior == .showAlternativePage && !altPageId.stringValue.isEmpty{
                                            result.alternatePageId = altPageId.stringValue
                                        }
                                    }
                                    
                                    if let secondaryPurchaseOption = sectionItem.permissions?["secondary_market_purchase_option"] {
                                        if result.behavior == .showPurchase && secondaryPurchaseOption.boolValue{
                                            result.secondaryPurchaseOption = true
                                        }
                                    }
                                    
                                }catch{}
                            }
                            
                            if let authorized = sectionItem.authorized {
                                result.authorized = authorized
                            }
                            if !result.authorized {
                                result.cause = "Section item permissions"
                            }
                            
                            if let permissionItemsArr = sectionItem.permissions?["permission_item_ids"] {
                                result.permissionItemIds = []
                                for item in permissionItemsArr.arrayValue {
                                    result.permissionItemIds.append(item.stringValue)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return result
        
    }
    
    func getBehavior(json:JSON) throws -> PermisionBehavior {
        switch(json.stringValue.lowercased()){
        case "hide":
            return .Hide
        case "disable":
            return .Disable
        case "show_alternate_page":
            return .showAlternativePage
        case "show_if_unauthorized":
            return .showIfUnauthorized
        case "show_purchase":
            return .showPurchase
        default:
            throw FabricError.unexpectedResponse("no behavior defined.")
        }
    }
}

struct ResolvedPermission {
    var authorized:Bool = true
    var behavior:PermisionBehavior = .Hide
    var hide:Bool = false
    var disable:Bool = false
    var purchaseGate: Bool = false
    var secondaryPurchaseOption: Bool = false
    var showAlternatePage:Bool = true
    var alternatePageId:String = ""
    var permissionItemIds:[String] = []
    var cause: String = ""
}

enum PermisionBehavior {
    case Hide, Disable, showPurchase, showIfUnauthorized, showAlternativePage
}

/*
 HIDE: "hide",
 DISABLE: "disable",
 SHOW_PURCHASE: "show_purchase",
 SHOW_IF_UNAUTHORIZED: "show_if_unauthorized",
 SHOW_ALTERNATE_PAGE: "show_alternate_page"
 */

/*
ResolvePermission({
  mediaPropertySlugOrId,
  pageSlugOrId,
  sectionSlugOrId,
  sectionItemId,
  mediaCollectionSlugOrId,
  mediaListSlugOrId,
  mediaItemSlugOrId
}) {
  // Resolve permissions from top down
  let authorized = true;
  let behavior = this.PERMISSION_BEHAVIORS.HIDE;
  let cause;
  let permissionItemIds;

  const mediaProperty = this.MediaProperty({mediaPropertySlugOrId});
  behavior = mediaProperty?.metadata?.permissions?.behavior || behavior;

  let alternatePageId = (
    behavior === this.PERMISSION_BEHAVIORS.SHOW_ALTERNATE_PAGE &&
    mediaProperty?.metadata?.permissions?.alternate_page_id
  );

  let secondaryPurchaseOption = (
    behavior === this.PERMISSION_BEHAVIORS.SHOW_PURCHASE &&
    mediaProperty?.metadata?.permissions?.secondary_market_purchase_option
  );

  const page = this.MediaPropertyPage({mediaPropertySlugOrId, pageSlugOrId: pageSlugOrId || "main"});
  behavior = page.permissions?.behavior || behavior;

  alternatePageId = (
    page?.permissions?.behavior === this.PERMISSION_BEHAVIORS.SHOW_ALTERNATE_PAGE &&
    page?.permissions?.alternate_page_id
  ) || alternatePageId;

  secondaryPurchaseOption = (
    page?.permissions?.behavior === this.PERMISSION_BEHAVIORS.SHOW_PURCHASE &&
    page?.permissions?.permissions?.secondary_market_purchase_option
  ) || secondaryPurchaseOption;

  if(sectionSlugOrId) {
    const section = this.MediaPropertySection({mediaPropertySlugOrId, sectionSlugOrId});

    if(section) {
      behavior = section.permissions?.behavior || behavior;
      authorized = section.authorized;
      cause = !authorized && "Section permissions";
      permissionItemIds = section.permissions?.permission_item_ids || [];
      alternatePageId =
        (
          section.permissions?.behavior === this.PERMISSION_BEHAVIORS.SHOW_ALTERNATE_PAGE &&
          section.permissions?.alternate_page_id
        ) || alternatePageId;

      secondaryPurchaseOption =
        (
          section.permissions?.behavior === this.PERMISSION_BEHAVIORS.SHOW_PURCHASE &&
          section.permissions?.secondary_market_purchase_option
        ) || secondaryPurchaseOption;

      if(authorized && sectionItemId) {
        const sectionItem = this.MediaPropertySection({mediaPropertySlugOrId, sectionSlugOrId})?.content
          ?.find(sectionItem => sectionItem.id === sectionItemId);

        if(sectionItem) {
          behavior = sectionItem.permissions?.behavior || behavior;
          permissionItemIds = sectionItem.permissions?.permission_item_ids || [];
          authorized = sectionItem.authorized;
          cause = cause || !authorized && "Section item permissions";
          alternatePageId =
            (
              sectionItem.permissions?.behavior === this.PERMISSION_BEHAVIORS.SHOW_ALTERNATE_PAGE &&
              sectionItem.permissions?.alternate_page_id
            ) || alternatePageId;

          secondaryPurchaseOption =
            (
              sectionItem.permissions?.behavior === this.PERMISSION_BEHAVIORS.SHOW_PURCHASE &&
              sectionItem.permissions?.secondary_market_purchase_option
            ) || secondaryPurchaseOption;
        }
      }
    }
  }

  if(authorized && mediaCollectionSlugOrId) {
    const mediaCollection = this.MediaPropertyMediaItem({mediaPropertySlugOrId, mediaItemSlugOrId: mediaCollectionSlugOrId});
    authorized = mediaCollection?.authorized || false;
    permissionItemIds = mediaCollection.permissions?.map(permission => permission.permission_item_id) || [];
    cause = !authorized && "Media collection permissions";
  }

  if(authorized && mediaListSlugOrId) {
    const mediaList = this.MediaPropertyMediaItem({mediaPropertySlugOrId, mediaItemSlugOrId: mediaListSlugOrId});
    authorized = mediaList?.authorized || false;
    permissionItemIds = mediaList.permissions?.map(permission => permission.permission_item_id) || [];
    cause = !authorized && "Media list permissions";
  }

  if(authorized && mediaItemSlugOrId) {
    const mediaItem = this.MediaPropertyMediaItem({mediaPropertySlugOrId, mediaItemSlugOrId});
    authorized = mediaItem?.authorized || false;
    permissionItemIds = mediaItem.permissions?.map(permission => permission.permission_item_id) || [];
    cause = !authorized && "Media permissions";
  }

  if(behavior === this.PERMISSION_BEHAVIORS.SHOW_IF_UNAUTHORIZED) {
    authorized = !authorized;
    behavior = this.PERMISSION_BEHAVIORS.HIDE;
  }

  permissionItemIds = permissionItemIds || [];

  const purchaseGate = !authorized && behavior === this.PERMISSION_BEHAVIORS.SHOW_PURCHASE;
  const showAlternatePage = !authorized && behavior === this.PERMISSION_BEHAVIORS.SHOW_ALTERNATE_PAGE;

  if(showAlternatePage) {
    alternatePageId = this.MediaPropertyPage({mediaPropertySlugOrId, pageSlugOrId: alternatePageId ? alternatePageId : undefined})?.slug || alternatePageId;
  }

  return {
    authorized,
    behavior,
    // Hide by default, or if behavior is hide, or if no purchasable permissions are available
    hide: !authorized && (!behavior || behavior === this.PERMISSION_BEHAVIORS.HIDE || (purchaseGate && permissionItemIds.length === 0)),
    disable: !authorized && behavior === this.PERMISSION_BEHAVIORS.DISABLE,
    purchaseGate: purchaseGate && permissionItemIds.length > 0,
    secondaryPurchaseOption,
    showAlternatePage,
    alternatePageId,
    permissionItemIds,
    cause: cause || ""
  };
}
*/
