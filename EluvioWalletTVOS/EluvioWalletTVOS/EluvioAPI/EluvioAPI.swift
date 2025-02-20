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

class EluvioAPI : ObservableObject {
    @Published var accountManager : AccountManager = AccountManager()
    @Published var fabric : Fabric = Fabric()
    @Published var pathState : PathState = PathState()
    @Published var viewState = ViewState()
    @Published var refreshId = UUID().uuidString
    @Published var devMode: Bool = false
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(){
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
    
    
    func signIn(account:Account, property:String) async throws {
        await signOut()
        fabric.fabricToken = account.fabricToken
        try accountManager.addAndSetCurrentAccount(account: account, type: account.type, property:property)
        try await fabric.connect(network:"main")
        await needsRefresh()
    }
    
    @MainActor
    func signOut(){
        accountManager.signOut()
        fabric.reset()
        pathState.reset()
        viewState.reset()
        needsRefresh()
    }
    
    @MainActor func handleApiError(code: Int, response:JSON, error: Error){
        print("Could not get properties ", error)
        print("code \(code)")
        
        if code >= 400 && code < 500{
            self.pathState.path = []
            self.signOut()
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
            self.pathState.path = []
            self.signOut()
            return
        }else if errors[0]["reason"].stringValue.contains("token expired"){
            self.pathState.path = []
            self.signOut()
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
}

