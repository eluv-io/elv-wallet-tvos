//
//  SeriesDetail.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-06-26.
//

import SwiftUI
import SwiftyJSON
import AVKit
import SDWebImageSwiftUI

struct SeriesDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @Namespace var SeriesDetailView
    @EnvironmentObject var fabric: Fabric
    @State var seriesMediaItem = MediaItemViewModel()
    var subtitle : String {
        return seriesMediaItem.subtitle1
    }
    var description : AttributedString {
        return seriesMediaItem.description.html2Attributed(font:.small)
    }
    @FocusState var isFocused

    @FocusState private var headerFocused: Bool
    @State var matchedRedeemables: [RedeemableViewModel] = []
    
    var recentMedia: MediaItem {
        if section.collections.isEmpty || section.collections[0].media.isEmpty{
            return MediaItem()
        }
        
        return section.collections[0].media[0]
    }
    
    private var preferredLocation:String {
        fabric.profile.profileData.preferredLocation ?? ""
    }
    
    private var section: MediaSection {
        return seriesMediaItem.mediaSection ?? MediaSection()
    }
    
    private var seriesInfo: [(String,String)]{
        var info: [(String,String)] = []
        
        let director = seriesMediaItem.getTag(key:"Director")
        if !director.isEmpty {
            info.append(("Director:",director))
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
            info.append(("Cast:",language))
        }
        
        let rating = seriesMediaItem.getTag(key:"Rating")
        if !rating.isEmpty{
            info.append(("Rating:",rating))
        }
        
        let release = seriesMediaItem.getTag(key:"Release Date")
        if !release.isEmpty{
            info.append(("Release Date:",release))
        }
        
        let style = seriesMediaItem.getTag(key:"Style")
        if !style.isEmpty{
            info.append(("Style:",style))
        }
        
        return info
    }
    
    var body: some View {
        ZStack(alignment:.topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Button{} label: {
                            VStack(alignment: .leading)  {
                                WebImage(url: URL(string: seriesMediaItem.titleLogo))
                                    .resizable()
                                    .indicator(.activity) // Activity Indicator
                                    .transition(.fade(duration: 0.5))
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:700, height:300, alignment: .center)

                                HStack(alignment: .top, spacing:0) {
                                    VStack(alignment: .leading, spacing: 10)  {
                                        Text(subtitle)
                                            .font(.smallBold)
                                            .foregroundColor(Color.white)
                                            .frame(maxWidth:800, alignment:.leading)
                                            .lineLimit(1)
                                        Text(description)
                                            .foregroundColor(Color.white)
                                            .frame(maxWidth:800, alignment:.leading)
                                            .lineLimit(4)
                                    }
                                    
                                    Spacer()
                                    
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
                            }
                    }
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($headerFocused)

                    VStack(alignment: .leading, spacing: 10)  {
                        ScrollView(.horizontal) {
                            LazyHStack(alignment: .top, spacing: 50) {
                                VStack(alignment:.leading, spacing:10){
                                    MediaView2(mediaItem: recentMedia,
                                           showFocusName: false,
                                           display: MediaDisplay.video)
                                    Text(recentMedia.name).font(.rowSubtitle).foregroundColor(Color.white)
                                        .frame(maxWidth: 500)
                                }

                                ForEach(matchedRedeemables) {redeemable in
                                    VStack(alignment:.leading, spacing:10){
                                        RedeemableCardView(redeemable:redeemable)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .introspectScrollView { view in
                            view.clipsToBounds = false
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 20){
                        Text(section.name).font(.rowTitle).foregroundColor(Color.white)
                        ForEach(section.collections) { collection in
                            if(!collection.media.isEmpty){
                                VStack(alignment: .leading, spacing: 10){
                                    Text(collection.name).font(.rowSubtitle).foregroundColor(Color.white)
                                    MediaCollectionView(mediaCollection: collection, nameBelow:true)
                                }
                                .focusSection()
                            }
                        }
                    }
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
        .onAppear(){
            //print("LOGO: ",seriesMediaItem.titleLogo)
            Task{
                if let nft = seriesMediaItem.nft {
                    if let redeemableOffers = nft.redeemable_offers {
                        if !redeemableOffers.isEmpty {
                            var redeemableFeatures: [RedeemableViewModel] = []
                            for redeemable in redeemableOffers {
                                do{
                                    //Expensive operation
                                    if redeemable.contentTag.isEmpty || redeemable.contentTag == seriesMediaItem.contentTag {
                                        let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                        redeemableFeatures.append(redeem)
                                    }
                                        
                                }catch{
                                    print("Error processing redemption ", error)
                                }
                            }
                            
                            self.matchedRedeemables = redeemableFeatures
                        }
                    }
                }
            }
        }
        .background(Color.mainBackground)
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .ignoresSafeArea()
        .focusSection()
    }
}

struct SeriesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SeriesDetailView()
                .listRowInsets(EdgeInsets())
    }
}
