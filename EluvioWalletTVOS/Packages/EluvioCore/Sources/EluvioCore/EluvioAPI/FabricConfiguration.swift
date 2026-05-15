//
//  FabricConfiguration.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-04.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? newJSONDecoder().decode(Welcome.self, from: jsonData)

/*
 {
    "node_id":"inod4T4nRPqKa3MK8JrP89Ghggio2eWQ",
    "network":{
       "seed_nodes":{
          "fabric_api":[
             "https://host-216-66-40-19.contentfabric.io",
             "https://host-76-74-34-198.contentfabric.io",
             "https://host-154-14-240-138.contentfabric.io"
          ],
          "ethereum_api":[
             "https://host-216-66-40-19.contentfabric.io/eth/",
             "https://host-76-74-34-198.contentfabric.io/eth/",
             "https://host-60-240-133-204.contentfabric.io/eth/"
          ]
       },
       "api_versions":[
          3
       ],
       "services":{
          "authority_service":[
             "https://host-216-66-89-94.contentfabric.io/as",
             "https://host-66-220-3-86.contentfabric.io/as"
          ],
          "ethereum_api":[
             "https://host-216-66-40-19.contentfabric.io/eth/",
             "https://host-76-74-34-198.contentfabric.io/eth/",
             "https://host-60-240-133-204.contentfabric.io/eth/"
          ],
          "fabric_api":[
             "https://host-216-66-40-19.contentfabric.io",
             "https://host-76-74-34-198.contentfabric.io",
             "https://host-154-14-240-138.contentfabric.io"
          ],
          "search":[
             "https://host-184-104-204-51.contentfabric.io/"
          ]
       }
    },
    "qspace":{
       "id":"ispc3ANoVSzNA3P6t7abLR69ho5YPPZU",
       "version":"BaseContentSpace20191203120000PO",
       "type":"Ethereum",
       "ethereum":{
          "network_id":955210
       },
       "names":[
          "demov3"
       ]
    },
    "fabric_version":"develop-part-preamble@eda62a0d1bda7b2385d7711389bc9135edaae001 2021-10-27T23:06:57Z"
 }
 */

import Foundation

// MARK: - Welcome

public struct FabricConfiguration: Codable {
  public let nodeID: String
  public let network: Network
  public let qspace: Qspace

  public enum CodingKeys: String, CodingKey {
    case nodeID = "node_id"
    case network, qspace
  }

  public func getQspaceId() -> String {
    return qspace.id
  }

  public func getAuthServices() -> [String] {
    return network.services.authorityService
  }

  public func getFabricAPI() -> [String] {
    return network.seedNodes.fabricAPI
  }

  public func getEthereumAPI() -> [String] {
    return network.seedNodes.ethereumAPI
  }
}

// MARK: - Network

public struct Network: Codable {
  public let seedNodes: SeedNodes
  public let services: Services

  public enum CodingKeys: String, CodingKey {
    case seedNodes = "seed_nodes"
    case services
  }
}

// MARK: - SeedNodes

public struct SeedNodes: Codable {
  public let fabricAPI, ethereumAPI: [String]

  public enum CodingKeys: String, CodingKey {
    case fabricAPI = "fabric_api"
    case ethereumAPI = "ethereum_api"
  }
}

// MARK: - Services

public struct Services: Codable {
  public let authorityService, ethereumAPI, fabricAPI: [String]
  public let search: [String]?
  public enum CodingKeys: String, CodingKey {
    case authorityService = "authority_service"
    case ethereumAPI = "ethereum_api"
    case fabricAPI = "fabric_api"
    case search
  }
}

// MARK: - Qspace

public struct Qspace: Codable {
  public let id, version, type: String
  public let names: [String]
}
