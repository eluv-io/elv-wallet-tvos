//
//  RemoteSigner.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-14.
//

import Foundation
import Alamofire
import SwiftKeccak
import RLPSwift
import SwiftyJSON
import Base58Swift
import CryptoKit

enum APIEnvironment : String {
    case prod = ""; case staging = "staging"
}
                            
struct JRPCParams: Codable {
    var jsonrpc = "2.0"
    var id = 1
    var method: String
    var params: [String]
}

class RemoteSigner {
    var ethApi : [String]
    var authorityApi: [String]
    var currentEthIndex = 0
    var currentAuthIndex = 0
    var network : String
    var environment : APIEnvironment = .prod

    init(ethApi: [String], authorityApi: [String], network: String){
        self.ethApi = ethApi
        self.authorityApi = authorityApi
        self.network = network
        
        if let env = UserDefaults.standard.object(forKey: "api_environment")
                as? String {
            if env == "staging"{
                self.environment = .staging
            }else{
                self.environment = .prod
            }
        }else{
            print("Could not get api_environment from user defaults")
            self.environment = .prod
        }
    
    }
    
    func setEnvironment(env:APIEnvironment){
        environment = env
    }
    
    func getEnvironment() -> APIEnvironment {
        return environment
    }
    
    
    //TODO: implement fail over
    func getEthEndpoint() throws -> String{
        if let node = APP_CONFIG.network[network]?.overrides?.eth_url {
            if node != "" {
                print ("Found dev elvmaster node: ", node)
                return node
            }
        }
        
        let endpoint = self.ethApi[self.currentEthIndex]
        if(endpoint.isEmpty){
            throw FabricError.configError("getEthEndpoint: could not get endpoint")
        }
        return endpoint
    }
    
    func getAuthEndpoint() throws -> String{
        if let node = APP_CONFIG.network[network]?.overrides?.as_url {
            if node != "" {
                print ("Found dev authd node: ", node)
                return node
            }
        }
        let endpoint = self.authorityApi[self.currentAuthIndex]
        if(endpoint.isEmpty){
            throw FabricError.configError("getEthEndpoint: could not get endpoint")
        }
        return endpoint
    }

    //TODO: Convert this to responseDecodable
    func getWalletData(accountAddress: String, propertyId:String, description:String="", name:String="", accessCode: String, parameters : [String: String] = [:]) async throws -> (result: JSON, hash: SHA256Digest) {
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                
                // get all the tenants
                /*if IsDemoMode() {
                    endpoint = endpoint.appending("/wlt/").appending(accountAddress).appending("?limit=100")
                } else {*/
                    //apigw should have only tenants returned that are configured
                    endpoint = endpoint.appending("/apigw").appending("/nfts").appending("?limit=100")
                //}
                
                if (environment != .prod){
                    endpoint = endpoint.appending("&env=\(environment)")
                }
                
                if !propertyId.isEmpty {
                    endpoint = endpoint.appending("&property_id=\(propertyId)")
                }
                
                if !description.isEmpty {
                    endpoint = endpoint.appending("&filter=meta/description:co:\(description)")
                }
                
                if !name.isEmpty {
                    endpoint = endpoint.appending("&name_like=\(name)")
                }
                                                                    
                print("getWalletData Request: \(endpoint)")
                //print("Params: \(parameters)")
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                //print("Headers: \(headers)")
                
                AF.request(endpoint, parameters: parameters, encoding: URLEncoding.default,headers: headers )
                    .debugLog()
                    .responseJSON { response in

                        
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    let hash = SHA256.hash(data: response.data ?? Data())
                                        continuation.resume(returning: (JSON(result), hash))
                                }
                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getMediaCatalogJSON(accessCode: String, mediaId: String, parameters : [String: String] = [:]) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/catalog/").appending(mediaId).appending("?limit=100")
                if (environment != .prod){
                    endpoint = endpoint.appending("&env=\(environment)")
                }
                
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]

