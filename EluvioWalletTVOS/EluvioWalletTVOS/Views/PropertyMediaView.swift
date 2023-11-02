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

struct PropertyMediaView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var searchText = ""
    var featured: Features = Features()
    var library : [MediaCollection] = []
    //?? Extract only the media? Resusing the NFTViews for now
    var albums: [NFTModel] = []
    var items: [NFTModel] = []
    var drops: [ProjectModel] = []
    var liveStreams : [MediaItem] = []
    var sections: [MediaSection] = []
    @State var playerImageOverlayUrl : String = ""
    @State var playerTextOverlay : String = ""
    @State var showPlayer = false
    @State var playerItem : AVPlayerItem? = nil
    @State var redeemableFeatures: [RedeemableViewModel] = []
    @State var localizedFeatures: [MediaItem] = []
    private var preferredLocation:String {
        fabric.profile.profileData.preferredLocation ?? ""
    }
    
    var heroImage : String = ""
    private var hasHero: Bool {
        return heroImage != ""
    }
    
    private var featuredListCount: Int {
        return featured.media.count + featured.items.count
        
    }
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 0){
                if (hasHero) {
                    Button{} label: {

                        
                        if (heroImage.hasPrefix("http")){
                            WebImage(url: URL(string: heroImage))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth:.infinity)
                                .clipped()
                        }else if (heroImage != ""){
                            Image(heroImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth:.infinity)
                                .clipped()
                        }
                        
                    }
                    .padding(.bottom, 40)
                    .buttonStyle(NonSelectionButtonStyle())
                    .focusSection()
                }else{
                    HeaderView()
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
                        .scrollClipDisabled()
                    }
                    
                    if (featuredListCount <= 3){
                        HStack() {
                            ForEach(featured.media) { media in
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
                    }else{
                        ScrollView (.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 52) {
                                ForEach(redeemableFeatures) { redeemable in
                                    RedeemableCardView(redeemable: redeemable, display: MediaDisplay.feature)
                                }
                                
                                if !localizedFeatures.isEmpty {
                                    ForEach(localizedFeatures) { media in
                                        MediaView2(mediaItem: media, display: MediaDisplay.feature)
                                    }
                                }else{
                                    ForEach(featured.media) { media in
                                        MediaView2(mediaItem: media, display: MediaDisplay.feature)
                                    }
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
                        .scrollClipDisabled()
                    }
                    
                    Spacer(minLength: 20)
                    
                    ForEach(library) { collection in
                        if(!collection.media.isEmpty){
                            VStack(alignment: .leading, spacing: 20){
                                Text(collection.name).font(.rowTitle)
                                MediaCollectionView(mediaCollection: collection)
                            }
                            .focusSection()
                        }
                    }
                    
                    if(!albums.isEmpty){
                        VStack(alignment: .leading, spacing: 20){
                            Text("Audio").font(.rowTitle)
                            ScrollView (.horizontal, showsIndicators: false) {
                                LazyHStack{
                                    ForEach(albums) { album in
                                        NFTAlbumView(nft:album)
                                    }
                                }
                            }
                            .scrollClipDisabled()
                        }
                        .focusSection()
                    }
                    
                    if (!liveStreams.isEmpty){
                        VStack(alignment: .leading, spacing: 40){
                            ForEach(liveStreams) { media in
                                Text(media.name).font(.rowTitle)
                                ScrollView (.horizontal, showsIndicators: false) {
                                    LazyHStack(alignment: .top, spacing: 52) {
                                        MediaView2(mediaItem: media,
                                                  display: MediaDisplay.video)
                                        
                                        ForEach(media.schedule ?? []) { upcoming in
                                            MediaCard(display: MediaDisplay.video, image: upcoming.image ?? "",
                                                      isUpcoming: true, title: "UPCOMING", subtitle: upcoming.startDateTimeString
                                            )
                                        }
                                        
                                    }
                                }
                                .scrollClipDisabled()
                            }
                        }
                        .focusSection()
                    }
                    
                    if(!sections.isEmpty){
                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: 20){
                                Text(section.name).font(.rowTitle)
                                ForEach(section.collections) { collection in
                                    if(!collection.media.isEmpty){
                                        VStack(alignment: .leading, spacing: 10){
                                            Text(collection.name).font(.rowSubtitle)
                                            MediaCollectionView(mediaCollection: collection)
                                        }
                                        .focusSection()
                                    }
                                }
                            }
                        }
                    }
                    
                    if (!items.isEmpty){
                        VStack(alignment: .leading, spacing: 40){
                            Text("Items").font(.rowTitle)
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
                            .scrollClipDisabled()
                        }
                        .focusSection()
                    }

                    if (!drops.isEmpty){
                        ForEach(drops) { drop in
                            VStack(alignment: .leading, spacing: 40){
                                Text(drop.title ?? "").font(.rowTitle)
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
                                .scrollClipDisabled()
                            }
                        }
                    }
                }
                .padding([.leading,.trailing,.bottom], 80)
            }
            .padding(.bottom, 100) //This fixes bottom row being cut off
        }
        .ignoresSafeArea()
        .background(Color.mainBackground)
        .scrollClipDisabled()
        .onAppear(){

        }
             
    }
}


struct PropertyMediaView_Previews: PreviewProvider {
    static var previews: some View {
        PropertyMediaView()
    }
}
