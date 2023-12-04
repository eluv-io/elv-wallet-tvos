//
//  AuthService.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2023-11-14.
//

import Foundation
import Alamofire
import SwiftyJSON
import Base58Swift
import CryptoKit

struct JRPCParams: Codable {
    var jsonrpc = "2.0"
    var id = 1
    var method: String
    var params: [String]
}

class AuthService {
    var ethApi : [String]
    var authorityApi: [String]
    var currentEthIndex = 0
    var currentAuthIndex = 0
    var network : String

    init(ethApi: [String], authorityApi: [String], network: String){
        self.ethApi = ethApi
        self.authorityApi = authorityApi
        self.network = network
    }
    
    //TODO: implement fail over
    func getEthEndpoint() throws -> String{
        let endpoint = self.ethApi[self.currentEthIndex]
        if(endpoint.isEmpty){
            throw FabricError.configError("getEthEndpoint: could not get endpoint")
        }
        return endpoint
    }
    
    func getAuthEndpoint() throws -> String{
        let endpoint = self.authorityApi[self.currentAuthIndex]
        if(endpoint.isEmpty){
            throw FabricError.configError("getEthEndpoint: could not get endpoint")
        }
        return endpoint
    }

    
    //TODO: Convert this to responseDecodable
    func createAuthLogin(redirectUrl: String) async throws -> JSON {
        return try await withCheckedThrowingContinuation({ continuation in
            print("****** createMetaMaskLogin ******")
            do {
                var endpoint = try self.getAuthEndpoint().appending("/wlt/login/redirect/metamask")

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
                            print("createMetaMaskLogin error: \(error)")
                            continuation.resume(throwing: error)
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

                let headers: HTTPHeaders = [
                     "Accept": "application/json",
                     "Content-Type": "application/json" ]

                AF.request(endpoint, encoding: JSONEncoding.default, headers: headers )
                    .responseJSON { response in

                    switch (response.result) {
                        case .success(let result):
                            continuation.resume(returning: JSON(result))
                         case .failure(let error):
                            print("Get Wallet Data Request error: \(error)")
                            continuation.resume(throwing: error)
                     }
                }
            }catch{
                continuation.resume(throwing: error)
            }
        })
    }
    
}