                AF.request(endpoint, parameters: parameters, encoding: URLEncoding.default,headers: headers )
                    .debugLog()
                    .responseJSON{ response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: JSON(result))
                                }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getProperty(property:String = "", noCache:Bool = false, accessCode: String, parameters : [String: String] = [:]) async throws -> MediaProperty {

        //var result : MediaPropertiesResponse = try loadJsonFile("properties.json")
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties")
            
                if !property.isEmpty {
                    endpoint = endpoint.appending("/\(property)")
                }
                
                if noCache {
                    endpoint = endpoint.appending("?no_cache=true")
                }
                
                if (environment != .prod){
                    if endpoint.contains("?") {
                        endpoint = endpoint.appending("&env=\(environment)")
                    }else{
                        endpoint = endpoint.appending("?env=\(environment)")
                    }
                }
                          
                print("getProperties Request: \(endpoint)")
                //print("Params: \(parameters)")
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                //print("Headers: \(headers)")
                
                AF.request(endpoint, parameters: parameters, encoding: URLEncoding.default,headers: headers )
                    .debugLog()
                    .responseDecodable(of: MediaProperty.self) { response in
                    var respJSON = JSON()
                    do{
                        respJSON = try JSON(data: response.data ?? Data())
                    }catch{}
                        
                    switch (response.result) {
                        case .success(let result):
                            if respJSON["errors"].exists() {
                                continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                   response: respJSON, error:FabricError.unexpectedResponse("")))
                            }else {
                                continuation.resume(returning: result)
                            }
                         case .failure(let error):
                            print("Get property error: \(error)")

                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    
    func getProperties(includePublic:Bool = true, noCache:Bool = false, accessCode: String, parameters : [String: String] = [:]) async throws -> MediaPropertiesResponse {

        //var result : MediaPropertiesResponse = try loadJsonFile("properties.json")
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties")
                endpoint = endpoint.appending("?limit=100")
                if (environment != .prod){
                    endpoint = endpoint.appending("&env=\(environment)")
                }

                endpoint = endpoint.appending("&include_public=\(includePublic ? "true" : "false" )")
                
                if noCache {
                    endpoint = endpoint.appending("&no_cache=true")
                }
                
                print("getProperties Request: \(endpoint)")
                //print("Params: \(parameters)")
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                //print("Headers: \(headers)")
                
                AF.request(endpoint, parameters: parameters, encoding: URLEncoding.default,headers: headers )
                    .debugLog()
                    .responseDecodable(of: MediaPropertiesResponse.self) { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: result)
                                }

                         case .failure(let error):
                            //print("Get properties error: \(error)")
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getPropertySectionsJSON(property: String, sections : [String] = [], accessCode: String) async throws -> JSON{

        //var result : MediaPropertiesResponse = try loadJsonFile("properties.json")
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties/\(property)/sections")
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }
                                                                    
                print("getPropertySection Request: \(endpoint)")
                //print("Params: \(parameters)")
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                //print("Headers: \(headers)")
                
                guard let url =  URL(string:endpoint) else {
                    throw FabricError.invalidURL("getPropertySections - could not create url from \(endpoint)")
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.headers = headers
                request.httpBody = try JSONSerialization.data(withJSONObject: sections)
                
                AF.request(request)
                    .debugLog()
                    //.responseDecodable(of: MediaPropertySectionsResponse.self) { response in
                    .responseJSON() { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: respJSON)
                                }

                         case .failure(let error):
                            print("Get properties sections error: \(error)")
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                        
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func searchProperty(property: String, tags:[String], attributes: [String: Any], searchTerm: String, limit: Int = 30, accessCode: String) async throws -> [MediaPropertySection] {
        
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties/\(property)/search?limit=\(limit)")
                if (environment != .prod){
                    endpoint = endpoint.appending("&env=\(environment)")
                }
                                                                    
                print("getPropertySection Request: \(endpoint)")
                //print("Params: \(parameters)")
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                //print("Headers: \(headers)")
                
                let body = [
                    "tags": tags,
                    "attributes": attributes,
                    "search_term" : searchTerm
                ]
                
                guard let url =  URL(string:endpoint) else {
                    throw FabricError.invalidURL("getPropertySections - could not create url from \(endpoint)")
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.headers = headers
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                AF.request(request)
                    .debugLog()
                    .responseDecodable(of: MediaPropertySectionsResponse.self) { response in
                    //.responseJSON() { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                        case .success(let result):
                            if respJSON["errors"].exists() {
                                continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                   response: respJSON, error:FabricError.unexpectedResponse("")))
                            }else {
                                continuation.resume(returning: result.contents)
                            }

                        case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getPropertyFilters(property: String, primaryFilter: String = "", accessCode: String) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties/\(property)/filters")
                
                if !primaryFilter.isEmpty {
                    endpoint.append("/\(primaryFilter)")
                }
                
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }

                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]

                guard let url =  URL(string:endpoint) else {
                    throw FabricError.invalidURL("getPropertyFilters - could not create url from \(endpoint)")
                }
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.headers = headers
                
                AF.request(request)
                    .debugLog()
                    .responseJSON() { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: respJSON)
                                }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getPropertyPermissions(propertyId: String, accessCode: String) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties/\(propertyId)/permissions")
                
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }

                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]

                guard let url =  URL(string:endpoint) else {
                    throw FabricError.invalidURL("getPropertyFilters - could not create url from \(endpoint)")
                }
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.headers = headers
                
                AF.request(request)
                    .debugLog()
                    .responseJSON() { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: respJSON)
                                }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }

    func getPropertySections(property: String, noCache:Bool=false, sections : [String] = [], accessCode: String) async throws -> MediaPropertySectionsResponse{

        //var result : MediaPropertiesResponse = try loadJsonFile("properties.json")
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties/\(property)/sections?resolve_subsections=true")
                if (environment != .prod){
                    endpoint = endpoint.appending("&env=\(environment)")
                }
                
                if noCache {
                    endpoint = endpoint.appending("&no_cache=true")
                }
                                                                    
                print("getPropertySection Request: \(endpoint)")
                //print("Params: \(parameters)")
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                //print("Headers: \(headers)")
                
                guard let url =  URL(string:endpoint) else {
                    throw FabricError.invalidURL("getPropertySections - could not create url from \(endpoint)")
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.headers = headers
                request.httpBody = try JSONSerialization.data(withJSONObject: sections)
                
                AF.request(request)
                    .debugLog()
                    .responseDecodable(of: MediaPropertySectionsResponse.self) { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: result)
                                }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getPropertyPage(property: String, page: String, accessCode: String, parameters : [String: String] = [:]) async throws -> MediaPropertyPage{
        
        return try await withCheckedThrowingContinuation({ continuation in
            //print("****** getPropertyPageSections ******")
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties/\(property)/pages/\(page)")
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }
                                                                    
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]

                AF.request(endpoint, parameters: parameters, encoding: URLEncoding.default,headers: headers )
                    .debugLog()
                    .responseDecodable(of: MediaPropertyPage.self) { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: result)
                                }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getPropertyPageSections(property: String, page: String, noCache:Bool = false, accessCode: String, parameters : [String: String] = [:]) async throws -> MediaPropertySectionsResponse{

        //var result : MediaPropertiesResponse = try loadJsonFile("properties.json")
        return try await withCheckedThrowingContinuation({ continuation in
            //print("****** getPropertyPageSections ******")
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties/\(property)/pages/\(page)/sections?resolve_subsections=true")
                if (environment != .prod){
                    endpoint = endpoint.appending("&env=\(environment)")
                }
                
                if noCache {
                    endpoint = endpoint.appending("&no_cache=true")
                }
                                                              
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]

                AF.request(endpoint, parameters: parameters, encoding: URLEncoding.default,headers: headers )
                    .debugLog()
                    .responseDecodable(of: MediaPropertySectionsResponse.self) { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: result)
                                }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getMediaItems(property: String, noCache:Bool=false, mediaItems : [String] = [], accessCode: String) async throws -> MediaPropertyItemsResponse{

        return try await withCheckedThrowingContinuation({ continuation in
            do {
                
                var endpoint = try self.getAuthEndpoint()
                endpoint = endpoint.appending("/mw/properties/\(property)/media_items?")
                if (environment != .prod){
                    endpoint = endpoint.appending("&env=\(environment)")
                }
                
                if noCache {
                    endpoint = endpoint.appending("&no_cache=true")
                }
                                                                    
                print("getPropertySection Request: \(endpoint)")
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                
                guard let url =  URL(string:endpoint) else {
                    throw FabricError.invalidURL("getPropertySections - could not create url from \(endpoint)")
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.headers = headers
                request.httpBody = try JSONSerialization.data(withJSONObject: mediaItems)
                
                AF.request(request)
                    .debugLog()
                    .responseDecodable(of: MediaPropertyItemsResponse.self) { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: result)
                                }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    //TODO: Convert this to responseDecodable
    func createMetaMaskLogin() async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            print("****** createMetaMaskLogin ******")
            do {
                var endpoint = try self.getAuthEndpoint().appending("/wlt/login/redirect/metamask")
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }

                guard let walletUrl = APP_CONFIG.network[self.network]?.wallet_url else {
                    continuation.resume(throwing: FabricError.configError("Could not find wallet_url in configuration."))
                    return
                }

                let headers: HTTPHeaders = [
                     "Accept": "application/json",
                     "Content-Type": "application/json" ]

                let parameters : [String: Any] = ["op":"create", "dest": walletUrl]
                
                AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
                    .debugLog()
                    .responseJSON { response in

                    switch (response.result) {
                        case .success(let result):
                            continuation.resume(returning: JSON(result))
                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    //Pass in the response JSON of createMetaMaskLogin
    func checkMetaMaskLogin(createResponse: JSON) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            print("****** checkMetaMaskLogin ******")
            do {
                
                let id = createResponse["id"].stringValue
                let pass = createResponse["passcode"].stringValue
                
                if (id == ""){
                    continuation.resume(throwing: FabricError.badInput("checkMetaMaskLogin failed. ID is empty"))
                }
                
                if (pass == ""){
                    continuation.resume(throwing: FabricError.badInput("checkMetaMaskLogin failed. passcode is empty"))
                }
                
                var endpoint = try self.getAuthEndpoint().appending("/wlt/login/redirect/metamask/")
                    .appending(id).appending("/").appending(pass)
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }

                let headers: HTTPHeaders = [
                     "Accept": "application/json",
                     "Content-Type": "application/json" ]

                AF.request(endpoint, encoding: JSONEncoding.default, headers: headers )
                    .debugLog()
                    .responseJSON { response in

                    switch (response.result) {
                        case .success(let result):
                            continuation.resume(returning: JSON(result))
                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    //TODO: Convert this to responseDecodable
    func createAuthLogin(redirectUrl: String) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            print("****** createMetaMaskLogin ******")
            do {
                var endpoint = try self.getAuthEndpoint().appending("/wlt/login/redirect/metamask")
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }
                
                let headers: HTTPHeaders = [
                     "Accept": "application/json",
                     "Content-Type": "application/json" ]

                let parameters : [String: Any] = ["op":"create", "dest": redirectUrl]
                
                AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
                    .responseJSON { response in

                    switch (response.result) {
                        case .success(let result):
                            continuation.resume(returning: JSON(result))
                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    //Pass in the response JSON of createMetaMaskLogin
    func checkAuthLogin(createResponse: JSON) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            print("****** checkMetaMaskLogin ******")
            do {
                
                let id = createResponse["id"].stringValue
                let pass = createResponse["passcode"].stringValue
                
                if (id == ""){
                    continuation.resume(throwing: FabricError.badInput("checkMetaMaskLogin failed. ID is empty"))
                }
                
                if (pass == ""){
                    continuation.resume(throwing: FabricError.badInput("checkMetaMaskLogin failed. passcode is empty"))
                }
                
                var endpoint = try self.getAuthEndpoint().appending("/wlt/login/redirect/metamask/")
                    .appending(id).appending("/").appending(pass)
                
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }

                let headers: HTTPHeaders = [
                     "Accept": "application/json",
                     "Content-Type": "application/json" ]

                AF.request(endpoint, encoding: JSONEncoding.default, headers: headers )
                    .responseJSON { response in

                    switch (response.result) {
                        case .success(let result):
                            continuation.resume(returning: JSON(result))
                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    struct Message: Decodable, Identifiable {
        let id: Int
        let from: String
        let message: String
    }
    
    func joinSignature(signature: [String: Any]) throws -> Data? {
        guard let r = signature["r"] as? String else {
            print("joinSig couldn't get r")
            return nil
        }

        guard let rData = r.data(using: .hexadecimal) else {
            print("joinSig couldn't get rData")
            return nil
        }
        
        guard let s = signature["s"] as? String else {
            print("joinSig couldn't get s")
            return nil
        }
        
        guard let sData = s.data(using: .hexadecimal) else {
            print("joinSig couldn't get sData")
            return nil
        }
        
        
        guard let recoveryParam = signature["recoveryParam"] as? Int else{
            print("joinSig couldn't get recoveryParam")
            return nil
        }
        
        var v = "0x1c"
        if recoveryParam == 0 {
            v = "0x1b"
        }
        
        //let vData = try RLP.encode(v)
        guard let vData = v.data(using: .hexadecimal) else {
            print("joinSig couldn't get vData")
            return nil
        }
        
        let joined = rData + sData + vData
        //print("joinSignature joined \(HexToBytes(joined.hexEncodedString()))")
        return joined
    }
    
    func hashPersonalMessage(_ personalMessage: Data) -> Data? {
        var prefix = "\u{19}Ethereum Signed Message:\n"
        prefix += String(personalMessage.count)
        guard let prefixData = prefix.data(using: .ascii) else {return nil}
        var data = Data()
        if personalMessage.count >= prefixData.count && prefixData == personalMessage[0 ..< prefixData.count] {
            data.append(personalMessage)
        } else {
            data.append(prefixData)
            data.append(personalMessage)
        }
        let hash = keccak256(data)
        return hash
    }
    
    //This uses the authd api with a cluster token (returned from /login/jwt) to get a fabric token
    func getFabricToken(authToken:String) async throws -> String{
        return try await withCheckedThrowingContinuation({ continuation in
            print("****** checkMetaMaskLogin ******")
            do {

                var endpoint = try self.getAuthEndpoint().appending("/wlt/sign/csat")
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }
                
                let headers: HTTPHeaders = [
                     "Accept": "application/json",
                     "Content-Type": "application/json",
                     "Authorization" : "bearer \(authToken)"]

                AF.request(endpoint, encoding: JSONEncoding.default, headers: headers )
                    .debugLog()
                    .responseString { response in
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                            
                        switch (response.result) {
                            case .success(let result):
                                if respJSON["errors"].exists() {
                                    continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                       response: respJSON, error:FabricError.unexpectedResponse("")))
                                }else {
                                    continuation.resume(returning: result)
                                }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func createFabricToken(duration: Int64 = 1 * 24 * 60 * 60 * 1000, address: String, contentSpaceId: String, authToken: String, external: Bool = false) async throws -> String {
    

        let adr = address.data(using: .hexadecimal)?.base64EncodedString()
        let token: JSON = [
          "sub": try addressToId(prefix: "iusr", address: address),
          "adr": adr,
          "spc": contentSpaceId,
          "iat": Date().now,
          "exp": Date().now + duration
        ]
    
        
        guard var tokenString = token.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.init(rawValue: 0)) else{
            throw FabricError.badInput("personalSign: could not get string for token structure \(token)")
        }
        
        //print ("tokenString \n",tokenString)
        /*tokenString = "{\"sub\":\"iusr2xvLGywBuSQBBbcoJN3ShsMHsWJU\",\"adr\":\"jPujzYbFMKh5vZ/llESSDPPng9k=\",\"spc\":\"ispc3ANoVSzNA3P6t7abLR69ho5YPPZU\",\"iat\":1680643350169,\"exp\":1680729750169}" */

        let message = "Eluvio Content Fabric Access Token 1.0\n\(tokenString)";
        
        //print("message ", message)

        guard var signature = try await self.personalSign(message:message, accountId: try addressToId(prefix: "ikms", address: address), authToken: authToken, external: external) else {
            throw FabricError.unexpectedResponse("personalSign: could not get signature")
        }
        
        //print("personal signature ", signature)
        
        let compressedToken = Data(referencing: try (Data(tokenString.utf8) as NSData).compressed(using: .zlib))
        
        //print("compressedToken ", compressedToken)
        
        signature.append(compressedToken)
        
        guard let bytes = HexToBytes(signature.hexEncodedString()) else {
            throw FabricError.unexpectedResponse("createFabricToken: could not get bytes from signature \(signature)")
        }
    
        let fabricToken =  "acspjc\(Base58.base58Encode(bytes))"
        return fabricToken
    }
    
    func personalSign(message: String, accountId: String, authToken: String, external: Bool = false) async throws -> Data? {
        
        let message2 = "\u{19}Ethereum Signed Message:\n\(message.count)\(message)"
        //print("personalSign message ", message2)
        let hash: Data = keccak256(Data(message2.utf8))
        /*guard let hash = hashPersonalMessage(Data(message.utf8)) else {
            throw FabricError.badInput
        }*/
        
        //return try self.joinSignature(signature:try await self.signDigest(digest:hash, accountId:accountId, authToken:authToken))
        
        //print("personalSign hash ", hash.hexEncodedString())
        let signature = try await self.signDigest(digest:hash, accountId:accountId, authToken:authToken, external: external)
        
        /*var signature: [String : Any] = ["sig":"0x98f93dae6dc74393e3b917de790304a9954fa46ef0c28596d13eecb7c61b850e0077903fc4d21de6e07d484271f8c5468dc66aca23fae08dc052a48928f1a87701",
              "v": 28,
              "r": "0x98f93dae6dc74393e3b917de790304a9954fa46ef0c28596d13eecb7c61b850e",
              "s": "0x0077903fc4d21de6e07d484271f8c5468dc66aca23fae08dc052a48928f1a877",
              "recoveryParam": 1]*/
        
        return try self.joinSignature(signature: signature)
    }
    
    // Uses the custodial wallet endpoint to sign
    // digest: hex string of the digest to sign
    // accountId: in ikms___ format
    // authToken: token given back from the /wlt/login/jwt endpoint
    func signDigest(digest: Data, accountId: String, authToken: String, external: Bool = false) async throws -> [String: AnyObject] {
        return try await withCheckedThrowingContinuation({ continuation in
            print("****** signDigest ******")
            do {
                
                var endpoint: String = ""
                if external {
                    endpoint = "https://wlt.stg.svc.eluv.io/as/wlt/sign/eth/".appending(accountId);
                }else {
                    endpoint = try self.getAuthEndpoint().appending("/wlt/sign/eth/").appending(accountId);
                }
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }

                print("Request: \(endpoint)")
                
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(authToken)",
                     "Accept": "application/json",
                     "Content-Type": "application/json" ]
                //let parameters : [String: Any] = ["hash":"0x27d27bad7e7172ea9adb6b6083d657f33045fe2b1f87cc96c85638a1f96b9439"]
                //print("digest: \(digest.hexEncodedString())")
                let parameters : [String: Any] = ["hash":digest.hexEncodedString()]
                
                AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
                    .debugLog()
                    .responseJSON { response in
                    debugPrint("signDigest Response: \(response)")
                    
                    switch (response.result) {
                        case .success( _):
                            if var result = response.value as? [String: AnyObject] {
                                if let v = result["v"] as? String {
                                    if let value = UInt8(v.dropFirst(2), radix: 16) {
                                        result["recoveryParam"] =  (value - 27) as AnyObject
                                        continuation.resume(returning: result)
                                    }else{
                                        continuation.resume(throwing: FabricError.unexpectedResponse("signDigest: Could not get UInt8 from v param of response \(response)"))
                                    }
                                }else{
                                    continuation.resume(throwing: FabricError.unexpectedResponse("signDigest: Could not get v param from response \(response)"))
                                }
                            }else{
                                continuation.resume(throwing: FabricError.unexpectedResponse("signDigest: Could not get value from response \(response)"))
                            }
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
    
    func getNftInfo(nftAddress: String, tokenId: String, accessCode: String, parameters : [String: String] = [:]) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            //print("****** getNftInfo ******")
            do {
                var endpoint: String = try self.getAuthEndpoint().appending("/nft/info/\(nftAddress)/\(tokenId)");
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]

                AF.request(endpoint, parameters: parameters, encoding: URLEncoding.default,headers: headers ).responseJSON { response in

                    switch (response.result) {
                        case .success(let result):
                            continuation.resume(returning: JSON(result))
                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func getWalletStatus(tenantId: String, accessCode: String, parameters : [String: String] = [:]) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                debugPrint("****** getWalletStatus ******")
                var endpoint: String = try self.getAuthEndpoint().appending("/wlt/status/act/\(tenantId)");
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }
                
                
                debugPrint("Request: \(endpoint)")
                debugPrint("Params: \(parameters)")
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                debugPrint("Headers: \(headers)")
                
                AF.request(endpoint, parameters: parameters, encoding: URLEncoding.default,headers: headers ).responseJSON { response in
                    //print("Response : \(response)")
                    var respJSON = JSON()
                    do{
                        respJSON = try JSON(data: response.data ?? Data())
                    }catch{}
                        
                    switch (response.result) {
                        case .success(let result):
                            if respJSON["errors"].exists() {
                                continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                   response: respJSON, error:FabricError.unexpectedResponse("")))
                            }else {
                                continuation.resume(returning: respJSON)
                            }

                         case .failure(let error):
                            var respJSON = JSON()
                            do{
                                respJSON = try JSON(data: response.data ?? Data())
                            }catch{}
                            continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                               response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func postWalletStatus(tenantId: String, accessCode: String, query:[String:String], body : [String: Any] = [:], bodyData : Data? = nil) async throws -> JSON{
        return try await withCheckedThrowingContinuation({ continuation in
            do {
                debugPrint("****** postWalletStatus ******")
                var endpoint: String = try self.getAuthEndpoint().appending("/wlt/act/\(tenantId)");
                if (environment != .prod){
                    endpoint = endpoint.appending("?env=\(environment)")
                }
                
                debugPrint("Request: \(endpoint)")
                debugPrint("Body: \(body)")
                debugPrint("Query: \(query)")
                
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer \(accessCode)",
                         "Accept": "application/json" ]
                debugPrint("Headers: \(headers)")
                
                guard let url = URL(string: endpoint) else{
                    continuation.resume(throwing: FabricError.badInput("Could not form url from \(endpoint)"))
                    return
                }
                
                var urlRequest = URLRequest(url: url)
                var encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: query)
                
                encodedURLRequest.httpMethod = "POST"
                
                encodedURLRequest.headers = headers
                
                let data = bodyData == nil ? try JSONSerialization.data(withJSONObject: body) : bodyData
                
                encodedURLRequest.httpBody = data
                
                print("Request: ", encodedURLRequest)
                
                AF.request(encodedURLRequest)
                    .debugLog()
                    .response{ response in
                    print("Response : \(response)")
                    
                    switch (response.result) {
                        case .success:
                            if let value = response.value {
                                continuation.resume(returning: JSON(value))
                            }else{
                                continuation.resume(throwing: FabricError.unexpectedResponse("postWalletStatus: could not get value from response \(response)"))
                            }
                    case .failure(let error):
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                        continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                           response: respJSON, error: error))
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
    func createEntitlement(tenantId: String, marketplace: String, sku: String, purchaseId: String, authToken: String) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            debugPrint("****** checkAuthLogin ******")
            var endpoint = "https://appsvc.svc.eluv.io/sample-purchase/gen-entitlement"
            endpoint = endpoint.appending("?env=\(environment)")
            
            let headers: HTTPHeaders = [
                 "Accept": "application/json",
                 "Content-Type": "application/json",
                 "Authorization" : "Bearer \(authToken)"]
            
            let parameters : [String: Any] = [
                "tenant_id":tenantId,
                "marketplace_id":marketplace,
                "sku":sku,
                "purchase_id": purchaseId]
            
            AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers )
                .responseJSON { response in
                    var respJSON = JSON()
                    do{
                        respJSON = try JSON(data: response.data ?? Data())
                    }catch{}
                        
                    switch (response.result) {
                        case .success(let result):
                            if respJSON["errors"].exists() {
                                continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                                   response: respJSON, error:FabricError.unexpectedResponse("")))
                            }else {
                                continuation.resume(returning: respJSON)
                            }

                     case .failure(let error):
                        var respJSON = JSON()
                        do{
                            respJSON = try JSON(data: response.data ?? Data())
                        }catch{}
                        continuation.resume(throwing: FabricError.apiError(code: response.response?.statusCode ?? 0,
                                                                           response: respJSON, error: error))
                 }
            }
        })
    }
    
}

