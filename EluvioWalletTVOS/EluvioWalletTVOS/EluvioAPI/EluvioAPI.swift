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
    @Published var apiLogs: Bool = false
    //Requested token expiration during for login.
    @Published var ttlHours: Double = 336
    static var NONCE: String {
        UIDevice.current.identifierForVendor!.uuidString
    }
    //static var NONCE = "TESTNONCE"
    static var NONCE_HASHED: String {
        let hashedData = SHA512.hash(data: NONCE.data(using: .utf8)!)
        let hex = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hex
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(){
        
        debugPrint("Initiating Eluvio APIs on ", UIDevice.current.localizedModel)
        
        debugPrint("NONCE: ", EluvioAPI.NONCE)
        debugPrint("NONCE_HASHED: ", EluvioAPI.NONCE_HASHED)
        
        accountManager = .init()
        fabric = .init()
        pathState = .init()
        viewState = .init()

        devMode = UserDefaults.standard.bool(forKey: "api_devmode")
        apiLogs = UserDefaults.standard.bool(forKey: "api_logs")
        fabric.apiLogs = apiLogs

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

    @MainActor
    func setApiLogs(apiLogs: Bool){
        UserDefaults.standard.set(apiLogs, forKey: "api_logs")
        self.apiLogs = apiLogs
        fabric.apiLogs = apiLogs
        fabric.signer?.apiLogs = apiLogs
    }

    func getApiLogs() -> Bool {
        return apiLogs
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
        try accountManager.addAndSetCurrentAccount(account: account, type: account.type, property:property)
        try await fabric.connect(token: account.fabricToken)

        // Pre-cache authenticated properties in background so DiscoverView
        // gets an instant cache hit after login.
        // needsRefresh() is called AFTER caching completes so DiscoverView
        // finds fresh auth ViewModels instead of building from raw properties.
        let fabricRef = self.fabric
        let devMode = self.getDevMode()
        Task { @MainActor in
            do {
                let props = try await fabricRef.getProperties(
                    includePublic: true,
                    noAuth: false,
                    newFetch: true,
                    devMode: devMode,
                    properties: APP_CONFIG.allowed_properties
                )

                let cache = PersistentDataCache()
                let network = fabricRef.network
                cache.cacheProperties(props, network: network, authState: true)

                var viewModels: [MediaPropertyViewModel] = []
                for prop in props {
                    let vm = await MediaPropertyViewModel.create(mediaProperty: prop, fabric: fabricRef)
                    if !vm.image.isEmpty {
                        viewModels.append(vm)
                    }
                }
                cache.cachePropertyViewModels(viewModels, network: network, authState: true)
                // Trigger DiscoverView refresh NOW that auth cache is ready
                self.needsRefresh()
            } catch {
                // Still trigger refresh so DiscoverView can fall back to other cache paths
                self.needsRefresh()
            }
        }
    }
    
    @MainActor
    func signOut(){
        accountManager.signOut()
        fabric.reset()
    }
    
    //TODO:
    func handleApiError(code: Int, response:JSON, error: Error){
        print("handleApiError ", error)

        if code == 401 {
            return
        }

        if code >= 400 && code < 500{
            return
        }

        let errors = response["errors"].arrayValue
        if errors.isEmpty{
            return
        }else if errors[0]["cause"]["reason"].stringValue.contains("token expired"){
            return
        }else if errors[0]["reason"].stringValue.contains("token expired"){
            return
        }else {
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
    
    func refreshFabricToken() async {
        if let account = accountManager.currentAccount {
            
            if account.refreshToken == "" {
                return
            }
            
            do {
                let response = try await fabric.refreshFabricToken(
                    fabricToken: account.fabricToken,
                    refreshToken: account.refreshToken,
                    nonce:EluvioAPI.NONCE)
                
                if response["error"].stringValue != "" {
                    throw FabricError.badInput(response["error"].stringValue)
                }
                
                let fabricToken = response["token"].stringValue
                let refreshToken = response["refresh_token"].stringValue
                let expiresAt = response["expires_at"].int64Value
                
                if fabricToken.isEmpty || refreshToken.isEmpty || expiresAt == 0 {
                    throw FabricError.badInput(response["error"].stringValue)
                }
                
                account.fabricToken = fabricToken
                account.refreshToken = refreshToken
                account.expiresAt = expiresAt
                fabric.fabricToken = account.fabricToken
                accountManager.saveCurrentAccount()
                await needsRefresh()
                return
            }catch(FabricError.apiError(let code, let response, let error)){
                handleApiError(code: code, response: response, error: error)
                if (code == 401 || code == 403){
                    await signOut()
                    pathState.path.removeAll()
                }
                return
            }catch{
                print("Problem refreshing token ", error)
                await signOut()
                pathState.path.removeAll()
                return;
            }
        }
    }
}

