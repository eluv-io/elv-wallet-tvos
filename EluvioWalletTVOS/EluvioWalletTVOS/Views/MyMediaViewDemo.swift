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

struct MyMediaViewDemo: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var searchText = ""

    var library = MediaLibrary()
    var featured: Features {
        return library.features
    }
    var items: [NFTModel] {
        return library.items
    }

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
        return fabric.profile.profileData.preferredLocation ?? ""
    }
    
    @State var heroImage : String?
    private var hasHero: Bool {
        return heroImage != nil && heroImage != ""
    }
    
    private var featuredListCount: Int {
        
        //let num = localizedFeatures.isEmpty ? featured.media.count : localizedFeatures.count
        //return redeemableFeatures.count + num  + featured.items.count

        return library.features.media.count + library.features.items.count
        
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
                
                VStack(alignment: .center, spacing: 40) {
                    if (featuredListCount <= 3){
                        HStack() {
                            ForEach(redeemableFeatures) { redeemable in
                                RedeemableCardView(redeemable: redeemable, display: MediaDisplay.feature)
                            }
                            
                            
                            ForEach(featured.media) { media in
                                MediaView2(mediaItem: media, display: MediaDisplay.feature)
                            }
                             
                            /*
                            if !localizedFeatures.isEmpty {
                                ForEach(localizedFeatures) { media in
                                    MediaView2(mediaItem: media, display: MediaDisplay.feature)
                                }
                            }
                             */
                            
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
                                
                                
                                ForEach(featured.media) { media in
                                    MediaView2(mediaItem: media, display: MediaDisplay.feature)
                                }
                                
                                /*
                                if !localizedFeatures.isEmpty {
                                    ForEach(localizedFeatures) { media in
                                        MediaView2(mediaItem: media, display: MediaDisplay.feature)
                                    }
                                }
                                 */

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
                    if(!library.mediaRows.isEmpty) {
                        ForEach(library.mediaRows) { row in
                            if (!row.collection.media.isEmpty){
                                VStack(alignment: .leading, spacing: 20){
                                    Text(row.name).font(.rowTitle)
                                    MediaCollectionView(mediaCollection: row.collection)
                                }
                                .focusSection()
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
                }
                .padding([.leading,.trailing,.bottom], 80)
            }
        }
        .ignoresSafeArea()
        .background(Color.mainBackground)
        .scrollClipDisabled()
        .onAppear(){
            Task {
                var locals:[MediaItem] = []
                var redeemableFeatures: [RedeemableViewModel] = []
                
                for nft in self.items {
                    if let redeemableOffers = nft.redeemable_offers {
                        //debugPrint("RedeemableOffers ", redeemableOffers)
                        if !redeemableOffers.isEmpty {
                            for redeemable in redeemableOffers {
                                do{
                                    if (!preferredLocation.isEmpty) {
                                        //debugPrint("Redeemable: ", redeemable.name)
                                        if redeemable.location.lowercased() == preferredLocation.lowercased() || redeemable.location == ""{
                                            //debugPrint("location matched: ", redeemable.location.lowercased())
                                            let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)

                                            redeemableFeatures.append(redeem)
                                            //debugPrint("Appended.")
                                        }
                                    }else{
                                        let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                        redeemableFeatures.append(redeem)
                                    }
                                }catch{
                                    print("Error processing redemption ", redeemable)
                                }
                            }
                        }
                    }
                    
                    
                    if let additions = nft.additional_media_sections {
                        if (!preferredLocation.isEmpty) {
                            
                            for feature in additions.featured_media {
                                if (feature.location == ""){
                                    locals.append(feature)
                                }
                                
                                if (feature.location == preferredLocation){
                                    locals.append(feature)
                                }
                            }
                        }
                    }
                    
                }
                self.redeemableFeatures = redeemableFeatures.unique()
                self.localizedFeatures = locals.unique()
            }
        }
    }
}


struct MyMediaViewDemo_Previews: PreviewProvider {
    static var previews: some View {
        MyMediaViewDemo()
    }
}

