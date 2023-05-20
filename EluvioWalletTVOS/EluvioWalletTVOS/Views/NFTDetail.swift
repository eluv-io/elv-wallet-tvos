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
    
    
    var body: some View {
        ZStack(alignment:.topLeading) {
            WebImage(url: URL(string: self.backgroundImageUrl))
                .resizable()
                .indicator(.activity) // Activity Indicator
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth:.infinity)
                .frame(height: 500,  alignment: .topLeading)
                .clipped()
                .edgesIgnoringSafeArea(.all)
                //.padding(-50)
            
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 20)  {
                        Text(nft.meta.displayName).font(.title3)
                            .foregroundColor(Color.white)
                            .fontWeight(.bold)
                            .frame(maxWidth:1500, alignment:.leading)
                        /*HStack {
                         Text(nft.meta.editionName)
                         .font(.headline)
                         .foregroundColor(Color.white)
                         Text("# \(nft.token_id_str)")
                         .font(.headline)
                         .foregroundColor(Color.yellow)
                         }*/
                        if nft.meta_full != nil {
                            if(self.richText.description.isEmpty) {
                                Text(nft.meta_full?["description"].stringValue ?? "")
                                    .foregroundColor(Color.white)
                                    .padding(.top)
                                    .frame(maxWidth:1200, alignment:.leading)
                            }else {
                                Text(self.richText)
                                    .foregroundColor(Color.white)
                                    .padding(.top)
                                    .frame(maxWidth:1200, alignment:.leading)
                            }
                        }else{
                            Text(nft.meta.description)
                                .foregroundColor(Color.white)
                                .frame(maxWidth:1200, alignment:.leading)
                        }
                    }
                    .frame(height:400)
                    Spacer()
                    
                    ScrollView {
                    if self.featuredMedia.count > 0 {
                        VStack(alignment: .leading, spacing: 10)  {
                            /*if(!(self.nft.has_album ?? true)){
                                Text("FEATURED MEDIA")
                            }else{
                                Text("TRACKS")
                            }*/
                            ScrollView(.horizontal) {
                                LazyHStack(alignment: .top, spacing: 50) {
                                    ForEach(self.featuredMedia) {media in
                                        MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem,
                                                  playerImageOverlayUrl:$playerImageOverlayUrl,
                                                  playerTextOverlay:$playerTextOverlay
                                        )
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

                    
                    LazyVStack(alignment: .leading, spacing: 10)  {
                        ForEach(collections) { collection in
                            Text(collection.name)
                            MediaCollectionView(mediaCollection: collection, showPlayer: $showPlayer, playerItem: $playerItem,
                                                playerImageOverlayUrl:$playerImageOverlayUrl,
                                                playerTextOverlay:$playerTextOverlay
                            )
                        }
                    }
                }
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
                //print("Gallery Item: ", self.media)
                
                if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
                    self.backgroundImageUrl = "https://picsum.photos/600/800"
                }else{
                    var imageLink: JSON? = nil
                    do {
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
            }
        }
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
            if let additions = nft.additional_media_sections {
                self.featuredMedia = additions.featured_media
                
                var collections: [MediaCollection] = []
                for section in additions.sections {
                    for collection in section.collections {
                        collections.append(collection)
                    }
                }
                
                self.collections = collections
                print("FEATURED: ",featuredMedia)
            }
            
            let data = Data(nft.meta_full?["description_rich_text"].stringValue.utf8 ?? "".utf8)
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
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
