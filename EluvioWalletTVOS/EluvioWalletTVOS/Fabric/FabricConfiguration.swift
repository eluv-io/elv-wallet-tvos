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
struct FabricConfiguration: Codable {
    let nodeID: String
    let network: Network
    let qspace: Qspace
    let fabricVersion: String

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case network, qspace
        case fabricVersion = "fabric_version"
    }
    
    func getQspaceId() -> String{
        return self.qspace.id
    }
    
    func getAuthServices() -> [String]{
        return self.network.services.authorityService
    }
    
    func getFabricAPI() -> [String]{
        return self.network.seedNodes.fabricAPI
    }
    
    func getEthereumAPI() -> [String]{
        return self.network.seedNodes.ethereumAPI
    }
}

// MARK: - Network
struct Network: Codable {
    let seedNodes: SeedNodes
    let apiVersions: [Int]
    let services: Services

    enum CodingKeys: String, CodingKey {
        case seedNodes = "seed_nodes"
        case apiVersions = "api_versions"
        case services
    }
}

// MARK: - SeedNodes
struct SeedNodes: Codable {
    let fabricAPI, ethereumAPI: [String]

    enum CodingKeys: String, CodingKey {
        case fabricAPI = "fabric_api"
        case ethereumAPI = "ethereum_api"
    }
}

// MARK: - Services
struct Services: Codable {
    let authorityService, ethereumAPI, fabricAPI, search: [String]

    enum CodingKeys: String, CodingKey {
        case authorityService = "authority_service"
        case ethereumAPI = "ethereum_api"
        case fabricAPI = "fabric_api"
        case search
    }
}

// MARK: - Qspace
struct Qspace: Codable {
    let id, version, type: String
    let ethereum: Ethereum
    let names: [String]
}

// MARK: - Ethereum
struct Ethereum: Codable {
    let networkID: Int

    enum CodingKeys: String, CodingKey {
        case networkID = "network_id"
    }
}
