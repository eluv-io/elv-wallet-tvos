//
//  FabricModels.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-02.
//

import Foundation

struct AppConfiguration: Codable {
    var config_url=""
    var networks: [String: String]
    var auth0 : Auth0Config
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
