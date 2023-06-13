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

var APP_CONFIG : AppConfiguration = loadJsonFile("configuration.json")
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
    
    
    //Move these models to the app level
    @Published
    var library: [MediaCollection] = []
    @Published
    var albums: [NFTModel] = []
    @Published
    var featured = Features()//These can be NFTModel, MediaCollection, MediaItem
    @Published
    var properties: [PropertyModel] = []
    
    @Published
    var tenantItems: [JSON] = []  //Array of {"tenant":tenant, "nfts": nfts} objects of the user's items per tenant
    @Published
    var items: [NFTModel] = []
    @Published
    var drops : [ProjectModel] = []

    @Published
    var videos: [MediaItem] = []
    @Published
    var galleries: [MediaItem] = []
    @Published
    var images: [MediaItem] = []

    @Published
    var html: [MediaItem] = []
    @Published
    var books: [MediaItem] = []
    
    
    
    //Deprecated
    @Published
    var playable : [NFTModel] = []
    //Deprecated
    @Published
    var nonPlayable : [NFTModel] = []
    @Published
    var tenants : [JSON] = []
    @Published
    var currentTenantIndex = 0
    @Published
    var currentPropertyIndex = 0
    
    @Published
    var isRefreshing = false
    
    
    var currentProperty: JSON {
        if (self.tenants[currentTenantIndex]["properties"].arrayValue.count == 0){
            return JSON()
        }
        
        return self.tenants[currentTenantIndex]["properties"].arrayValue[currentPropertyIndex]
    }
    

    @Published
    var fabricToken: String = ""
    
    var signer : RemoteSigner? = nil
    var currentEnpointIndex = 0
    
    init(){
        print("Fabric init config_url \(self.configUrl)");
    }
    
    func getEndpoint() throws -> String{
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
    func connect(network: String) async throws {
        self.signingIn = true
        
        var _network = network
        if(network.isEmpty) {
            guard let savedNetwork = UserDefaults.standard.object(forKey: "fabric_network")
                    as? String else {
                self.signingIn = false
                self.isLoggedOut = true
                return
            }
            _network = savedNetwork
        }
        
        guard let configUrl = APP_CONFIG.network[_network]?.config_url else {
            throw FabricError.configError("Error, configuration network not found \(network)")
        }
        
        guard let url = URL(string: configUrl) else {
            self.signingIn = false
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
            self.signingIn = false
            throw FabricError.configError("Error getting ethereum apis from config: \(self.configuration)")
        }
        
        guard let asApi = self.configuration?.getAuthServices() else{
            self.signingIn = false
            throw FabricError.configError("Error getting authority apis from config: \(self.configuration)")
        }
        self.signer = RemoteSigner(ethApi: ethereumApi, authorityApi:asApi)
        
        self.configUrl = configUrl
        self.network = _network
        UserDefaults.standard.set(_network, forKey: "fabric_network")
        
        self.checkToken { success in
            print("Check Token: ", success)
            guard success == true else {
                self.signingIn = false
                self.isLoggedOut = true
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

            var credentials : [String: AnyObject] = [:]

            credentials["token_type"] = tokenType
            credentials["access_token"] = accessToken
            credentials["id_token"] = idToken

            self.signIn(credentials: credentials)
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
    
    //Demo only getting specific nfts
    /*
    @MainActor
    func refresh() async {
        if self.login == nil {
            return
        }
        do{
            self.fabricToken = try await self.signer!.createFabricToken( address: self.getAccountAddress(), contentSpaceId: self.getContentSpaceId(), authToken: self.login!.token)
            print("Fabric Token: \(self.fabricToken)");
            
            print("Account address: \(try getAccountAddress())")
            let profileData = try await self.signer!.getWalletData(accountAddress: try self.getAccountAddress(),
                                                                   accessCode: self.login!.token)
            //print("Profile DATA: \(profileData)")
            var playable : [NFTModel] = []
            var nonPlayable: [NFTModel] = []
            if let nfts = profileData["contents"] as? [AnyObject] {
                for nft in nfts {
                    do {
                        //print(nft)
                        let data = try JSONSerialization.data(withJSONObject: nft, options: .prettyPrinted)
                        //print(data)
                        var nftmodel = try JSONDecoder().decode(NFTModel.self, from: data)
                        if (nftmodel.id == nil){
                            nftmodel.id = UUID().uuidString
                        }
                        
                        let nftData = try await self.getNFTData(tokenUri: nftmodel.token_uri)
                        nftmodel.meta_full = nftData
                        
                        do {
                            nftmodel.additional_media_sections = try JSONDecoder().decode(AdditionalMediaModel.self, from: nftData["additional_media_sections"].rawData())
                        }catch{
                            print("Error decoding additional_media_sections for \(nftmodel.contract_name ?? ""): \(error)")
                            //print("\(try nftData.rawData().prettyPrintedJSONString ?? "")")
                            
                            do {
                                //Try to find the old style
                                if nftData["additional_media"].exists() {
                                    nftmodel.additional_media_sections = AdditionalMediaModel()
                                    nftmodel.additional_media_sections?.featured_media = try JSONDecoder().decode([MediaItem].self, from: nftData["additional_media"].rawData())
                                }
                            }catch{
                                print("Error decoding additional_media for \(nftmodel.contract_name ?? ""): \(error)")
                            }
                        }
                        
                        var hasPlayableMedia = false

                        if nftmodel.additional_media_sections != nil {
                            if let mediaSections = nftmodel.additional_media_sections {
                                //Parsing featured_media to find videos
                                for media in mediaSections.featured_media{
                                    if let mediaType = media.media_type {
                                        if mediaType == "Video" || mediaType == "Audio"{
                                            hasPlayableMedia = true
                                            break
                                        }
                                    }
                                }
                                
                                //Parsing sections to find videos
                                if (!hasPlayableMedia) {
                                    for section in mediaSections.sections {
                                        for collection in section.collections{
                                            for media in collection.media{
                                                if let mediaType = media.media_type {
                                                    if mediaType == "Video" || mediaType == "Audio"{
                                                        hasPlayableMedia = true
                                                        break
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        

                        nftmodel.has_playable_feature = hasPlayableMedia
                        if (hasPlayableMedia) {
                            playable.append(nftmodel)
                        }else{
                            nonPlayable.append(nftmodel)
                        }
                    } catch {
                        print(error.localizedDescription)
                        continue
                    }
                }
                
                //XXX: Only for demo
                var playable2: [NFTModel] = []
                for item in playable {
                    if item.meta.displayName.contains("Lord of") {
                        playable2.append(item)
                    }
                }
            
                
                var property = CreateTestProperty(num: 0)
                
                property["contents"][0]["contents"] = JSON(try JSONEncoder().encode(playable2))
                
                var tenants = self.tenants
                tenants[0]["properties"] = [property]
                
                self.tenants = tenants
                //print("Current property \(currentProperty["contents"][0]["contents"][0].object)")
                
                //print("Non Playable ", self.nonPlayable)
                self.playable = playable2 //XXX
                self.nonPlayable = nonPlayable
                
                print("refreshed!")
            }
        }catch{
            print ("Error: \(error)")
        }
    }
    */
    
    func parseNfts(_ nfts: [JSON]) async throws -> (items: [NFTModel], featured:Features, albums:[NFTModel], videos: [MediaItem] , images:[MediaItem] , galleries: [MediaItem] , html: [MediaItem] , books: [MediaItem], liveStreams: [MediaItem] ) {
        
        var featured = Features()
        var videos: [MediaItem] = []
        var galleries: [MediaItem] = []
        var images: [MediaItem] = []
        var albums: [NFTModel] = []
        var html: [MediaItem] = []
        var books: [MediaItem] = []
        var liveStreams: [MediaItem] = []
        
        var items : [NFTModel] = []
        for nft in nfts {
            do {
                let parsedModels = try await self.parseNft(nft)
                guard var model = parsedModels.nftModel else {
                    print("Error parsing nft: \(nft)")
                    continue
                }
                
                if(model.has_album ?? false){
                    albums.append(model)
                }
                items.append(model)
                
                //print("Parsed nft: \(parsedModels.nftModel)")
                //print("Parsed Featured: \(parsedModels.featured)")
                //print("Parsed Galleries: \(parsedModels.galleries)")
                //print("Parsed Galleries: \(parsedModels.images)")
                //print("Parsed Albums: \(parsedModels.albums)")
                print("NFT: \(model.contract_name)")
                //print("Parsed HTML: \(parsedModels.html)")
                //print("Parsed Books: \(parsedModels.books)")
                
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
    
    func parseNft(_ nft: JSON) async throws -> (nftModel: NFTModel?, featured:Features, videos: [MediaItem] , images:[MediaItem] , galleries: [MediaItem] , html: [MediaItem] , books: [MediaItem], liveStreams: [MediaItem] ) {
        
        print("Parse NFT")
        
        var featured = Features()
        var videos: [MediaItem] = []
        var galleries: [MediaItem] = []
        var images: [MediaItem] = []
        var html: [MediaItem] = []
        var books: [MediaItem] = []
        var liveStreams: [MediaItem] = []
        
        //print(nft)
        //let data = try JSONSerialization.data(withJSONObject: nft, options: .prettyPrinted)
        let data = try nft.rawData()
        
        print("DATA ",nft)
        print("before decoding ")
        var nftmodel = try JSONDecoder().decode(NFTModel.self, from: data)
        print("after decoding ", nftmodel)
        if (nftmodel.id == nil){
            nftmodel.id = nftmodel.contract_addr
        }
        
        if (nftmodel.contract_name ?? "").contains("Run") {
            nftmodel.background_image_tv = "Dolly_NFT-Detail-View-BG_4K"
        }
        
        //print("Getting NFT DATA")
        guard let tokenUri = nftmodel.token_uri else {
            throw FabricError.invalidURL("token_uri does not exist for \(nftmodel.contract_addr)")
        }
        
        let nftData = try await self.getNFTData(tokenUri: tokenUri)
        nftmodel.meta_full = nftData
        //print("NFT DATA ", nftData)
        
        if nftData["additional_media_sections"].exists() {
            print("additional_media_sections exists for \(nftData["display_name"].stringValue)")
            do {
                nftmodel.additional_media_sections = try JSONDecoder().decode(AdditionalMediaModel.self, from: nftData["additional_media_sections"].rawData())
                
                //print("DECODED: \(nftmodel.additional_media_sections)")
                //print("FOR JSON: \(try nftData["additional_media_sections"].rawData().prettyPrintedJSONString ?? "")")
            }catch{
                print("Error decoding additional_media_sections for \(nftmodel.contract_name ?? ""): \(error)")
                //print("\(try nftData["additional_media_sections"].rawData().prettyPrintedJSONString ?? "")")
            }
        }else{
            print("additional_media_sections does not exists for \(nftData["display_name"].stringValue)")
            
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
        print("additional_media_display ", nftmodel.meta_full?["additional_media_display"].stringValue)
        
        
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
                    print("Media ", media)
                    if let mediaType = media.media_type {
                        if mediaType == "Video"{
                            hasPlayableMedia = true
                        }
                        if mediaType == "Audio"{
                            hasPlayableMedia = true
                        }
                        
                        //XXX: Demo only until we have a proper Live mediaType
                        if media.name.contains("Live"){
                        //if mediaType == "Live" {
                            media.isLive = true
                            liveStreams.append(media)
                            nftmodel.additional_media_sections?.featured_media[index] = media
                        }
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
                for section in mediaSections.sections {
                    for collection in section.collections{
                        for var media in collection.media{
                            if let mediaType = media.media_type {
                                //XXX: Demo only until we have a proper Live mediaType
                                if media.name.contains("Live"){
                                    media.isLive = true
                                    hasPlayableMedia = true
                                //if mediaType == "Live" {
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
                            }
                        }
                    }
                }
            }
        }
        nftmodel.has_playable_feature = hasPlayableMedia
        
        return (nftmodel, featured, videos, images, galleries, html, books, liveStreams)
    }
    
    //Move this to the app level
    @MainActor
    func refresh() async {
        if self.login == nil {
            return
        }
        
        if self.isRefreshing {
            return
        }
        self.isRefreshing = true
        defer{
            isRefreshing = false
        }
        
        do{
            /*var featured: [AnyHashable] = []
            var videos: [MediaItem] = []
            var galleries: [MediaItem] = []
            var images: [MediaItem] = []
            var albums: [NFTModel] = []
            var html: [MediaItem] = []
            var books: [MediaItem] = []*/
            var properties: [PropertyModel] = []
            
            self.fabricToken = try await self.signer!.createFabricToken( address: self.getAccountAddress(), contentSpaceId: self.getContentSpaceId(), authToken: self.login!.token)
            print("Fabric Token: \(self.fabricToken)");
            
            let profileData = try await self.signer!.getWalletData(accountAddress: try self.getAccountAddress(),
                                                                   accessCode: self.login!.token)

            let nfts = profileData["contents"].arrayValue

            var parsedLibrary = try await parseNfts(nfts)
            
            
            var featured = parsedLibrary.featured
            
            if (!featured.isEmpty){
                let feature = featured.media.remove(at: 0)
                featured.append(feature)
            }
            parsedLibrary.featured = featured;
            
            
            self.featured = parsedLibrary.featured;
            
            
            print("featured count ", self.featured.count)
            self.galleries = parsedLibrary.galleries;
            self.images = parsedLibrary.images;
            self.albums = parsedLibrary.albums;
            self.videos = parsedLibrary.videos;
            self.html = parsedLibrary.html;
            self.books = parsedLibrary.books;
            
            var library : [MediaCollection] = []
            library.append(MediaCollection(name:"Video", media:parsedLibrary.videos))
            library.append(MediaCollection(name:"Live Stream", media:parsedLibrary.liveStreams)) //TODO: Find what's a live video
            library.append(MediaCollection(name:"Image Gallery", media:parsedLibrary.galleries))
            library.append(MediaCollection(name:"Apps", media:parsedLibrary.html))
            library.append(MediaCollection(name:"E-books", media:parsedLibrary.books))
            self.library = library
            
            let eluvioProp = CreateTestPropertyModel(title:"Eluvio Media Wallet", logo: "e_logo", image:"e_logo", heroImage:"", featured: self.featured, media: library, albums: self.albums,   items:self.items)
            
            let wbProp = try await createWbDemoProp(nfts: nfts)
            
            let dollyProp = try await createDollyDemoProp(nfts: nfts)
            
            var moonProp = try await createMoonProp(nfts:nfts)
            
            let foxSportsProp = try await createFoxSportsDemoProp(nfts:nfts)
            
            var items : [NFTModel] = []
            var dropsDict : [String:ProjectModel] = [:]
            var drops : [ProjectModel] = []

            for var item in parsedLibrary.items {
                if let attribute = item.meta.attributesDict["Drop"] {
                    if let attributeValue = attribute.value {
                        if var proj = dropsDict[attributeValue] {
                            item.property = moonProp
                            proj.contents.append(item)
                            dropsDict[attributeValue] = proj
                        }else{
                            var image = ""
                            var imageWide = ""
                            var bgImage = ""
                            var description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
                            if attributeValue.contains("Hell"){
                                image = "Hell in a Cell 1_1"
                                imageWide = "Hell in a Cell Tile"
                                bgImage = "Hell in a Cell BG"
                                description = "Every Moonsault Case contains 3 NFT Flips that immortalize the most amazing slams, highlights, and Superstars from WWE events. The Hell in a Cell Case features the biggest moments from Hell in a Cell matches of our current era and from our rich history. Open a Hell in a Cell Case today!"
                            }else if attributeValue.contains("Money"){
                                image = "Money in the Bank 1_1"
                                imageWide = "Money in the Bank Tile"
                                bgImage = "Money in the Bank BG"
                                description = "Every Moonsault Case contains 3 NFT Flips that immortalize the most amazing slams, highlights, and Superstars from WWE events. The Money in the Bank Case features the biggest moments from Money in the Bank matches of our current era and from our rich history. Open a Money in the Bank Case today!"
                            }else if attributeValue.contains("Halloween"){
                                image = "Halloween 1_1-v2"
                                imageWide = "Halloween Tile-v2"
                                bgImage = "Halloween BG-v2"
                                description = "The time for fear is here. Brace yourself for Halloween Drop NFTs featuring the scariest highlights in #WWE history. Things are getting sinister with this limited-edition drop featuring the biggest WWE Superstars and their most terrifying moments. Chills will run up and down your spine as Superstars like Kane, The Boogeyman and Undertaker unleash their carnage before your very eyes."
                            }else if attributeValue.contains("Castle"){
                                image = "Clash at the Castle 1_1"
                                imageWide = "Clash at the Castle Tile"
                                bgImage = "Clash at the Castle BG"
                                description = "Every Moonsault Case contains 3 NFT Flips that immortalize the most amazing slams, highlights, and Superstars from WWE events. Unlock and enjoy this exclusive Clash at the Castle NFT Case, celebrating the first WWE premium live event in the UK in 30 years!"
                            }else if attributeValue.contains("Summer"){
                                image = "Summer Slam 1_1"
                                imageWide = "Summer Slam Tile"
                                bgImage = "Summer Slam BG"
                                description = "Every Moonsault Case contains 3 NFT Flips that immortalize the most amazing slams, highlights, and Superstars from WWE events. The SummerSlam Case features the biggest moments from SummerSlam matches of our current era and from our rich history. Open a SummerSlam Case today!"
                            }else if attributeValue.contains("Survivor"){
                                image = "Survivor 1_1"
                                imageWide = "Survivor Tile"
                                bgImage = "Survivor BG"
                                description = """
                                For the first time in WWE history, WWE Superstars will step into a monstrous steel cage encapsulating two rings where anything goes and they’ll battle for glory. As more Superstars enter the rings, the more action packed the perilous combat becomes.
                                
                                But, this war is anything but a game. This Survivor Series Drop will feature the WWE Universe’s favorite Superstars, and it’ll mean giving your all on the battlefield to snag the victor.

                                Fight for your fandom. Claim yours now on November 18th.
                                """
                            }

                            var newProj = ProjectModel(title:attributeValue,
                                                       description: description,
                                                       image:image,
                                                       image_wide:imageWide,
                                                       background_image_tv: bgImage)
                            item.property = moonProp
                            newProj.contents.append(item)
                            newProj.property = moonProp
                            dropsDict[attributeValue] = newProj
                            drops.append(newProj)
                        }
                    }
                }else {
                    
                    if let name = item.meta.displayName {
                        if name.contains("Ring"){
                            item.property = wbProp
                        }else if name.contains("Run"){
                            item.property = dollyProp
                        }else if name.contains("Fox"){
                            item.property = foxSportsProp
                        }else if name.contains("Eluvio"){
                            item.property = eluvioProp
                        }
                    }
                    
                    items.append(item)
                }
            }
            
            
            
            self.items = items
            
            let sorted = dropsDict.sorted { $0.key < $1.key }
            moonProp.contents = Array(sorted.map({ $0.value }))
            /*
            if (!moonProp.contents.isEmpty){
                print( moonProp.contents[0])
                
                do {
                    let jsonData = try JSONEncoder().encode(moonProp.contents[0])
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    print(jsonString) // [{"sentence":"Hello world","lang":"en"},{"sentence":"Hallo Welt","lang":"de"}]
                    
                } catch { print(error) }
                
            }*/
            
            properties = [
                foxSportsProp,
                wbProp,
                dollyProp,
                moonProp
            ]
            
            self.properties = properties
            self.drops = moonProp.contents
                
        }catch{
            print ("Refresh Error: \(error)")
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
    
    func createWbDemoProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.contains("Rings") {
                demoNfts.append(nft)
            }else if name.contains("Superman") {
                demoNfts.append(nft)
            }
        }
        
        var demoLib = try await parseNfts(demoNfts)
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
                }
            }
            newItems.append(item)
        }
        
        let prop = CreateTestPropertyModel(title:"Movieverse", logo: "WarnerBrothersLogo", image:"WBMovieverse", heroImage:"WarnerBrothers_TopImage",
                                    featured: demoLib.featured, media: demoMedia, liveStreams: demoLib.liveStreams, items:newItems)
        
        return prop
    }
    
    func createFoxSportsDemoProp(nfts:[JSON]) async throws -> PropertyModel {
        var demoNfts: [JSON] = []
        for nft in nfts{
            let name = nft["contract_name"].stringValue
            if name.contains("Live") || name.contains("Sports") || name.contains("Demo") {
                demoNfts.append(nft)
            }
        }
        
        var demoLib = try await parseNfts(demoNfts)
        var demoMedia : [MediaCollection] = []
        demoMedia.append(MediaCollection(name:"Video", media:demoLib.videos))
        demoMedia.append(MediaCollection(name:"Image Gallery", media:demoLib.galleries))
        demoMedia.append(MediaCollection(name:"Apps", media:demoLib.html))
        demoMedia.append(MediaCollection(name:"E-books", media:demoLib.books))
        
        print("videos count: ", demoLib.videos.count)
        print("live stream count: ", demoLib.liveStreams.count)
        
        var newItems : [NFTModel] = []
        
        for var item in demoLib.items{
            if let name = item.contract_name {
                if name.contains("Epic") {
                    item.title_image = "LOTR_Tile Group_Epic"
                }else  if name.contains("Shire") {
                    item.title_image = "LOTR_Tile Group_Shire"
                }
            }
            newItems.append(item)
        }
        
        
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
        
        var prop = CreateTestPropertyModel(title:"Fox Sports", logo: "FoxSportsLogo", image:"FoxSport", heroImage:"fox_sports_header",  featured: demoLib.featured, media: demoMedia, liveStreams: streams, items:newItems)
        
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
        
        var prop = CreateTestPropertyModel(title:"Dollyverse", logo: "DollyverseLogo", image:"Dollyverse", heroImage:"DollyVerse_TopImage", featured: demoLib.featured, media: demoMedia, albums: demoLib.albums, items:demoLib.items)
        
        return prop
    }
    
    //Move this to the app level
    /*
    @MainActor
    func refresh() async {
        if self.login == nil {
            return
        }
        do{
            var featured:[MediaItem] = []
            var videos: [MediaItem] = []
            var galleries: [MediaItem] = []
            var images: [MediaItem] = []
            var albums: [MediaItem] = []
            var html: [MediaItem] = []
            var books: [MediaItem] = []
            
            self.fabricToken = try await self.signer!.createFabricToken( address: self.getAccountAddress(), contentSpaceId: self.getContentSpaceId(), authToken: self.login!.token)
            print("Fabric Token: \(self.fabricToken)");
            
            let tenantItems = try await self.getWalletTenantItems()
            //print("Tenants: \(tenantItems)");
            
            //print("Account address: \(try getAccountAddress())")

            for tenantItem in tenantItems {
                //print ("TenantItem \(tenantItem)")
                let tenantTitle = tenantItem["tenant"]["title"].stringValue
                let marketTitle = tenantItem["marketplace"]["title"].stringValue
                let count = tenantItem["nfts"].arrayValue.count
                print("Tenant: \(tenantTitle) Marketplace: \(marketTitle) nfts \(count)");
                
                for nft in tenantItem["nfts"].arrayValue {
                    do {
                        let parsedModels = try await self.parseNft(nft)
                        //print("Parsed nft: \(parsedModels.nftModel)")
                        //print("Parsed Featured: \(parsedModels.featured)")
                        //print("Parsed Galleries: \(parsedModels.galleries)")
                        //print("Parsed Galleries: \(parsedModels.images)")
                        //print("Parsed Albums: \(parsedModels.albums)")
                        //print("Parsed Videos: \(parsedModels.videos)")
                        //print("Parsed HTML: \(parsedModels.html)")
                        //print("Parsed Books: \(parsedModels.books)")
                        
                        if(!parsedModels.featured.isEmpty){
                            featured.append(contentsOf: parsedModels.featured)
                        }
                        if(!parsedModels.galleries.isEmpty){
                            galleries.append(contentsOf: parsedModels.galleries)
                        }
                        if(!parsedModels.images.isEmpty){
                            books.append(contentsOf: parsedModels.images)
                        }
                        if(!parsedModels.albums.isEmpty){
                            albums.append(contentsOf: parsedModels.albums)
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
                        
                    } catch {
                        print(error.localizedDescription)
                        continue
                    }
                }
            }
            
            self.tenantItems = tenantItems;
            self.featured = featured;
            self.galleries = galleries;
            self.images = images;
            self.albums = albums;
            self.videos = videos;
            self.html = html;
            self.books = books;
            
        }catch{
            print ("Refresh Error: \(error)")
        }
    }
    */
    
    @MainActor
    func setLogin(login:  LoginResponse){
        self.login = login
        self.isLoggedOut = false
        self.signingIn = false
        Task {
            await self.refresh()
        }
    }
    
    func signOut(){
        print("Fabric: signOut()")
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
        self.login = nil
        self.isLoggedOut = true
        self.signInResponse = nil
        self.signer = nil
        self.fabricToken = ""
        self.tenantItems = []  //Array of {"tenant":tenant, "nfts": nfts} objects of the user's items per tenant
        self.featured = Features()
        self.videos = []
        self.galleries = []
        self.images  = []
        self.albums = []
        self.html = []
        self.books = []
        
        //self.playable = []
        //self.nonPlayable = []
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "id_token")
        UserDefaults.standard.removeObject(forKey: "token_type")
        UserDefaults.standard.removeObject(forKey: "fabric_network")
    }
    
    @MainActor
    func signIn(credentials: [String: AnyObject] ){
        print("Fabric: signIn()")
        guard let config = self.configuration else
        {
            self.signingIn = false
            print("Not configured.")
            return
        }
        
        print("Credentials: \(credentials)")

        
        print("Web Auth0 Success: idToken: \(credentials["id_token"])")
        print("Web Auth0 Success: accessToken: \(credentials["access_token"])")
        print("Web Auth0 Success: refreshToken: \(credentials["refresh_token"])")
        
        guard let accessToken: String = credentials["access_token"] as? String else {
            self.signingIn = false
            print("Could not retrieve accessToken")
            return
            
        }
        guard let idToken: String = credentials["id_token"] as? String else {
            self.signingIn = false
            print("Could not retrieve id_token")
            return
        }
        
        //We do not get the refresh token with device sign in for some reason
        let refreshToken: String = credentials["refresh_token"] as? String ?? ""

        var signInResponse = SignInResponse()
        signInResponse.idToken = idToken
        signInResponse.refreshToken = refreshToken
        signInResponse.accessToken = accessToken
        
        self.signInResponse = signInResponse
        
        let urlString = config.getAuthServices()[0] + "/wlt/login/jwt"
        guard let url = URL(string: urlString) else {
            //throw FabricError.invalidURL
            print("Invalid URL \(urlString)")
            self.signingIn = false
            return
        }
        

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
        let json: [String: Any] = ["ext": ["share_email":true]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        print("http request: ", request)
        print("http request headers: ", request.allHTTPHeaderFields)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            
                do{
                    guard let data = data else {
                        self.signingIn = false
                        throw FabricError.unexpectedResponse("Error response data: \(response)")
                    }
                    print("Fabric login response: \(response)")
                    print("Fabric login error: \(error)")
                    
                    let str = String(decoding: data, as: UTF8.self)
                    
                    print("Fabric login data: \(str)")

                    // Parse the JSON data
                    let login = try JSONDecoder().decode(LoginResponse.self, from: data)
                    Task {
                        await self.setLogin(login: login)
                    }
                }catch{
                    self.signingIn = false
                    print(error)
                }
        
        })
        task.resume()
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
        
        return address
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
                                    
        print("GET ",newUrl)

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
                    
                    print("GET ",newUrl)
                    print("HEADERS ", headers)
                    
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
    
    func getOptionsFromLink(resolvedLink: JSON?, offering:String="default") throws -> String {
        guard let link = resolvedLink else{
            throw FabricError.badInput("getOptionsFromLink: resolvedLink is nil")
        }
        

        var path = link["sources"][offering]["/"].stringValue
        var hash = link["sources"][offering]["."]["container"].stringValue
                
        path = NSString.path(withComponents: ["/","q",hash,path])
        
        guard let url = URL(string:try self.getEndpoint()) else {
            throw FabricError.badInput("getOptionsFromLink: Could not get parse endpoint. Link: \(resolvedLink)")
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
            throw FabricError.badInput("getOptionsFromLink: Could not create url. Link: \(resolvedLink)")
        }
        
        return newUrl.standardized.absoluteString
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
    
    func getJsonRequest(url: String, accessToken: String? = nil, parameters : [String: String] = [:]) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            
            var token = accessToken ?? self.fabricToken
            
            var headers: HTTPHeaders = [
                     "Accept": "application/json"]
            
            if !token.isEmpty {
                headers["Authorization"] =  "Bearer \(token)"
            }
            
            print("GET ",url)
            print("HEADERS ", headers)
            
            AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers:headers)
                .responseJSON { response in
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
    
    
    //Move this to ElvLive class
    func getTenants() async throws -> JSON {
        print ("getTenants")
        let objectId = try self.getNetworkConfig().main_obj_id
        let libraryId = try self.getNetworkConfig().main_obj_lib_id
        let metadataSubtree = "public/asset_metadata/tenants"
        return try await self.contentObjectMetadata(libraryId:libraryId, objectId:objectId, metadataSubtree:metadataSubtree)
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
                items = try await self.signer!.getWalletData(accountAddress: try getAccountAddress(),
                                                                 accessCode: self.login!.token, parameters:parameters)
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
    
    //ELV-CLIENT API
    
    //TODO: only need objectId
    //TODO: provide the other params from elv-client-js
    func contentObjectMetadata(libraryId: String, objectId: String, metadataSubtree: String? = "") async throws -> JSON {
        let url: String = try self.getEndpoint().appending("/qlibs/").appending("\(libraryId)").appending("/q/").appending("\(objectId)").appending("/meta/\(metadataSubtree!)").appending("?\(Fabric.CommonFabricParams)")
        
        return try await self.getJsonRequest(url: url)
    }
    
    //TODO: Use contract call to get lib ID from objectID
    func contentObjectLibraryId(_objectId: String?) async throws -> String {
        return ""
    }
}


