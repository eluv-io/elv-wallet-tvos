//
//  ContentView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI
import Combine

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    
    @State private var viewStateCancellable: AnyCancellable? = nil
    @State private var fabricCancellable: AnyCancellable? = nil
    
    @State var showNft: Bool = false
    @State var nft = NFTModel()
    
    func checkViewState() {
        debugPrint("checkViewState op ", viewState.op)
        if viewState.op == .none {
            return
        }
        
        if fabric.library.isEmpty {
            debugPrint("fabric library isEmpty")
            return
        }
        
        if viewState.op == .item {
            if let _nft = fabric.getNFT(contract: viewState.itemContract,
                                        token: viewState.itemTokenStr) {
                self.nft = _nft
                debugPrint("Showing NFT: ", nft.contract_name)
                self.showNft = true
                viewState.reset()
            }
        }
    }
    
    var body: some View {
        if fabric.isLoggedOut {
            SignInView()
                .environmentObject(self.fabric)
                .preferredColorScheme(colorScheme)
                .background(Color.mainBackground)
                
        }else{
            NavigationView {
                MainView()
                    .preferredColorScheme(colorScheme)
                    .background(Color.mainBackground)
                    .navigationBarHidden(true)
                    .onAppear(){
                        self.viewStateCancellable = fabric.$library
                            .receive(on: DispatchQueue.main) //Delays the sink closure to get called after didSet
                            .sink { val in
                            debugPrint("Fabric library changed. isEmpty: ", val.isEmpty)
                            checkViewState()
                        }
                        self.fabricCancellable = viewState.$op
                            .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                            .sink { val in
                            debugPrint("viewState changed.", val)
                            checkViewState()
                        }
                    }
                    .fullScreenCover(isPresented: $showNft) {
                        NFTDetail(nft: self.nft)
                    }
            }
            .navigationViewStyle(.stack)
            .edgesIgnoringSafeArea(.all)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Fabric())
            .preferredColorScheme(.dark)
    }
}
