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
                            
struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    var viewState: ViewState {
        return eluvio.viewState
    }
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
    
    //Gallery View
    @State var showGallery: Bool = false
    @State var mediaList: [GalleryItem] = []
    
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

    @State private var selectedProperty: MediaPropertyViewModel = MediaPropertyViewModel()
    
    @State var playerFinsished : Bool = false
    
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
        mediaList = []
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
                    let market = try await eluvio.fabric.getMarketplace(marketplaceId: marketplace)
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
                    contract = try await eluvio.fabric.findItemAddress(marketplaceId: marketplace, sku: sku)
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
                if let _nft = eluvio.fabric.getNFT(contract: contract,
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
            
                
                if let item = eluvio.fabric.getMediaItem(mediaId:viewState.mediaId) {
                    debugPrint("Found item: ", item.title)

                    do {
                        if let link = item.media_link?["sources"]["default"] {
                            debugPrint("Item link: ", link)
                            
                            let item  = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: link)
                            await MainActor.run {
                                self.playerItem = item
                                self.showPlayer = true
                            }
                        }
                    }catch{
                        print("checkViewState - could not create AVPlayerItem ", error)
                        viewState.reset()
                        errorMessage = "Could not play item."
                        showError = true
                        self.showActivity = false
                        return
                    }
                }
                
            }else if viewState.op == .gallery {
                debugPrint("Gallery View: ", viewState.mediaId)
                if let item = eluvio.fabric.getMediaItem(mediaId:viewState.mediaId) {
                    debugPrint("Found item: ", item.title)

                    do {
                        if let mediaList = item.media{
                            debugPrint("Media list: ", mediaList)
                            
                            var gallery : [GalleryItem] = []
                            
                            for item in mediaList {
                                //gallery.append(GalleryItem.create(propertyMedia:item))
                            }
                        
                            await MainActor.run {
                                self.mediaList = gallery
                                self.showGallery = true
                            }
                        }
                    }catch{
                        print("checkViewState - could not create AVPlayerItem ", error)
                        viewState.reset()
                        errorMessage = "Could not play item."
                        showError = true
                        self.showActivity = false
                        return
                    }
                }else{
                    viewState.reset()
                    errorMessage = "Could not find media."
                    showError = true
                    self.showActivity = false
                }
            }else if viewState.op == .mint {
                debugPrint("Mint marketplace: ", viewState.marketplaceId)
                debugPrint("Mint: sku", viewState.itemSKU)
                do {
                    let (itemJSON, tenantId) = try await eluvio.fabric.findItem(marketplaceId: marketplace, sku: sku)
                    
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
                        self.property = try eluvio.fabric.findProperty(marketplaceId: marketplace)
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
        NavigationStack(path: $eluvio.pathState.path) {
            Group{
                if eluvio.fabric.isLoggedOut {
                    /*
                     SignInView()
                     .environmentObject(self.eluvio)
                     .preferredColorScheme(colorScheme)
                     .background(Color.mainBackground)
                     */
                    DiscoverView()
                        .environmentObject(self.eluvio)
                        .preferredColorScheme(colorScheme)
                        .background(Color.mainBackground)
                }else{
                    //Don't use NavigationView, pops back to root on ObservableObject update
                    
                    ZStack {
                        if (showActivity) {
                            ProgressView()
                                .edgesIgnoringSafeArea(.all)
                        }else {
                            MainView()
                                .environmentObject(self.eluvio)
                                .edgesIgnoringSafeArea(.all)
                                .preferredColorScheme(colorScheme)
                                .background(Color.mainBackground)
                                .navigationBarHidden(true)
                        }
                    }
                }
            }
                .navigationDestination(for: NavDestination.self) { destination in
                    switch destination {
                    case .property:
                        if let property = eluvio.pathState.property {
                                MediaPropertyDetailView(property: MediaPropertyViewModel.create(mediaProperty: property, fabric:eluvio.fabric))
                                    .environmentObject(self.eluvio)
                            }else{
                                Text("Error")
                            }
                    
                    case .html:
                        QRView(url: eluvio.pathState.url)
                            .environmentObject(self.eluvio)
                    case .video:
                        if let playerItem = eluvio.pathState.playerItem {
                            PlayerView(playerItem: playerItem, seekTimeS: 0, finished: $playerFinsished)
                                .environmentObject(self.eluvio)
                        }
                    case .videoError:
                        if let params = eluvio.pathState.videoErrorParams {
                            if let mediaItem = params.mediaItem {
                                if params.type == .permission {
                                    PlayerErrorView(backgroundImageUrl:params.backgroundImage, title:"The media is not available")
                                }else if params.type == .upcoming {
                                    CountDownView(backgroundImageUrl:params.backgroundImage,
                                                  images:params.images,
                                                  imageUrl: mediaItem.thumbnail,
                                                  title:mediaItem.title,
                                                  infoText:mediaItem.headerString,
                                                  startDateTime: mediaItem.start_time)
                                }
                            }
                        }
                    case .mediaGrid:
                        if let item = eluvio.pathState.mediaItem {
                            if !eluvio.pathState.propertyId.isEmpty {
                                SectionItemListView(propertyId: eluvio.pathState.propertyId, item:item)
                                    .environmentObject(self.eluvio)
                            }
                        }
                    case .gallery:
                        GalleryView(gallery:eluvio.pathState.gallery)
                            .environmentObject(self.eluvio)
                    case .search:
                        if let params = eluvio.pathState.searchParams {
                            SearchView(searchString: params.searchTerm,
                                       propertyId: params.propertyId,
                                       primaryFilters: params.primaryFilters,
                                       currentPrimaryFilter: params.currentPrimaryFilter,
                                       currentSecondaryFilter: params.currentSecondaryFilter, 
                                       secondaryFilters: params.secondaryFilters
                            )
                            .environmentObject(self.eluvio)
                        }
                    case .sectionViewAll:
                        if let section = eluvio.pathState.section {
                            ScrollView {
                                SectionGridView(propertyId: eluvio.pathState.propertyId, section:section)
                                    .environmentObject(self.eluvio)
                            }
                            .scrollClipDisabled()
                        }
                    case .nft:
                        if let nft = eluvio.pathState.nft {
                            ItemDetailView(item:nft)
                                .environmentObject(self.eluvio)
                        }
                    case let .errorView(msg) :
                        Text(msg)
                            .background(.black)
                            .edgesIgnoringSafeArea(.all)
                    case let .login(params) :
                        if params.type == .auth0 {
                            DeviceFlowView()
                        }else if params.type == .ory {
                            OryDeviceFlowView()
                        }
                    }

                }
                .onAppear(){
                    debugPrint("ContentView onAppear")
                    self.showActivity = true
                    
                    self.viewStateCancellable = viewState.$op
                        .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                        .sink { val in
                            debugPrint("viewState changed.", viewState.op)
                            debugPrint("showNFT ", showNft)
                            if viewState.op == .none || eluvio.fabric.isLoggedOut{
                                self.showActivity = false
                                return
                            }
                            checkViewState()
                            showActivity = false
                        }

                    self.fabricCancellable = eluvio.fabric.$isRefreshing
                        .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                        .sink { val in
                            debugPrint("isRefreshing changed.", eluvio.fabric.isRefreshing)
                            if (eluvio.fabric.isRefreshing){
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
            .fullScreenCover(isPresented: $showGallery, onDismiss: didFullScreenCoverDismiss) { [mediaList] in
                GalleryView(gallery: mediaList)
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
