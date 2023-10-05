//
//  NFTDetailMovieView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-10-04.
//

import SwiftUI
import SwiftyJSON
import AVKit
import SDWebImageSwiftUI

struct NFTDetailMovieView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @Namespace var SeriesDetailView
    @EnvironmentObject var fabric: Fabric
    var seriesMediaItem : MediaItemViewModel

    var subtitle : String {
        return seriesMediaItem.subtitle1
    }
    
    var release : String  {
        return seriesMediaItem.getTag(key:"Release Date")
    }
    
    var rating : String {
        return seriesMediaItem.getTag(key:"Rating")
    }
    
    var style : String {
        return seriesMediaItem.getTag(key:"Style")
    }
    
    @FocusState var isFocused

    @FocusState private var headerFocused: Bool
    
    @State var featuredMedia: [MediaItem] = []
    @State var redeemableFeatures: [RedeemableViewModel] = []

    @State private var isLoaded = false
    
    private var sections: [MediaSection] {
        if let additionalMedia = seriesMediaItem.nft?.additional_media_sections {
            return additionalMedia.sections
        }
        
        return []
    }
    
    private var seriesInfo: [(String,String)]{
        var info: [(String,String)] = []
        
        let director = seriesMediaItem.getTag(key:"Director")
        if !director.isEmpty {
            info.append(("Director:",director))
        }
        
        let writers = seriesMediaItem.getTag(key:"Writers")
        if !writers.isEmpty{
            info.append(("Writers:",writers))
        }
        
        let producer = seriesMediaItem.getTag(key:"Producer")
        if !producer.isEmpty{
            info.append(("Producer:",producer))
        }
        
        let language = seriesMediaItem.getTag(key:"Language")
        if !language.isEmpty{
            info.append(("Languages:",language))
        }
        
        let cast = seriesMediaItem.getTag(key:"Cast")
        if !cast.isEmpty{
            info.append(("Cast:",cast))
        }
        
        let stars = seriesMediaItem.getTag(key:"Stars")
        if !stars.isEmpty{
            info.append(("Stars:",stars))
        }
        
        return info
    }
    
    var body: some View {
        if !isLoaded {
            Color.black
                .frame(maxWidth:.infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .onAppear(){
                    self.isLoaded = false
                    
                    if let nft = seriesMediaItem.nft {
                        if let additions = nft.additional_media_sections {
                            self.featuredMedia = additions.featured_media
                        }
                    }
                    
                    debugPrint("Featured number" , self.featuredMedia.count)
                    
                    Task{
                        
                        if let nft = seriesMediaItem.nft {
                            if let redeemableOffers = nft.redeemable_offers {
                                //debugPrint("RedeemableOffers ", redeemableOffers)
                                if !redeemableOffers.isEmpty {
                                    var redeemableFeatures: [RedeemableViewModel] = []
                                    for redeemable in redeemableOffers {
                                        do{
                                            let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                            if (redeem.shouldDisplay(currentUserAddress: try fabric.getAccountAddress())){
                                                redeemableFeatures.append(redeem)
                                                //debugPrint("Redeemable should display!")
                                            }else{
                                                //debugPrint("Redeemable should NOT display")
                                            }
                                        }catch{
                                            print("Error processing redemption ", error)
                                        }
                                    }
                                    await MainActor.run {
                                        self.redeemableFeatures = redeemableFeatures
                                        debugPrint("redeemableFeatures number" , self.redeemableFeatures.count)
                                        self.isLoaded = true
                                    }
                                }
                            }
                        }
                        
                        await MainActor.run {
                            self.isLoaded = true
                        }
                    }
                }
        }else {
            ScrollView{
                VStack(alignment:.leading){
                    Button{} label: {
                        VStack(alignment: .leading, spacing: 40)  {
                            WebImage(url: URL(string: seriesMediaItem.titleLogo))
                                .resizable()
                                .transition(.fade(duration: 0.5))
                                .aspectRatio(contentMode: .fit)
                                .frame(width:600, height:280, alignment: .leading)
                                .padding(.bottom, 20)
                            
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 10)  {
                                    /*
                                    Text(subtitle)
                                        .font(.small)
                                        .foregroundColor(Color.gray)
                                        .frame(maxWidth:650, alignment:.leading)
                                        .lineLimit(1)
*/
                                    HStack (spacing:20) {
                                        if (rating != ""){
                                            Text(rating)
                                                .font(.smallBold)
                                                .foregroundColor(Color.white)
                                                .lineLimit(1)
                                            
                                        }
                                        if (release != ""){
                                            Text(release)
                                                .font(.smallBold)
                                                .foregroundColor(Color.white)
                                                .lineLimit(1)
                                            
                                        }
                                        if (style != ""){
                                            Text(style)
                                                .font(.smallBold)
                                                .foregroundColor(Color.white)
                                                .lineLimit(1)
                                            
                                        }
                                        Spacer()
                                    }
                                    .frame(maxWidth:900, alignment:.leading)
                                    
                                    Text(seriesMediaItem.description_text)
                                        .foregroundColor(Color.white)
                                        .font(.small)
                                        .frame(maxWidth:650, alignment:.leading)
                                        .lineLimit(5)
                                }
                                
                                Spacer()
                                    .frame(width: 250)
                                
                                Grid(alignment: .topLeading,
                                     horizontalSpacing: 10, verticalSpacing: 1) {
                                    ForEach(seriesInfo, id:\.0) { item in
                                        GridRow(){
                                            Text("\(item.0)")
                                                .font(.small)
                                                .foregroundColor(Color.white)
                                            Text("\(item.1)")
                                                .font(.small)
                                                .foregroundColor(Color.white)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($headerFocused)
                    .focusSection()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10)  {
                            ScrollView(.horizontal) {
                                HStack(alignment: .top, spacing: 50) {
                                    ForEach(self.featuredMedia) {media in
                                        MediaView2(mediaItem: media, showSharing:true)
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
                }
                .padding(80)
                .focusSection()
                .introspectScrollView { view in
                    view.clipsToBounds = false
                }
            }
            .frame(maxWidth:.infinity, maxHeight:.infinity)
            .background(
                Group {
                    if (seriesMediaItem.backgroundImage.hasPrefix("http")){
                        WebImage(url: URL(string: seriesMediaItem.backgroundImage))
                            .resizable()
                            .indicator(.activity) // Activity Indicator
                            .transition(.fade(duration: 0.5))
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth:.infinity, maxHeight:.infinity)
                            .frame(alignment: .topLeading)
                            .clipped()
                    }else if(seriesMediaItem.backgroundImage != "") {
                        Image(seriesMediaItem.backgroundImage)
                            .resizable()
                            .transition(.fade(duration: 0.5))
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth:.infinity, maxHeight:.infinity)
                            .frame(alignment: .topLeading)
                            .clipped()
                    }
                }
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}
