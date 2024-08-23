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
        .sink(receiveValue: self.objectWillChange.send)
        .store(in: &self.cancellables)
    }
}
