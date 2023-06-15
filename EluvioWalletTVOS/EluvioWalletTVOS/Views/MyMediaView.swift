//
//  MediaView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-18.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI
import SwiftyJSON

struct MyMediaView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @State var searchText = ""
    var featured: Features = Features()
    var library : [MediaCollection] = []
    //?? Extract only the media? Resusing the NFTViews for now
    var albums: [NFTModel] = []
    var items: [NFTModel] = []
    var drops: [ProjectModel] = []
    var liveStreams : [MediaItem] = []
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
                            .frame(width:1920,height: 739, alignment: .topLeading)
                            .clipped()
                    }
                    .padding(.bottom, 40)
                    .buttonStyle(NonSelectionButtonStyle())
                    .focusSection()
                }else{
                    HeaderView(logo:logo, logoUrl: logoUrl)
                        .padding(.top,50)
                        .padding(.leading,80)
                        .padding(.bottom,80)
                }
                
                LazyVStack(alignment: .center, spacing: 40) {
                    
                    if (!drops.isEmpty){
                        ScrollView (.horizontal, showsIndicators: false) {
                            LazyHStack(alignment: .top, spacing: 52) {
                                ForEach(drops) { drop in
                                    DropView<DropDetail>(
                                        image: drop.image_wide ?? "",
                                        title: drop.title ?? "",
                                        destination: DropDetail(drop:drop)
                                    )
                                }
                            }
                            .focusSection()
                        }
                        .introspectScrollView { view in
                            view.clipsToBounds = false
                        }
                    }
                    
                    
                    ScrollView (.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 52) {
                            ForEach(featured.media) { media in
                                /*MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem,
                                          playerImageOverlayUrl:$playerImageOverlayUrl,
                                          playerTextOverlay:$playerTextOverlay,
                                          display: MediaDisplay.feature)*/
                                MediaView2(mediaItem: media, display: MediaDisplay.feature)
                            }
                            
                            ForEach(featured.items) { nft in
                                if nft.has_album ?? false {
                                    NFTAlbumView(nft:nft, display: MediaDisplay.feature)
                                }else {
                                    NFTView<NFTDetail>(
                                        display: MediaDisplay.feature,
                                        image: nft.meta.image ?? "",
                                        title: nft.meta.displayName ?? "",
                                        subtitle: nft.meta.editionName ?? "",
                                        propertyLogo: nft.property?.image ?? "",
                                        propertyName: nft.property?.title ?? "",
                                        tokenId: nft.token_id_str ?? "",
                                        destination: NFTDetail(nft: nft)
                                    )
                                    
                                }
                            }
                            
                        }
                        .focusSection()
                    }
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
                        .focusSection()
                    }
                    
                    if (!liveStreams.isEmpty){
                        VStack(alignment: .leading, spacing: 40){
                            ForEach(liveStreams) { media in
                                Text(media.name)
                                ScrollView (.horizontal, showsIndicators: false) {
                                    LazyHStack(alignment: .top, spacing: 52) {
                                        MediaView(media: media,
                                                  showPlayer: $showPlayer, playerItem: $playerItem,
                                                  playerImageOverlayUrl:$playerImageOverlayUrl,
                                                  playerTextOverlay:$playerTextOverlay,
                                                  display: MediaDisplay.video)
                                        
                                        ForEach(media.schedule ?? []) { upcoming in
                                            MediaCard(display: MediaDisplay.video, image: upcoming.image ?? "",
                                                      isUpcoming: true, title: "UPCOMING", subtitle: upcoming.startDateTimeString
                                            )
                                        }
                                        
                                    }
                                }
                                .introspectScrollView { view in
                                    view.clipsToBounds = false
                                }
                            }
                        }
                        .focusSection()
                    }
                    
                    if (!items.isEmpty){
                        VStack(alignment: .leading, spacing: 40){
                            Text("Items")
                            ScrollView (.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .top, spacing: 52) {
                                    ForEach(items) { nft in
                                        
                                        if nft.has_tile{
                                            NFTTileView(nft:nft)
                                        }else{
                                             NFTView<NFTDetail>(
                                                 image: nft.meta.image ?? "",
                                                 title: nft.meta.displayName ?? "",
                                                 subtitle: nft.meta.editionName ?? "",
                                                 propertyLogo: nft.property?.logo ?? "",
                                                 propertyName: nft.property?.title ?? "",
                                                 tokenId: "#" + (nft.token_id_str ?? ""),
                                                 destination: NFTDetail(nft: nft),
                                                 scale: 0.72
                                             )
                                             .padding(.top,10)
                                        }
                                    }
                                }
                            }
                            .introspectScrollView { view in
                                view.clipsToBounds = false
                            }
                        }
                        .focusSection()
                    }

                    if (!drops.isEmpty){
                        ForEach(drops) { drop in
                            VStack(alignment: .leading, spacing: 40){
                                Text(drop.title ?? "")
                                ScrollView (.horizontal, showsIndicators: false) {
                                    LazyHStack(alignment: .top, spacing: 52) {
                                        ForEach(drop.contents) { nft in
                                             NFTView<NFTPlayerView>(
                                                 image: nft.meta.image ?? "",
                                                 title: nft.meta.displayName ?? "",
                                                 subtitle: nft.meta.editionName ?? "",
                                                 propertyLogo: nft.property?.logo ?? "",
                                                 propertyName: nft.property?.title ?? "",
                                                 tokenId: nft.token_id_str ?? "",
                                                 destination: NFTPlayerView(nft:nft),
                                                 scale: 0.72
                                             )
                                        }
                                    }
                                }
                                .introspectScrollView { view in
                                    view.clipsToBounds = false
                                }
                            }
                        }
                    }
                }
                .padding([.leading,.trailing,.bottom], 80)
            }
            .fullScreenCover(isPresented: $showPlayer) {
                PlayerView(playerItem:self.$playerItem,
                           playerImageOverlayUrl:$playerImageOverlayUrl,
                           playerTextOverlay:$playerTextOverlay
                )
                .preferredColorScheme(colorScheme)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .ignoresSafeArea()
        .background(Color.mainBackground)
        .introspectScrollView { view in
            view.clipsToBounds = false
        }
    }
}


struct MyMediaView_Previews: PreviewProvider {
    static var previews: some View {
        MyMediaView()
    }
}
