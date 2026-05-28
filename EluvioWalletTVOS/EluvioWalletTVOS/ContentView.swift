//
//  ContentView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import AVKit
import Combine
import SwiftUI
import SwiftyJSON

struct ContentView: View {
  @Environment(\.scenePhase) var scenePhase
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router
  var viewState: ViewState {
    return eluvio.viewState
  }
  @Environment(\.openURL) private var openURL

  @State private var viewStateCancellable: AnyCancellable? = nil

  @State var showNft: Bool = false
  @State var nft = NFTModel()

  @State var showPlayer: Bool = false
  @State var mediaItem: MediaItem?
  @State var playerItem: AVPlayerItem?
  @State var showActivity = true
  @State var backLink = ""
  @State var backLinkIcon = ""

  //Gallery View
  @State var showGallery: Bool = false
  @State var mediaList: [GalleryItem] = []

  @State var showMinter: Bool = false
  @State var mintItem = JSON()
  @State var mintInfo = MintInfo()
  @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  @State var timerCancellable: Cancellable? = nil

  @State var showProperty: Bool = false
  @State var property: PropertyModel?

  @State var appeared: Double = 1.0

  @State var showError: Bool = false
  @State var errorMessage: String = ""
  @State var checkingViewState = false

  func reset() {
    showNft = false
    nft = NFTModel()
    showPlayer = false
    mediaItem = nil
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

    Task {
      self.showActivity = true

      debugPrint("showActivity true ")

      debugPrint("backlink: ", viewState.backLink)
      self.backLink = viewState.backLink
      let marketplace = viewState.marketplaceId
      let sku = viewState.itemSKU
      var logo = ""
      if marketplace != "" {
        do {
          let market = try await eluvio.fabric.getMarketplace(marketplaceId: marketplace)
          logo = market.logo
        } catch {
          print("Could not getMarketplace", error)
        }
      }
      self.backLinkIcon = logo
      debugPrint("BackLink Icon: ", logo)

      var contract = viewState.itemContract

      if contract.isEmpty && !marketplace.isEmpty && !sku.isEmpty {
        do {
          contract = try await eluvio.fabric.findItemAddress(marketplaceId: marketplace, sku: sku)
          debugPrint(contract)
        } catch {
          print("Could not find NFT contract from marketplace and sku. ")
          self.showActivity = false
          viewState.reset()
          errorMessage = "Could not find bundle."
          showError = true
          return
        }
      }

      if viewState.op == .item {
        // This hasn't really worked in a long time, so just disabling it until we need it again
        let _nft: NFTModel? = nil  // = eluvio.fabric.getNFT(contract: contract, token: viewState.itemTokenStr)

        if let _nft {
          await MainActor.run {
            self.nft = _nft
            debugPrint("Showing NFT: ", nft.contract_name)
            self.showNft = true
          }
        } else {
          debugPrint("Could not find NFT from deeplink. ")
          viewState.reset()
          errorMessage = "Could not find bundle."
          showError = true
          self.showActivity = false
          return
        }

      } else if viewState.op == .play {
        debugPrint("Playmedia: ", viewState.mediaId)

        if let item = eluvio.fabric.getMediaItem(mediaId: viewState.mediaId) {
          debugPrint("Found item: ", item.title)

          do {
            if let link = item.media_link?["sources"]["default"] {
              debugPrint("Item link: ", link)
              let item = try await MakePlayerItemFromLink(
                fabric: eluvio.fabric, link: link, title: item.title ?? "",
                description: item.description ?? "", imageThumb: item.thumbnail())
              await MainActor.run {
                self.playerItem = item
                self.showPlayer = true
              }
            }
          } catch {
            print("checkViewState - could not create AVPlayerItem ", error)
            viewState.reset()
            errorMessage = "Could not play item."
            showError = true
            self.showActivity = false
            return
          }
        }

      } else if viewState.op == .gallery {
        debugPrint("Gallery View: ", viewState.mediaId)
        if let item = eluvio.fabric.getMediaItem(mediaId: viewState.mediaId) {
          debugPrint("Found item: ", item.title)

          do {
            if let mediaList = item.media {
              debugPrint("Media list: ", mediaList)

              var gallery: [GalleryItem] = []

              for item in mediaList {
                //gallery.append(GalleryItem.create(propertyMedia:item))
              }

              await MainActor.run {
                self.mediaList = gallery
                self.showGallery = true
              }
            }
          } catch {
            print("checkViewState - could not create AVPlayerItem ", error)
            viewState.reset()
            errorMessage = "Could not play item."
            showError = true
            self.showActivity = false
            return
          }
        } else {
          viewState.reset()
          errorMessage = "Could not find media."
          showError = true
          self.showActivity = false
        }
      } else if viewState.op == .mint {
        debugPrint("Mint marketplace: ", viewState.marketplaceId)
        debugPrint("Mint: sku", viewState.itemSKU)
        do {
          let (itemJSON, tenantId) = try await eluvio.fabric.findItem(
            marketplaceId: marketplace, sku: sku)

          if let item = itemJSON {
            await MainActor.run {
              self.mintItem = item
              self.mintInfo = MintInfo(
                tenantId: tenantId, marketplaceId: marketplace, sku: sku,
                entitlement: viewState.entitlement)
              debugPrint("findItem", mintItem["nft_template"]["nft"]["display_name"].stringValue)
              self.showMinter = true
            }
          }
        } catch {
          print("checkViewState mint error ", error)
          viewState.reset()
          errorMessage = "Could not mint item."
          showError = true
          self.showActivity = false
          return
        }
      } else if viewState.op == .property {
        // This has been broken for a long time, so we deleted the non-funtional code.
        // Will need to be re-implemented if we ever want it again
        debugPrint("property marketplace: ", viewState.marketplaceId)
      }
    }
  }

