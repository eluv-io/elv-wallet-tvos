//
//  ContentView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI
import Combine
import AVKit
import SwiftyJSON

struct MintInfo {
    var tenantId: String = ""
    var marketplaceId: String = ""
    var sku: String = ""
}

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
    
    @State var showMinter : Bool = false
    @State var mintItem = JSON()
    @State var mintInfo = MintInfo()
    @State var timer = Timer.publish(every: 1, on: .main, in: .common)
    @State var timerCancellable: Cancellable? = nil
    
    func reset() {
        showNft = false
        nft = NFTModel()
        showPlayer = false
        mediaItem = nil
        playerFinished = false
        showActivity = false
        showMinter = false
        mintItem = JSON()
        mintInfo = MintInfo()
    }
    
    func checkViewState() {
        debugPrint("checkViewState op ", viewState.op)
        if self.showActivity == true {
            return
        }
        
        /*
        if fabric.isRefreshing {
            return
        }
         */
        
        defer {
            viewState.reset()
            showActivity = false
        }

        if viewState.op == .none {
            return
        }
        
        self.showActivity = true
        
        if viewState.op == .item {
            if let _nft = fabric.getNFT(contract: viewState.itemContract,
                                        token: viewState.itemTokenStr) {
                self.nft = _nft
                viewState.reset()
                showActivity = false
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
                                self.showActivity = false
                                self.showPlayer = true
                            }
                        }catch{
                            print("checkViewState - could not create MediaItemViewModel ", error)
                            await MainActor.run {
                                viewState.reset()
                                showActivity = false
                            }
                        }
                    }
                }
                
                
            }
        }else if viewState.op == .mint {
            debugPrint("Mint marketplace: ", viewState.marketplaceId)
            debugPrint("Mint: sku", viewState.itemSKU)
            
            let marketplace = viewState.marketplaceId
            let sku = viewState.itemSKU
            Task{
                do {
                    let (itemJSON, tenantId) = try await fabric.findItem(marketplaceId: marketplace, sku: sku)

                    if let item = itemJSON {
                        await MainActor.run {
                            self.mintItem = item
                            self.mintInfo = MintInfo(tenantId: tenantId, marketplaceId: marketplace, sku: sku)
                            debugPrint("findItem", mintItem["nft_template"]["nft"]["display_name"].stringValue)
                            viewState.reset()
                            showActivity = false
                            self.showMinter = true
                        }
                    }
                }catch{
                    print("checkViewState mint error ", error)
                    await MainActor.run {
                        viewState.reset()
                        showActivity = false
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
                        debugPrint("ContentView onAppear")
                        reset()
                        self.viewStateCancellable = fabric.$library
                            .receive(on: DispatchQueue.main) //Delays the sink closure to get called after didSet
                            .sink { val in
                            debugPrint("Fabric library changed. viewState", viewState.op)
                            if viewState.op == .none || fabric.isLoggedOut {
                                return
                            }
                                
                            checkViewState()
                        }
                        self.fabricCancellable = viewState.$op
                            .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                            .sink { val in
                            debugPrint("viewState changed.", val)
                            if val == .none || fabric.isLoggedOut{
                                return
                            }
                            checkViewState()
                        }
                        if viewState.op == .mint {
                            checkViewState()
                        }
                    }
                    .fullScreenCover(isPresented: $showActivity){
                        ZStack{
                            Color.black.edgesIgnoringSafeArea(.all)
                            ProgressView()
                        }
                    }
                    .fullScreenCover(isPresented: $showNft) {
                        NFTDetail(nft: self.nft)
                    }
                    .fullScreenCover(isPresented: $showPlayer) {
                        PlayerView(playerItem:self.$playerItem, finished: $playerFinished)
                    }
                    .fullScreenCover(isPresented: $showMinter) {
                        MinterView(marketItem: $mintItem, mintInfo:$mintInfo)
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
