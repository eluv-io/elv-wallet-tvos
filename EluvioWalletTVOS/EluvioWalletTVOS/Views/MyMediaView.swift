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
    //?? Extrat only the media? Resusing the NFTViews for now
    var albums: [NFTModel] = []
    @State var playerImageOverlayUrl : String = ""
    @State var playerTextOverlay : String = ""
    @State var showPlayer = false
    @State var playerItem : AVPlayerItem? = nil
    var logo = "e_logo"
    var logoUrl = ""
    var name = "Eluvio Wallet"
    @State var heroImage : String?
    private var hasHero: Bool {
        return heroImage != nil && heroImage != ""
    }
    
    var body: some View {
        ScrollView{
            LazyVStack(alignment: .leading, spacing: 40){
                if (hasHero) {
                    Button{} label: {
                        Image(heroImage ?? "")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth:.infinity)
                            .frame(height: 600,  alignment: .topLeading)
                            .clipped()
                    }
                    .padding([.top, .leading, .trailing], -80)
                    //.padding(.bottom, 20)
                    .buttonStyle(NonSelectionButtonStyle())
                }else{
                    HeaderView(logo:logo, logoUrl: logoUrl, name:name)
                }
                
                if(featured.count > 0){
                    Text("Pick Up Where You Left Off").frame(maxWidth:.infinity, alignment:.center)
                        .padding()
                }
                
                ScrollView (.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 20) {
/*
                        ForEach(featured.indices, id: \.self) { index in
                            if let media = featured[index].object as? MediaItem {
                                MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem,
                                          playerImageOverlayUrl:$playerImageOverlayUrl,
                                          playerTextOverlay:$playerTextOverlay,
                                          display: MediaDisplay.feature)
                            }
                            
                            if let nft = featured[index].object as? NFTModel {
                                if nft.has_album ?? false {
                                    NFTAlbumView(nft:nft, display: MediaDisplay.feature)
                                }else {
                                    NFTView(nft:nft, display: MediaDisplay.feature)
   
                                }
                            }
                        }
                   */
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
