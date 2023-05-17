//
//  FabricModels.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-02.
//

import Foundation

struct AppConfiguration: Codable {
    var network: [String: NetworkConfig]
    var auth0 : Auth0Config
}

struct NetworkConfig: Codable {
    var config_url: String
    var main_obj_id: String
    var main_obj_lib_id: String //TEMP: Should use obj id only to retrieve lib id
}

struct Auth0Config: Codable {
    var domain: String
    var client_id: String
    var grant_type : String
}

struct LoginResponse: Codable {
    var addr: String
    var eth: String
    var token: String
}
