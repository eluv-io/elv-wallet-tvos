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
    
    @Published
    var playable : [NFTModel] = []
    var nonPlayable : [NFTModel] = []
    
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
        
        guard let configUrl = APP_CONFIG.networks[_network] else {
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
    
    @MainActor
    func setLogin(login:  LoginResponse){
        self.login = login
        self.isLoggedOut = false
        self.signingIn = false
        Task {
            do{
                self.fabricToken = try await self.signer!.createFabricToken( address: self.getAccountAddress(), contentSpaceId: self.getContentSpaceId(), authToken: self.login!.token)
                print("Fabric Token: \(self.fabricToken)");
                
                print("Account address: \(try getAccountAddress())")
                let profileData = try await self.signer!.getWalletData(accountAddress: try getAccountAddress(),
                                                                       accessCode: login.token)
                print("Profile DATA: \(profileData)")
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
                                print("Error decoding additional_media_sections for \(nftmodel.contract_name) \(error)")
                            }
                            
                            var hasPlayableMedia = false

                            if nftData["additional_media_sections"].exists() {
                                let mediaSections = nftData["additional_media_sections"]
                                
                                //Parsing featured_media to find videos
                                for media in mediaSections["featured_media"].arrayValue{
                                    if media["media_type"].stringValue == "Video" {
                                        hasPlayableMedia = true
                                        break
                                    }
                                }
                                
                                //Parsing sections to find videos
                                if (!hasPlayableMedia) {
                                    let sections = mediaSections["sections"]
                                    for section in sections.arrayValue {
                                        for collection in section["collections"].arrayValue {
                                            for media in collection["media"].arrayValue {
                                                if media["media_type"].stringValue == "Video" {
                                                    hasPlayableMedia = true
                                                    break
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
                    self.playable = playable
                    self.nonPlayable = nonPlayable
                    
                    //print("Non Playable ", self.nonPlayable)
                    //print("Playable ", self.playable)
                    
                }
            }catch{
                print ("Error: \(error)")
            }
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
                        print("Request error: \(error.localizedDescription)")
                    }
                }
        }
        self.login = nil
        self.isLoggedOut = true
        self.signInResponse = nil
        self.signer = nil
        self.fabricToken = ""
        self.playable = []
        self.nonPlayable = []
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
    
    //Given a token uri with suffix /meta/public/nft, we retrieve the full one
    // with /meta/public/asset_metadata/nft
    func getNFTData(tokenUri: String ) async throws -> JSON {
            return try await withCheckedThrowingContinuation({ continuation in
                do {
                    if !tokenUri.contains("/meta/public/nft") {
                        continuation.resume(throwing: FabricError.invalidURL("getNFTData: tokenUri does not contain /meta/public/nft. tokenUri: \(tokenUri)"))
                        return
                    }
                    
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
                            let value = JSON(response.value!)
                            continuation.resume(returning: value)
                         case .failure(let error):
                            print("Request error: \(error.localizedDescription)")
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
                        print("Request error: \(error.localizedDescription)")
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
                        print("Request error: \(error.localizedDescription)")
                        completion(nil, response.error?.localizedDescription)
                 }

                return
        }
    }
    
    //Given a token uri with suffix /meta/public/nft, we retrieve the full one
    // with /meta/public/asset_metadata/nft
    func getOptionsFromLink(resolvedLink: JSON?) throws -> String {
        guard let link = resolvedLink else{
            throw FabricError.badInput("getOptionsFromLink: resolvedLink is nil")
        }
        

        var path = link["sources"]["default"]["/"].stringValue
        var hash = link["sources"]["default"]["."]["container"].stringValue
                
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
    
    
    func getUrlFromLink(link: JSON?, params: [JSON] = []) throws -> String {
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
        
        guard let url = URL(string:try self.getEndpoint()) else {
            throw FabricError.badInput("getUrlFromLink: Could not get parse endpoint. Link: \(link)")
        }
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.path = path
        components.queryItems = [
            URLQueryItem(name: "link_depth", value: "5"),
            URLQueryItem(name: "resolve", value: "true"),
            URLQueryItem(name: "resolve_include_source", value: "true"),
            URLQueryItem(name: "resolve_ignore_errors", value: "true"),
            URLQueryItem(name: "authorization", value: self.fabricToken)
        ]
        
        for param in params {
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
    
    func getJsonRequest(url: String, accessToken: String? = nil ) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            
            var token = accessToken ?? self.fabricToken
            
            var headers: HTTPHeaders = [
                     "Accept": "application/json",
                     "Content-Type": "application/json" ]
            
            if !token.isEmpty {
                headers["Authorization"] =  "Bearer \(token)"
            }
            
            print("GET ",url)
            print("HEADERS ", headers)
            
            AF.request(url, headers:headers)
                .responseJSON { response in
                switch (response.result) {
                    case .success( _):
                        let value = JSON(response.value!)
                        continuation.resume(returning: value)
                     case .failure(let error):
                        print("Request error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                 }
            }
        })
    }
    
    func getHlsPlaylistFromOptions(optionsJson: JSON?, hash: String) throws -> String {
        guard let link = optionsJson else{
            throw FabricError.badInput("getHlsPlaylistFromOptions: optionsJson is nil")
        }
        

        if (hash.isEmpty) {
            throw FabricError.badInput("getHlsPlaylistFromOptions: hash is empty")
        }
        

        var uri = link["hls-fairplay"]["uri"].stringValue
        
        guard let url = URL(string:try self.getEndpoint()) else {
            throw FabricError.badInput("getHlsPlaylistFromOptions: Could not get parse endpoint. Link: \(link)")
        }
        
        var newUrl = "\(url.absoluteString)/q/\(hash)/rep/playout/default/\(uri)"
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
                        print("Request error: \(error.localizedDescription)")
                        completion(false)
                 }
        }
    }
}