  var body: some View {
    NavigationStack(path: $router.path) {
      Group {
        if AccountStore.shared.isLoggedOut {
          DiscoverView()
            .preferredColorScheme(colorScheme)
        } else if eluvio.isCustomApp() {
          CustomAppRootView()
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(colorScheme)
            .navigationBarHidden(true)
        } else {
          //Don't use NavigationView, pops back to root on ObservableObject update

          ZStack {
            if showActivity {
              ProgressView()
                .edgesIgnoringSafeArea(.all)
                .accessibilityIdentifier("loading_indicator")
            } else {
              MainView()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(colorScheme)
                .navigationBarHidden(true)
                .accessibilityIdentifier("main_view")
            }
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.mainBackground)
      .navigationDestination(for: NavDestination.self) { destination in
        destination.view()
      }
      .onAppear {
        debugPrint("ContentView onAppear")
        self.showActivity = true

        self.viewStateCancellable = viewState.$op
          .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
          .sink { [weak viewState] val in
            debugPrint("viewState changed.", viewState?.op)
            debugPrint("showNFT ", showNft)
            if viewState?.op == .none || AccountStore.shared.isLoggedOut {
              self.showActivity = false
              return
            }
            checkViewState()
            showActivity = false
          }

        if viewState.op != .none {
          checkViewState()
        } else {
          showActivity = false
        }
      }
    }
    .onChange(of: self.showActivity) {
      debugPrint("ShowActivity ", self.showActivity)
    }
    .fullScreenCover(isPresented: $showPlayer, onDismiss: didFullScreenCoverDismiss) {
      [playerItem, backLink, backLinkIcon] in
      PlayerView(
        playerItem: playerItem, seekTimeS: 0,
        backLink: backLink, backLinkIcon: backLinkIcon
      )
    }
    .fullScreenCover(isPresented: $showGallery, onDismiss: didFullScreenCoverDismiss) {
      [mediaList] in
      GalleryView(gallery: mediaList)
    }
    .fullScreenCover(isPresented: $showError, onDismiss: didFullScreenCoverDismiss) {
      HStack {
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
    if backLink != "" {
      if let url = URL(string: backLink) {
        openURL(url) { accepted in
          debugPrint(
            accepted
              ? "Successfully launched backlink \(backLink)"
              : "Failure launching backlink \(backLink)")
        }
      }
    }
    reset()
    Task {
      try? await Task.sleep(for: .seconds(1.5))
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
