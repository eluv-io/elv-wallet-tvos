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
    @State var showActivity = true
    @State var backLink = ""
    @State var backLinkIcon = ""
    
    @State var showMinter : Bool = false
    @State var mintItem = JSON()
    @State var mintInfo = MintInfo()
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var timerCancellable: Cancellable? = nil
    
    @State var showProperty : Bool = false
    @State var property : PropertyModel?
    
    func reset() {
        showNft = false
        nft = NFTModel()
        showPlayer = false
        mediaItem = nil
        playerFinished = false
        showActivity = false
        showMinter = false
        showProperty = false
        property = nil
        mintItem = JSON()
        mintInfo = MintInfo()
        backLink = ""
        backLinkIcon = ""
    }
    
    func checkViewState() {
        debugPrint("checkViewState op ", viewState.op)
        if self.showActivity == true {
            //return
        }

        if viewState.op == .none {
            return
        }
        
        Task{
            self.showActivity = true
            debugPrint("showActivity true ")
        }
        
        if viewState.op == .item {
            let marketplace = viewState.marketplaceId
            let sku = viewState.itemSKU
            
            if let _nft = fabric.getNFT(contract: viewState.itemContract,
                                        token: viewState.itemTokenStr) {
                self.nft = _nft
                debugPrint("backlink: ", viewState.backLink)
                self.backLink = viewState.backLink
            
                Task {
                    do {
                        let startTime = DispatchTime.now()
                        let market = try await fabric.getMarketplace(marketplaceId: marketplace)
                        
                        let endTime = DispatchTime.now()

                        let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                        let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0
                        debugPrint("getMarketplace function time ms: ", elapsedTimeInMilliSeconds)
                        
                        await MainActor.run {
                            viewState.reset()
                            showActivity = false
                            debugPrint("Showing NFT: ", nft.contract_name)
                            self.backLinkIcon = market.logo
                            self.showNft = true
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
                                viewState.reset()
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
        }else if viewState.op == .property {
            debugPrint("property marketplace: ", viewState.marketplaceId)

            let marketplace = viewState.marketplaceId

            do {
                property = try fabric.findProperty(marketplaceId: marketplace)
                viewState.reset()
                showActivity = false
                showProperty = true
            }catch{
                debugPrint("Could not find property ", marketplace)
                viewState.reset()
                showActivity = false
            }
        }else{
            viewState.reset()
            showActivity = false
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
                    //FIXME: The activity is buggy and might not be wanted...
                        /*.overlay {
                            if (showActivity){
                                ZStack{
                                    Color.black.edgesIgnoringSafeArea(.all)
                                    ProgressView()
                                }
                            }
                        }*/
                        .onAppear(){
                            debugPrint("ContentView onAppear")
                            //reset()
                            self.viewStateCancellable = fabric.$library
                                .receive(on: DispatchQueue.main) //Delays the sink closure to get called after didSet
                                .sink { val in
                                    debugPrint("Fabric library changed. viewState", viewState.op)
                                    if viewState.op == .none || fabric.isLoggedOut {
                                        if !fabric.isRefreshing {
                                            showActivity = false
                                        }
                                        return
                                    }
                                    
                                    checkViewState()
                                    showActivity = false
                                }
                            self.fabricCancellable = viewState.$op
                                .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                                .sink { val in
                                    debugPrint("viewState changed.", val)
                                    if val == .none || fabric.isLoggedOut{
                                        return
                                    }
                                    checkViewState()
                                    showActivity = false
                                }
                            if viewState.op == .mint {
                                checkViewState()
                                showActivity = false
                            }
                        }
                        .fullScreenCover(isPresented: $showNft) { [backLink, backLinkIcon] in
                            NFTDetail(nft: self.nft, backLink: backLink, backLinkIcon: backLinkIcon)
                        }
                        .fullScreenCover(isPresented: $showPlayer) {
                            PlayerView(playerItem:self.$playerItem, seekTimeS: 0, finished: $playerFinished)
                        }
                        .fullScreenCover(isPresented: $showMinter) {
                            MinterView(marketItem: $mintItem, mintInfo:$mintInfo)
                        }
                        .fullScreenCover(isPresented: $showProperty) {
                            if let prop = property {
                                let items : [NFTModel] = !prop.contents.isEmpty ? prop.contents[0].contents : []
                                NavigationView {
                                    PropertyMediaView(featured: prop.featured,
                                                      library: prop.media,
                                                      albums: prop.albums,
                                                      items: items,
                                                      liveStreams: prop.live_streams,
                                                      sections: prop.sections,
                                                      heroImage: prop.heroImage ?? ""
                                    )
                                }
                                .navigationViewStyle(.stack)
                            }
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
