//
//  Fabric.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-03.
//

import Foundation

enum FabricError: Error {
    case invalidURL(String)
    case configError(String)
    case unexpectedResponse(String)
    case noLogin(String)
    case badInput(String)
}

struct RuntimeError: LocalizedError {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    var errorDescription: String? {
        description
    }
}

class Fabric: ObservableObject {
    var configUrl = ""
    var network = ""
    var configuration : FabricConfiguration? = nil
    var mainStaticUrl = "https://main.net955305.contentfabric.io"
    let mainStaticToken = "eyJxc3BhY2VfaWQiOiJpc3BjMlJVb1JlOWVSMnYzM0hBUlFVVlNwMXJZWHp3MSJ9Cg=="
    
    func connect(configUrl: String) async throws {
        guard let url = URL(string: configUrl) else {
            throw FabricError.invalidURL("\(self.configUrl)")
        }
        
        // Use the async variant of URLSession to fetch data
        // Code might suspend here
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let str = String(decoding: data, as: UTF8.self)
        
        print("Fabric config response: \(str)")

        let config = try JSONDecoder().decode(FabricConfiguration.self, from: data)
        self.configuration = config
    }
    
    
    func getEndpoint() -> String{
        
        guard let config = self.configuration else {
            debugPrint("config error")
            return mainStaticUrl
        }

        let endpoint = config.getFabricAPI()[0]
        if(endpoint.isEmpty){
            debugPrint("endpoint error.")
            return mainStaticUrl;
        }
        return endpoint
    }
    
    func createUrl(path:String) -> String {
        return getEndpoint() + path + "?authorization=\(mainStaticToken)"
    }
}
