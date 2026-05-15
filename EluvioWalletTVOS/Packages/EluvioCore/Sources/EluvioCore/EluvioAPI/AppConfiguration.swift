//
//  AppConfiguration.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-07-12.
//

import Foundation

public struct AppConfiguration: Codable {
  public var app: AppConfig
  public var network: [String: NetworkConfig]
  public var allowed_properties: [String]?
}

public enum AppMode: String, Codable, CaseIterable {
  case demo, main
}

public struct AppConfig: Codable {
  public var name: String
}

public struct NetworkConfig: Codable {
  public var config_url: String
  public var state_store_urls: [String]
  public var wallet_url: String
  public var badger_address: String
  public var mux: MuxConfig
}

public struct Auth0Config: Codable {
  public var domain: String
  public var client_id: String
  public var grant_type: String
}

public struct MuxConfig: Codable {
  public var env_key: String
}
