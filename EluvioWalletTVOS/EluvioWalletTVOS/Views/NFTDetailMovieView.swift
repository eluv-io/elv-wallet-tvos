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
    @EnvironmentObject var viewState: ViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @Namespace var SeriesDetailView
    @EnvironmentObject var eluvio: EluvioAPI
    @Environment(\.openURL) private var openURL

    var seriesMediaItem : MediaItemViewModel
    
    var backLink: String = ""
    var backLinkIcon: String = ""
    
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
    @State private var showProgress = true
    
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
        ScrollView{
            VStack(alignment:.leading){
                HStack(alignment:.top) {
                    WebImage(url: URL(string: seriesMediaItem.titleLogo))
                        .resizable()
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fit)
                        .frame(width:600, height:280, alignment: .leading)
                        .padding(.bottom, 20)
                    
                    Spacer()
                    if (backLink != ""){
                        BackButton(buttonIcon:backLinkIcon,
                                   action: {
                            debugPrint("BackButton link: ", backLink)
                            debugPrint("BackButton link Icon: ", backLinkIcon)
                            if let url = URL(string: backLink) {
                                openURL(url) { accepted in
                                    print(accepted ? "Success" : "Failure")
                                    if (!accepted){
                                        print("Could not open URL ", backLink)
                                    }else{
                                        self.presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                        }
                        )
                    }
                }
                .focusSection()
                
                Button{} label: {
                    VStack(alignment: .leading, spacing: 40)  {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 10)  {
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
                .prefersDefaultFocus(in: SeriesDetailView)
                
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
                        .scrollClipDisabled()
                    }
                    .padding(.top)
                }
            }
            .opacity(showProgress ? 0.0 : 1.0)
            .padding(80)
            .focusSection()
            .scrollClipDisabled()
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .background(
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                if (seriesMediaItem.backgroundImage.hasPrefix("http")){
                    WebImage(url: URL(string: seriesMediaItem.backgroundImage))
                        .resizable()
                        .indicator(.activity) // Activity Indicator
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth:.infinity, maxHeight:.infinity)
                        .frame(alignment: .topLeading)
                        .clipped()
                        .opacity(showProgress ? 0.0 : 1.0)
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
                .edgesIgnoringSafeArea(.all)
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear(){
            self.showProgress = true
            Task {
                try? await Task.sleep(nanoseconds: 1500000000)
                if self.showProgress {
                    await MainActor.run {
                        self.showProgress = false
                    }
                }
            }
            
            if let nft = seriesMediaItem.nft {
                var featured : [MediaItem] = []
                if let additions = nft.additional_media_sections {
                    for var feature in additions.featured_media {
                        //Need to add nft since we only added the nft to one level of the media item. This is the second level
                        feature.nft = nft
                        featured.append(feature)
                        //debugPrint("feature name ", feature.name)
                        //debugPrint("feature nft ", feature.nft?.contract_name)
                    }
                    
                    self.featuredMedia = featured
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
                                    let redeem = try await RedeemableViewModel.create(fabric:eluvio.fabric, redeemable:redeemable, nft:nft)
                                    if (redeem.shouldDisplay(currentUserAddress: try eluvio.fabric.getAccountAddress())){
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
                            }
                        }
                    }
                }
                
            }
            
        }
    }
}
