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
  var allowed_properties: [String]?
}

enum AppMode: String, Codable, CaseIterable {
  case demo, main
}

struct AppConfig: Codable {
  var name: String
}

struct NetworkConfig: Codable {
  var config_url: String
  var state_store_urls: [String]
  var wallet_url: String
  var badger_address: String
  var mux: MuxConfig
}

struct Auth0Config: Codable {
  var domain: String
  var client_id: String
  var grant_type: String
}

struct MuxConfig: Codable {
  var env_key: String
}
