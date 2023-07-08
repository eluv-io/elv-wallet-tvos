//
//  FabricModels.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-02.
//

import Foundation

struct AppConfiguration: Codable {
    var app: AppConfig
    var network: [String: NetworkConfig]
    var auth0 : Auth0Config
    var allowed_tenants: [String]
}

struct AppConfig: Codable {
    var name: String
}

struct NetworkConfig: Codable {
    var config_url: String
    var main_obj_id: String
    var main_obj_lib_id: String //TEMP: Should use obj id only to retrieve lib id
    var state_store_urls: [String]
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
