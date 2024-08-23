//
//  AppConfiguration.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-07-12.
//

import Foundation

struct AppConfiguration: Codable {
    var app: AppConfig
    var network: [String: NetworkConfig]
    var auth0 : Auth0Config
}

enum AppMode: String, Codable{
    case demo, prod
}

struct AppConfig: Codable {
    var name: String
    var mode: AppMode
}

struct NetworkOverrides: Codable {
    var fabric_url: String?
    var as_url: String?
    var eth_url: String?
}

struct NetworkConfig: Codable {
    var config_url: String
    var main_obj_id: String
    var main_obj_lib_id: String //TEMP: Should use obj id only to retrieve lib id
    var state_store_urls: [String]
    var wallet_url: String
    var overrides: NetworkOverrides?
    var badger_address: String
}

struct Auth0Config: Codable {
    var domain: String
    var client_id: String
    var grant_type : String
}
