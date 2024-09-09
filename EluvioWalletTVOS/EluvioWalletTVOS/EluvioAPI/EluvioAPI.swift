//
//  EluvioAPI.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-23.
//

import Foundation
import Combine
import SwiftUI

class EluvioAPI : ObservableObject {
    @Published var accountManager : AccountManager = AccountManager()
    @Published var fabric : Fabric = Fabric()
    @Published var pathState : PathState = PathState()
    @Published var viewState = ViewState()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(){
        accountManager = .init()
        fabric = .init()
        pathState = .init()
        viewState = .init()
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
    

    func setEnvironment(env:APIEnvironment){
        UserDefaults.standard.set(env.rawValue, forKey: "api_environment")
        if let signer = fabric.signer {
            fabric.signer?.setEnvironment(env: env)
        }
    }
    
    func getEnvironment() -> APIEnvironment {
        return fabric.getEnvironment()
    }
    
    
    func signIn(account:Account, property:String) async throws {
        signOut()
        fabric.fabricToken = account.fabricToken
        try accountManager.addAndSetCurrentAccount(account: account, type: account.type, property:property)
        try await fabric.connect(network:"main")
    }
    
    func signOut(){
        accountManager.signOut()
        fabric.reset()
        pathState.reset()
        viewState.reset()
    }
}
