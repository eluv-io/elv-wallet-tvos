//
//  MediaView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-18.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI

struct MyMediaView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @State var searchText = ""
    var featured : [AnyHashable] = []
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
    
    var body: some View {
        ScrollView{
            LazyVStack(alignment: .leading, spacing: 40){
                HeaderView(logo:logo, logoUrl: logoUrl, name:name)
                ScrollView (.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 20) {
                        ForEach(featured.indices, id: \.self) { index in
                            if let media = featured[index] as? MediaItem {
                                MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem,
                                          playerImageOverlayUrl:$playerImageOverlayUrl,
                                          playerTextOverlay:$playerTextOverlay,
                                          display: MediaDisplay.feature)
                            }
                            
                            if let nft = featured[index] as? NFTModel {
                                if nft.has_album ?? false {
                                    NFTAlbumView(nft:nft, display: MediaDisplay.feature)
                                }else {
                                    NFTView(nft:nft, display: MediaDisplay.feature)
   
                                }
                            }
                        }
                    }
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
                        .padding()
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
