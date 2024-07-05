//
//  ContentView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//
/*
import SwiftUI
import Combine
import AVKit
import SwiftyJSON

struct ContentView: View {
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
    
    @State var appeared: Double = 1.0
    
    @State var showError : Bool = false
    @State var errorMessage: String = ""
    @State var checkingViewState = false
    
    func reset() {
        showNft = false
        nft = NFTModel()
        showPlayer = false
        mediaItem = nil
        playerFinished = false
        showActivity = true
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
        self.checkingViewState = true
        
        defer {
            self.checkingViewState = false
        }
        
        if viewState.op == .none {
            showActivity = false
            return
        }
        

        Task{
            self.showActivity = true
        
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
                do {
                    contract = try await fabric.findItemAddress(marketplaceId: marketplace, sku: sku)
                    debugPrint(contract)
                }catch {
                    print("Could not find NFT contract from marketplace and sku. ")
                    self.showActivity = false
                    viewState.reset()
                    errorMessage = "Could not find bundle."
                    showError = true
                    return
                }
            }
                        
            if viewState.op == .item {
                if let _nft = fabric.getNFT(contract: contract,
                                            token: viewState.itemTokenStr) {
                    await MainActor.run {
                        self.nft = _nft
                        debugPrint("Showing NFT: ", nft.contract_name)
                        self.showNft = true
                    }
                }else{
                    debugPrint("Could not find NFT from deeplink. ")
                    viewState.reset()
                    errorMessage = "Could not find bundle."
                    showError = true
                    self.showActivity = false
                    return
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
                                self.showPlayer = true
                            }
                        }catch{
                            print("checkViewState - could not create MediaItemViewModel ", error)
                            viewState.reset()
                            errorMessage = "Could not play item."
                            showError = true
                            self.showActivity = false
                            return
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
                            self.showMinter = true
                        }
                    }
                }catch{
                    print("checkViewState mint error ", error)
                    viewState.reset()
                    errorMessage = "Could not mint item."
                    showError = true
                    self.showActivity = false
                    return
                }
            }else if viewState.op == .property {
                debugPrint("property marketplace: ", viewState.marketplaceId)
                
                let marketplace = viewState.marketplaceId
                await MainActor.run {
                    do {
                        self.property = try fabric.findProperty(marketplaceId: marketplace)
                        self.showProperty = true
                    }catch{
                        debugPrint("Could not find property ", marketplace)
                        viewState.reset()
                        errorMessage = "Could not find property."
                        showError = true
                        self.showActivity = false
                        return
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
                    if (showActivity) {
                        ProgressView()
                            .edgesIgnoringSafeArea(.all)
                    }else {
                        MainView()
                            .edgesIgnoringSafeArea(.all)
                            .preferredColorScheme(colorScheme)
                            .background(Color.mainBackground)
                            .navigationBarHidden(true)
                    }
                }
                .onAppear(){
                    debugPrint("ContentView onAppear")
                    self.showActivity = true

                    self.fabricCancellable = fabric.$isRefreshing
                        .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                        .sink { val in
                            debugPrint("isRefreshing changed.", fabric.isRefreshing)
                            if (fabric.isRefreshing && fabric.library.isEmpty){
                                return
                            }
                            
                            checkViewState()
                        }
                    
                    if viewState.op != .none {
                        checkViewState()
                    }else {
                        showActivity = false
                    }
                }
            }
            .onChange(of: self.showActivity) {
                debugPrint("ShowActivity ", self.showActivity)
            }
            .fullScreenCover(isPresented: $showNft, onDismiss: didFullScreenCoverDismiss) { [backLink, backLinkIcon, nft] in
                NFTDetail(nft: nft, backLink: backLink, backLinkIcon: backLinkIcon)
            }
            .fullScreenCover(isPresented: $showPlayer, onDismiss: didFullScreenCoverDismiss) { [backLink, backLinkIcon] in
                PlayerView(playerItem:self.$playerItem, seekTimeS: 0, finished: $playerFinished,
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
            .fullScreenCover(isPresented: $showError, onDismiss: didFullScreenCoverDismiss) {
                HStack{
                    Text(errorMessage).font(.description)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(.black)
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
        Task {
            try? await Task.sleep(nanoseconds: 1500000000)
            await MainActor.run {
                showActivity = false
            }
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

*/
