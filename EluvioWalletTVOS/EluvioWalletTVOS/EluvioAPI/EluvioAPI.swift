//
//  EluvioAPI.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-23.
//

import Foundation
import Combine
import SwiftUI
import SwiftyJSON
import CryptoKit

class EluvioAPI : ObservableObject {
    @Published var accountManager : AccountManager = AccountManager()
    @Published var fabric : Fabric = Fabric()
    @Published var pathState : PathState = PathState()
    @Published var viewState : ViewState
    @Published var refreshId = UUID().uuidString
    @Published var devMode: Bool = false
    //Requested token expiration during for login.
    @Published var ttlHours: Double = 0.004
    static var NONCE = UIDevice.current.identifierForVendor!.uuidString
    static var NONCE_HASHED: String {
        let hashedData = SHA512.hash(data: NONCE.data(using: .utf8)!)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(){
        
        debugPrint("Initiating Eluvio APIs on ", UIDevice.current.localizedModel)
        
        accountManager = .init()
        fabric = .init()
        pathState = .init()
        viewState = .init()

        do {
            devMode = UserDefaults.standard.bool(forKey: "api_devmode")
        }catch{
            print("Could not get api_devmode")
        }
        
        Publishers.MergeMany(
            self.accountManager.objectWillChange,
            self.fabric.objectWillChange,
            self.pathState.objectWillChange,
            self.viewState.objectWillChange
        )
        .sink(receiveValue: {
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        )
        .store(in: &self.cancellables)
    }
    
    func isCustomApp() -> Bool {
        if let props = APP_CONFIG.allowed_properties {
            if !props.isEmpty {
                return true
            }
        }
        
        return false
    }
    
    @MainActor
    func needsRefresh() {
        debugPrint("EluvioAPI needs refresh")
        refreshId = UUID().uuidString
    }

    @MainActor
    func setEnvironment(env:APIEnvironment){
        UserDefaults.standard.set(env.rawValue, forKey: "api_environment")
        fabric.setEnvironment(env: env)
        needsRefresh()
    }
    
    func getEnvironment() -> APIEnvironment {
        return fabric.getEnvironment()
    }
    
    @MainActor
    func setDevMode(devMode: Bool){
        UserDefaults.standard.set(devMode, forKey: "api_devmode")
        self.devMode = devMode
        needsRefresh()
    }
    
    func getDevMode() -> Bool {
        return devMode
    }
    
    func isDebugNode() -> Bool {
        return fabric.isDebugNode
    }
    
    func setIsDebugNode(debugNode: Bool) {
        fabric.isDebugNode = debugNode
    }
    
    func setTtlHours(_ hours:Double){
        self.ttlHours = hours
    }
    
    func getTtlHours() -> Double{
        return self.ttlHours
    }

    func signIn(account:Account, property:String) async throws {
        await signOut()
        fabric.fabricToken = account.fabricToken
        try accountManager.addAndSetCurrentAccount(account: account, type: account.type, property:property)
        try await fabric.connect(network:"main")
    }
    
    @MainActor
    func signOut(){
        accountManager.signOut()
        fabric.reset()
    }
    
    @MainActor func handleApiError(code: Int, response:JSON, error: Error){
        print("Could not get properties ", error)
        print("code \(code)")
        
        if code >= 400 && code < 500{
            Task{
                do {
                    try await self.refreshFabricToken()
                }catch{
                    debugPrint("Error refreshing Token ", error)
                }
            }
            return
        }
        
        print("Response ", response)
        let errors = response["errors"].arrayValue
        print("Response ", errors)
        if errors.isEmpty{
            print("errors field is empty")
            //eluvio.pathState.path.append(.errorView("A problem occured."))
            return
        }else if errors[0]["cause"]["reason"].stringValue.contains("token expired"){
            Task{
                do {
                    try await self.refreshFabricToken()
                }catch{
                    debugPrint("Error refreshing Token ", error)
                }
            }
            return
        }else if errors[0]["reason"].stringValue.contains("token expired"){
            Task{
                do {
                    try await self.refreshFabricToken()
                }catch{
                    debugPrint("Error refreshing Token ", error)
                }
            }
            return
        }else {
            print("Couldn't parse errors")
            return
        }
    }
    
    func createWalletAuthorization() -> String {
        do {
            if let account = accountManager.currentAccount {
                return try createWalletAuthorizationFromAccount(account: account)
            }
        }catch{
            print("Error creating wallet authorization", error.localizedDescription)
        }
        
        return ""
    }
    
    func createWalletAuthorizationFromAccount(account: Account) throws -> String{
        
        let address = account.getAccountAddress()
        var provider = "external"
        if account.type == .Auth0 {
            provider = "auth0"
        }
        
        if account.type == .Ory {
            provider = "ory"
        }

        return try fabric.createWalletAuthorization(
            address:address,
            email: account.email,
            expiresAt: account.expiresAt,
            clusterToken: account.clusterToken,
            fabricToken: account.fabricToken,
            provider: provider
        )
    }
    
    func refreshFabricToken() async throws  {
        if let account = accountManager.currentAccount {
            
            if account.refreshToken == "" {
                return
            }
            
            let response = try await fabric.refreshFabricToken(
                fabricToken: account.fabricToken,
                refreshToken: account.refreshToken,
                nonce:EluvioAPI.NONCE)
            
            if response["error"].stringValue != "" {
                throw FabricError.badInput(response["error"].stringValue)
            }
            
            account.fabricToken = response["token"].stringValue
            account.refreshToken = response["refresh_token"].stringValue
            account.expiresAt = response["expires_at"].int64Value
            fabric.fabricToken = account.fabricToken
            //debugPrint("Got new token ", account.fabricToken)
            //debugPrint("Got new refresh token ", account.fabricToken)
            debugPrint("expires at ", account.expiresAt)
            accountManager.saveCurrentAccount()
            return
        }
        
        throw FabricError.noLogin("Not Logged In")
    }
}

