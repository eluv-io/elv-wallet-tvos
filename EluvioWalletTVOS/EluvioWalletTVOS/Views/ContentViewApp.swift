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

struct WalletApp: View {

    @Environment(\.scenePhase) var scenePhase
    
    static let signInBackground = RadialGradient(gradient: Gradient(colors: [Color(hex:0x0e2765),
                                                                             Color(hex:0x040b1d)]),
                                                                                   center: .top, startRadius: 0, endRadius:1200)
    
    @StateObject
    var fabric = Fabric(createDemoProperties:false)
    @StateObject
    var viewState = ViewState(isBranded: false, signInBackground:signInBackground)

    @State var isBranded : Bool = false
    @State var openUrl : URL? = nil
    
    @State var opacity : CGFloat = 0.0
    
    init(){
        
    }
    
    init(isBranded: Bool){
        self.isBranded = isBranded
        viewState.isBranded = isBranded
    }
    
    var body: some View {

            ZStack{
                Color.black.edgesIgnoringSafeArea(.all)
                    ContentViewApp()
                    .opacity(opacity)
                    .environmentObject(fabric)
                    .environmentObject(viewState)
                    .preferredColorScheme(.dark)
                    .onAppear(){
                        Task {
                            do {
                                try await fabric.connect(network:"")
                            }catch{
                                print("Error connecting to the fabric: ", error)
                            }
                        }
                    }
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .inactive {
                            print("Inactive")
                            self.opacity = 0.0
                        } else if newPhase == .active {
                            print("Active ")
                            Task {
                                await MainActor.run {
                                    withAnimation(.easeInOut(duration: 3)) {
                                        self.opacity = 1.0
                                    }
                                }
                            }
                        } else if newPhase == .background {
                            print("Background")
                            self.opacity = 0.0
                        }
                    }
                    .onOpenURL { url in
                        debugPrint("url opened: ", url)
                        Task {
                            await viewState.handleLink(url:url, fabric:fabric)
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
   

struct ContentViewApp: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @Environment(\.openURL) private var openURL
    
    @State private var viewStateCancellable: AnyCancellable? = nil
    @State private var fabricCancellable: AnyCancellable? = nil
    
    @State var showNft: Bool = false
    @State var nft = NFTModel()
    
    @State var showPlayer: Bool = false
    @State var mediaItem : MediaItem?
    @State var playerItem : AVPlayerItem?
    @State var playerFinished = false
    @State var showActivity = false
    @State var backLink = ""
    @State var backLinkIcon = ""
    
    @State var showMinter : Bool = false
    @State var mintItem = JSON()
    @State var mintInfo = MintInfo()
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var timerCancellable: Cancellable? = nil
    
    @State var showProperty : Bool = false
    @State var property : PropertyModel?
    
    @State var appeared: Double = 1.0
    @State var checkingViewState = false
    
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
        checkingViewState = false
        withAnimation(.easeInOut(duration: 2)) {
            self.appeared = 1.0
        }
        viewState.reset()
    }
    
    func checkViewState() {
        debugPrint("checkViewState op ", viewState.op)
        if self.checkingViewState == true {
            return
        }
        
        defer {
            self.checkingViewState = false
        }
        
        if viewState.op == .none {
            return
        }
    
        
        Task{

            
            self.showActivity = true
            self.checkingViewState = true
            
            debugPrint("showActivity true ")
            
            debugPrint("backlink: ", viewState.backLink)
            self.backLink = viewState.backLink
            let marketplace = viewState.marketplaceId
            let sku = viewState.itemSKU
            var logo = ""
            if marketplace != ""{
                do {
                    let market = try await fabric.getMarketplace(marketplaceId: marketplace)
                    logo = market.logo
                }catch{
                    print("Could not getMarketplace", error)
                }
            }
            self.backLinkIcon = logo
            debugPrint("BackLink Icon: ", logo)
            
            var contract = viewState.itemContract
            
            if contract.isEmpty && !marketplace.isEmpty && !sku.isEmpty{
                contract = try await fabric.findItemAddress(marketplaceId: marketplace, sku: sku)
                debugPrint(contract)
            }
            
            
            if viewState.op == .item {

                
                if let _nft = fabric.getNFT(contract: contract,
                                            token: viewState.itemTokenStr) {
                    await MainActor.run {
                        self.nft = _nft
                        debugPrint("Showing NFT: ", nft.contract_name)
                        self.showActivity = false
                        self.showNft = true
                        //viewState.reset()
                    }
                }
                
            }else if viewState.op == .play {
                debugPrint("Playmedia: ", viewState.mediaId)
                
                if let _nft = fabric.getNFT(contract: contract,
                                            token: viewState.itemTokenStr){
                    self.nft = _nft
                    if let item = self.nft.getMediaItem(id:viewState.mediaId) {
                        debugPrint("Found item: ", item.name)
                        self.mediaItem = item
                        do {
                            let item  = try await MakePlayerItem(fabric: fabric, media: item)
                            await MainActor.run {
                                self.playerItem = item
                                self.showActivity = false
                                self.showPlayer = true
                                //viewState.reset()
                            }
                        }catch{
                            print("checkViewState - could not create MediaItemViewModel ", error)
                            self.showActivity = false
                            viewState.reset()
                        }
                    }
                }
            }else if viewState.op == .mint {
                debugPrint("Mint marketplace: ", viewState.marketplaceId)
                debugPrint("Mint: sku", viewState.itemSKU)
                do {
                    let (itemJSON, tenantId) = try await fabric.findItem(marketplaceId: marketplace, sku: sku)
                    
                    if let item = itemJSON {
                        await MainActor.run {
                            self.mintItem = item
                            self.mintInfo = MintInfo(tenantId: tenantId, marketplaceId: marketplace, sku: sku, entitlement:viewState.entitlement)
                            debugPrint("findItem", mintItem["nft_template"]["nft"]["display_name"].stringValue)
                            self.showActivity = false
                            self.showMinter = true
                            //viewState.reset()
                        }
                    }
                }catch{
                    print("checkViewState mint error ", error)
                    await MainActor.run {
                        self.showActivity = false
                        viewState.reset()
                    }
                }
            }else if viewState.op == .property {
                debugPrint("property marketplace: ", viewState.marketplaceId)
                
                let marketplace = viewState.marketplaceId
                await MainActor.run {
                    do {
                        self.property = try fabric.findProperty(marketplaceId: marketplace)
                        self.showActivity = false
                        self.showProperty = true
                        //viewState.reset()
                    }catch{
                        debugPrint("Could not find property ", marketplace)
                        self.showActivity = false
                        viewState.reset()
                    }
                }
            }
        }
    }
    
    var body: some View {
        if fabric.isLoggedOut {
            SignInView()
                .environmentObject(self.fabric)
                .environmentObject(self.viewState)
                .preferredColorScheme(colorScheme)
                .background(Color.mainBackground)
        }else{
            //Don't use NavigationView, pops back to root on ObservableObject update
            NavigationStack {
                ZStack {
                    if (appeared == 1.0) {
                        MainView()
                            .preferredColorScheme(colorScheme)
                            .background(Color.mainBackground)
                            .navigationBarHidden(true)
                    }
                    if (showActivity) {
                        ProgressView()
                            .edgesIgnoringSafeArea(.all)
                    }
                }
                .onDisappear {debugPrint("ContentView onDisappear")
                    //self.appeared = 0.0
                }
                .onAppear(){
                    withAnimation(.easeInOut(duration: 2)) {
                        self.appeared = 1.0
                    }
                    debugPrint("ContentView onAppear")
                    self.viewStateCancellable = viewState.$op
                        .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                        .sink { val in
                            debugPrint("viewState changed.", viewState.op)
                            debugPrint("showNFT ", showNft)
                            if viewState.op == .none || fabric.isLoggedOut{
                                self.showActivity = false
                                return
                            }
                            checkViewState()
                            showActivity = false
                        }
                    
                    self.fabricCancellable = fabric.$isRefreshing
                        .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                        .sink { val in
                            debugPrint("isRefreshing changed.", fabric.isRefreshing)
                            if (fabric.isRefreshing && fabric.library.isEmpty){
                                self.showActivity = true
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
            }
            .onChange(of:showNft){
                if (showNft){
                    self.appeared = 0.0
                }
            }
            .onChange(of:showMinter){
                if (showMinter){
                    self.appeared = 0.0
                }
            }
            .onChange(of:showProperty){
                if (showProperty){
                    self.appeared = 0.0
                }
            }
            .onChange(of:showPlayer){
                if (showProperty){
                    self.appeared = 0.0
                }
            }
            .fullScreenCover(isPresented: $showNft, onDismiss: didFullScreenCoverDismiss) { [backLink, backLinkIcon] in
                NFTDetail(nft: self.nft, backLink: backLink, backLinkIcon: backLinkIcon)
            }
            .fullScreenCover(isPresented: $showPlayer, onDismiss: didFullScreenCoverDismiss) { [playerItem, backLink, backLinkIcon] in
                PlayerView(playerItem:playerItem, seekTimeS: 0, finished: $playerFinished,
                           backLink: backLink, backLinkIcon: backLinkIcon
                )
            }
            .fullScreenCover(isPresented: $showMinter, onDismiss: didFullScreenCoverDismiss) { [backLink, backLinkIcon] in
                MinterView(marketItem: $mintItem, mintInfo:$mintInfo,
                           backLink: backLink, backLinkIcon: backLinkIcon
                )
            }
            .fullScreenCover(isPresented: $showProperty, onDismiss: didFullScreenCoverDismiss) { [backLink, backLinkIcon] in
                if let prop = property {
                    let items : [NFTModel] = !prop.contents.isEmpty ? prop.contents[0].contents : []
                    NavigationStack {
                        PropertyMediaView(featured: prop.featured,
                                          library: prop.media,
                                          albums: prop.albums,
                                          items: items,
                                          liveStreams: prop.live_streams,
                                          sections: prop.sections,
                                          heroImage: prop.heroImage ?? "",
                                          backLink: backLink, backLinkIcon: backLinkIcon
                        )
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    func didFullScreenCoverDismiss() {
        if (backLink != ""){
            if let url = URL(string: backLink) {
                openURL(url) { accepted in
                    debugPrint(accepted ? "Successfully launched backlink \(backLink)" : "Failure launching backlink \(backLink)")
                }
            }
        }
        reset()
    }
}


struct ContentViewApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewApp()
            .environmentObject(Fabric())
            .preferredColorScheme(.dark)
    }
}
