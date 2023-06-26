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
    @EnvironmentObject var fabric: Fabric
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
    @State var redeemableFeatures: [RedeemableViewModel] = []
    @State var localizedFeatures: [MediaItem] = []
    private var preferredLocation:String {
        fabric.profile.profileData.preferredLocation ?? ""
    }
    
    @State var heroImage : String?
    private var hasHero: Bool {
        return heroImage != nil && heroImage != ""
    }
    
    private var featuredListCount: Int {
        let num = localizedFeatures.isEmpty ? featured.media.count : localizedFeatures.count
        return redeemableFeatures.count + num  + featured.items.count
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
                    
                    if (featuredListCount <= 3){
                        HStack() {
                            if !redeemableFeatures.isEmpty {
                                ForEach(redeemableFeatures) { redeemable in
                                    RedeemableCardView(redeemable: redeemable, display: MediaDisplay.feature)
                                }
                                
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
                        .introspectScrollView { view in
                            view.clipsToBounds = false
                        }
                    }
                    
                    
                    ForEach(library) { collection in
                        if(!collection.media.isEmpty){
                            VStack(alignment: .leading, spacing: 20){
                                Text(collection.name)
                                MediaCollectionView(mediaCollection: collection)
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
                                        MediaView2(mediaItem: media,
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
        }
        .ignoresSafeArea()
        .background(Color.mainBackground)
        .introspectScrollView { view in
            view.clipsToBounds = false
        }
        .onAppear(){
            Task {
                for nft in self.items {
                    if let redeemableOffers = nft.redeemable_offers {
                        print("RedeemableOffers ", redeemableOffers)
                        if !redeemableOffers.isEmpty {
                            var redeemableFeatures: [RedeemableViewModel] = []
                            for redeemable in redeemableOffers {
                                do{
                                    if (!preferredLocation.isEmpty) {
                                        if redeemable.location.lowercased() == preferredLocation.lowercased() || redeemable.location == ""{
                                            let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                            redeemableFeatures.append(redeem)
                                        }
                                    }else{
                                        let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                        redeemableFeatures.append(redeem)
                                    }
                                }catch{
                                    print("Error processing redemption ", redeemable)
                                }
                            }
                            self.redeemableFeatures = redeemableFeatures
                        }
                    }
                    
                    
                    if let additions = nft.additional_media_sections {
                        if (!preferredLocation.isEmpty) {
                            var locals:[MediaItem] = []
                            
                            for feature in additions.featured_media {
                                if (feature.location == ""){
                                    locals.append(feature)
                                }
                                
                                if (feature.location == preferredLocation){
                                    locals.append(feature)
                                }
                            }
                            self.localizedFeatures = locals
                        }
                    }
                    
                }
            }
        }
    }
}


struct MyMediaView_Previews: PreviewProvider {
    static var previews: some View {
        MyMediaView()
    }
}
