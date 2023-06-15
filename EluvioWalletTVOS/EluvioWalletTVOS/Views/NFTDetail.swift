//
//  NFTDetail.swift
//  NFTDetail
//
//  Created by Wayne Tran on 2021-09-27.
//

import SwiftUI
import SwiftyJSON
import AVKit
import SDWebImageSwiftUI

struct NFTDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @Namespace var nftDetails
    @EnvironmentObject var fabric: Fabric
    @State var search = false
    @State var searchText = ""
    @State var showPlayer = false
    @State var playerItem : AVPlayerItem? = nil
    var title = ""
    @Binding var nft: NFTModel
    @Binding var featuredMedia: [MediaItem]
    @Binding var collections: [MediaCollection]
    @Binding var richText : AttributedString
    @FocusState var isFocused
    @State var playerImageOverlayUrl : String = ""
    @State var playerTextOverlay : String = ""
    @State var backgroundImageUrl : String = ""
    @FocusState private var headerFocused: Bool
    @State var redeemableFeatures: [RedeemableViewModel] = []
    //@State var featureViewModels: [MediaItemViewModel] = []
    
    var body: some View {
        ZStack(alignment:.topLeading) {
            if (self.backgroundImageUrl.hasPrefix("http")){
                WebImage(url: URL(string: self.backgroundImageUrl))
                    .resizable()
                    .indicator(.activity) // Activity Indicator
                    .transition(.fade(duration: 0.5))
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
                    .frame(alignment: .topLeading)
                    .clipped()
            }else if(self.backgroundImageUrl != "") {
                Image(self.backgroundImageUrl)
                    .resizable()
                    .transition(.fade(duration: 0.5))
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
                    .frame(alignment: .topLeading)
                    .clipped()
            }else{
                Rectangle().foregroundColor(Color.clear)
                .frame(maxWidth:.infinity, maxHeight:.infinity)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Button{} label: {
                        VStack(alignment: .leading, spacing: 20)  {
                            Text(nft.meta.displayName ?? "").font(.title3)
                                .foregroundColor(Color.white)
                                .fontWeight(.bold)
                                .frame(maxWidth:1500, alignment:.leading)
                            if nft.meta_full != nil {
                                if(self.richText.description.isEmpty) {
                                    Text(nft.meta_full?["description"].stringValue ?? "")
                                        .foregroundColor(Color.white)
                                        .padding(.top)
                                        .frame(maxWidth:1200, alignment:.leading)
                                        .lineLimit(5)
                                }else {
                                    Text(self.richText)
                                        .foregroundColor(Color.white)
                                        .padding(.top)
                                        .frame(maxWidth:1200, alignment:.leading)
                                        .lineLimit(5)
                                }
                            }else{
                                Text(nft.meta.description ?? "")
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth:1200, alignment:.leading)
                            }
                            Spacer()
                        }
                    }
                    //.frame(height:400)
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($headerFocused)

                    VStack(spacing: 20){
                        if self.featuredMedia.count > 0 {
                            VStack(alignment: .leading, spacing: 10)  {
                                ScrollView(.horizontal) {
                                    LazyHStack(alignment: .top, spacing: 50) {
                                        /*
                                        ForEach(self.featuredMedia) {media in
                                            if (media.media_type ?? "" == "Video"){
                                                
                                                MediaView(media: media,
                                                          showPlayer: $showPlayer, playerItem: $playerItem,
                                                          playerImageOverlayUrl:$playerImageOverlayUrl,
                                                          playerTextOverlay:$playerTextOverlay,
                                                          display: MediaDisplay.video)
                                                          
                                            }else{
                                                MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem,
                                                          playerImageOverlayUrl:$playerImageOverlayUrl,
                                                          playerTextOverlay:$playerTextOverlay
                                                )
                                            }
                                        }
                                         */
                                        
                                        ForEach(self.featuredMedia) {media in
                                            /*if (media.isLive){
                                             MediaView2(media: media,
                                                          display: MediaDisplay.video)
                                            }else{*/
                                                MediaView2(mediaItem: media)
                                            //}
                                        }
                                        
                                        ForEach(self.redeemableFeatures) {redeemable in
                                            RedeemableCardView(redeemable:redeemable)
                                        }
                                        
                                    }
                                    .padding(20)
                                }
                                .introspectScrollView { view in
                                    view.clipsToBounds = false
                                }
                            }
                            .padding(.top)
                        }
                        
                        LazyVStack(alignment: .leading, spacing: 40)  {
                            ForEach(collections) { collection in
                                VStack(alignment: .leading, spacing: 10){
                                    Text(collection.name)
                                    MediaCollectionView(mediaCollection: collection, showPlayer: $showPlayer, playerItem: $playerItem,
                                                        playerImageOverlayUrl:$playerImageOverlayUrl,
                                                        playerTextOverlay:$playerTextOverlay
                                    )
                                }
                            }
                        }
                        .padding(20)
                    }
                }
                .padding(80)
                .focusSection()
            }
            .introspectScrollView { view in
                view.clipsToBounds = false
            }
            .fullScreenCover(isPresented: $showPlayer) {
                PlayerView(playerItem:self.$playerItem,
                           playerImageOverlayUrl:$playerImageOverlayUrl,
                           playerTextOverlay:$playerTextOverlay
                )
                .preferredColorScheme(colorScheme)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .onAppear(){
                //print("NFT FEATURES: \(self.nft.additional_media_sections?.featured_media)")
                
                if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
                    self.backgroundImageUrl = "https://picsum.photos/600/800"
                }else{
                    var imageLink: JSON? = nil
                    do {
                        //print("TV BG Image ", nft.background_image_tv)
                        if let bg = nft.background_image_tv {
                            if bg != "" {
                                self.backgroundImageUrl = bg
                            }
                        }
                        
                        //Use the NFT's background image
                        if let featured = nft.additional_media_sections?.featured_media {
                            if !featured.isEmpty {
                                imageLink = featured[0].background_image_tv
                                self.backgroundImageUrl = try fabric.getUrlFromLink(link: imageLink)
                            }
                        }

                    }catch{
                        print("Error getting image URL from link ", imageLink)
                    }
                }
                
               Task {
                   do{
                        if let redeemableOffers = nft.redeemable_offers {
                            //print("RedeemableOffers ", redeemableOffers)
                            if !redeemableOffers.isEmpty {
                                var redeemableFeatures: [RedeemableViewModel] = []
                                for redeemable in redeemableOffers {
                                    var animationItem : AVPlayerItem? = nil
                                    if let animationLink = redeemable.animation?["sources"]["default"] {
                                        animationItem = try await MakePlayerItemFromLink(fabric: fabric, link: animationLink)
                                    }
                                    let imageUrl = try fabric.getUrlFromLink(link: redeemable.image)
                                    let isRedeemed = true //TODO: get the status
                                    
                                    let redeem = RedeemableViewModel(id:redeemable.id,
                                                                     expiresAt: redeemable.expires_at ?? "",
                                                                     name: redeemable.name ?? "",
                                                                     animationPlayerItem: animationItem,
                                                                     availableAt: redeemable.available_at ?? "",
                                                                     isRedeemed: isRedeemed,
                                                                     imageUrl: imageUrl)

                                    redeemableFeatures.append(redeem)
                                }
                                self.redeemableFeatures = redeemableFeatures
                            }
                        }
                   }catch{
                       print("Error getting redemption animation ", error)
                   }
                   
                   /*
                   var featureViewModels: [MediaItemViewModel] = []
                   for feature in self.featuredMedia {
                       do {
                           try await featureViewModels.append(MediaItemViewModel.create(fabric:fabric, mediaItem:feature))
                       }catch{
                           print("Error creating MediaItemViewModel",error)
                       }
                   }
                   self.featureViewModels = featureViewModels
                   print("featureViewModels ", featureViewModels)
                    */
                }
            }
        }
        .background(Color.mainBackground)
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .ignoresSafeArea()
        .focusSection()
    }
}



