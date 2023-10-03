//
//  ContentView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI
import Combine
import AVKit

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    
    @State private var viewStateCancellable: AnyCancellable? = nil
    @State private var fabricCancellable: AnyCancellable? = nil
    
    @State var showNft: Bool = false
    @State var nft = NFTModel()
    
    @State var showPlayer: Bool = false
    @State var mediaItem : MediaItem?
    @State var playerItem : AVPlayerItem?
    @State var playerFinished = false
    @State var showActivity = false
    
    func checkViewState() {
        debugPrint("checkViewState op ", viewState.op)
        if viewState.op == .none {
            return
        }
        self.showActivity = true
        if fabric.library.isEmpty {
            debugPrint("fabric library isEmpty")
            return
        }
        
        defer {
            viewState.reset()
            showActivity = false
        }
        
        if viewState.op == .item {
            if let _nft = fabric.getNFT(contract: viewState.itemContract,
                                        token: viewState.itemTokenStr) {
                self.nft = _nft
                debugPrint("Showing NFT: ", nft.contract_name)
                self.showNft = true
            }
        }else if viewState.op == .play {
            debugPrint("Playmedia: ", viewState.mediaId)
            if let _nft = fabric.getNFT(contract: viewState.itemContract,
                                        token: viewState.itemTokenStr) {
                self.nft = _nft
                if let item = self.nft.getMediaItem(id:viewState.mediaId) {
                    debugPrint("Found item: ", item.name)
                    self.mediaItem = item
                    Task {
                        do {
                            let item  = try await MakePlayerItem(fabric: fabric, media: item)
                            await MainActor.run {
                                self.playerItem = item
                                self.showPlayer = true
                            }
                        }catch{
                            print("MediaView could not create MediaItemViewModel ", error)
                        }

                    }
                }
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
                    .fullScreenCover(isPresented: $showActivity){
                        ProgressView()
                            .background(Color.black)
                            .frame(maxWidth:.infinity, maxHeight:.infinity)
                            .edgesIgnoringSafeArea(.all)
                    }
                    .fullScreenCover(isPresented: $showNft) {
                        NFTDetail(nft: self.nft)
                    }
                    .fullScreenCover(isPresented: $showPlayer) {
                        PlayerView(playerItem:self.$playerItem, finished: $playerFinished)
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
