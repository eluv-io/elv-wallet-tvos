//
//  MyMediaView2.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-31.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI
import SwiftyJSON

struct MyMediaView2: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @State var searchText = ""
    var featured: Features = Features()
    var library : [MediaCollection] = []
    //?? Extract only the media? Resusing the NFTViews for now
    var albums: [NFTModel] = []
    var items: [NFTModel] = []
    @State var playerImageOverlayUrl : String = ""
    @State var playerTextOverlay : String = ""
    @State var showPlayer = false
    @State var playerItem : AVPlayerItem? = nil
    var logo = "e_logo"
    var logoUrl = ""
    var name = ""
    
    @State var heroImage : String?
    private var hasHero: Bool {
        return heroImage != nil && heroImage != ""
    }
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 0){
                if (hasHero) {
                    Button{} label: {
                        Image(heroImage ?? "")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth:.infinity)
                            .frame(height: 600,  alignment: .topLeading)
                            .clipped()
                    }
                    .padding(.bottom, 40)
                    .buttonStyle(NonSelectionButtonStyle())
                }else{
                    HeaderView(logo:logo, logoUrl: logoUrl)
                        .padding(.top,50)
                        .padding(.leading,80)
                        .padding(.bottom,80)
                }
                
                LazyVStack(alignment: .center, spacing: 40) {
                    ScrollView (.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 20) {
                            ForEach(featured.media) { media in
                                MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem,
                                          playerImageOverlayUrl:$playerImageOverlayUrl,
                                          playerTextOverlay:$playerTextOverlay,
                                          display: MediaDisplay.feature)
                            }
                            /*
                             ForEach(featured.collections) { collection in
                             //TODO?
                             }*/
                            
                            ForEach(featured.items) { nft in
                                if nft.has_album ?? false {
                                    NFTAlbumView(nft:nft, display: MediaDisplay.feature)
                                }else {
                                    NFTView(nft:nft, display: MediaDisplay.feature)
                                    
                                }
                            }
                            
                        }
                    }
                    .focusSection()
                    .introspectScrollView { view in
                        view.clipsToBounds = false
                    }
                    
                    
                    ForEach(library) { collection in
                        if(!collection.media.isEmpty){
                            VStack(alignment: .leading, spacing: 20){
                                Text(collection.name)
                                MediaCollectionView(mediaCollection: collection,
                                                    showPlayer: $showPlayer,
                                                    playerItem: $playerItem,
                                                    playerImageOverlayUrl:$playerImageOverlayUrl,
                                                    playerTextOverlay:$playerTextOverlay
                                )
                            }
                            .focusSection()
                        }
                    }
                    
                    if(!albums.isEmpty){
                        VStack(alignment: .leading, spacing: 20){
                            Text("Audio")
                            ScrollView (.horizontal, showsIndicators: false) {
                                LazyHStack{
                                    ForEach(albums) { album in
                                        NFTAlbumView(nft:album)
                                        //.frame( width: 225, height: 225)
                                    }
                                }
                            }
                            .introspectScrollView { view in
                                view.clipsToBounds = false
                            }
                        }
                    }
                    
                    if (!items.isEmpty){
                        VStack(alignment: .leading, spacing: 20){
                            Text("Items")
                            ScrollView (.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .top, spacing: 40) {
                                    ForEach(items) { nft in
                                        NFTTileView(nft:nft, display: MediaDisplay.tile)
                                    }
                                }
                            }
                            .introspectScrollView { view in
                                view.clipsToBounds = false
                            }
                        }
                    }
                    
                }
                .padding([.leading,.trailing,.bottom], 80)
            }
            .focusSection()
            .fullScreenCover(isPresented: $showPlayer) {
                PlayerView(playerItem:self.$playerItem,
                           playerImageOverlayUrl:$playerImageOverlayUrl,
                           playerTextOverlay:$playerTextOverlay
                )
                    .preferredColorScheme(colorScheme)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .background(Color.mainBackground)
        .ignoresSafeArea()
        .introspectScrollView { view in
            view.clipsToBounds = false
        }
    }
}


struct MyMediaView2_Previews: PreviewProvider {
    static var previews: some View {
        MyMediaView2()
    }
}