struct NFTDetail: View {
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @State var nft : NFTModel
    @State var featuredMedia: [MediaItem] = []
    @State var collections: [MediaCollection] = []
    @State var richText: AttributedString = ""
    
    var body: some View {
        VStack{
            NFTDetailView(nft:$nft, featuredMedia: $featuredMedia, collections:$collections, richText: $richText)
                .environmentObject(fabric)
        }
        .background(Color.secondaryBackground)
        .task(){
            //print("NFT additional_media_sections: \(self.nft)")
            
            if let additions = nft.additional_media_sections {
                self.featuredMedia = additions.featured_media
                
                var collections: [MediaCollection] = []
                for section in additions.sections {
                    for collection in section.collections {
                        collections.append(collection)
                    }
                }
                
                self.collections = collections
                //print("FEATURED: ",featuredMedia)
            }
            
            let data = Data(nft.meta_full?["description_rich_text"].stringValue.utf8 ?? "".utf8)
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSUTF8StringEncoding], documentAttributes: nil) {
                self.richText = AttributedString(attributedString)
                self.richText.foregroundColor = .white
                self.richText.font = .body
            }

        }
    }
    
}

struct NFTDetail_Previews: PreviewProvider {
    static var previews: some View {
        NFTDetail(nft: test_NFTs[0])
                .listRowInsets(EdgeInsets())
    }
}
