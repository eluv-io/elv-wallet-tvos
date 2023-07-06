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
    @State var showDetails = false
    @State var searchText = ""
    var title = ""
    @Binding var nft: NFTModel
    @State var featuredMedia: [MediaItem] = []
    @State var collections: [MediaCollection] = []
    @State var richText : AttributedString = ""
    @State var description = ""
    @FocusState var isFocused
    @State var backgroundImageUrl : String = ""
    @FocusState private var headerFocused: Bool
    @FocusState private var detailsButtonFocused: Bool
    
    @State var redeemableFeatures: [RedeemableViewModel] = []
    @State var localizedFeatures: [MediaItem] = []
    @State var localizedRedeemables: [RedeemableViewModel] = []
    
    private var sections: [MediaSection] {
        if let additionalMedia = nft.additional_media_sections {
            return additionalMedia.sections
        }
        
        return []
    }
    
    private var preferredLocation:String {
        fabric.profile.profileData.preferredLocation ?? ""
    }
    
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
                            
                            if (description != "") {
                                Text(description)
                                    .foregroundColor(Color.white)
                                    .padding(.top)
                                    .frame(maxWidth:1200, alignment:.leading)
                                    .lineLimit(3)
                            }else{
                               Text(self.richText)
                                    .foregroundColor(Color.white)
                                    .padding(.top)
                                    .frame(maxWidth:1200, alignment:.leading)
                                    .lineLimit(3)
                            }
                            

                            Spacer()
                        }
                    }
                    //.frame(height:400)
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($headerFocused)
                    
                    Button(action: {
                        self.showDetails = true
                    }){
                        HStack(spacing:10){
                            Image(systemName: "eye")
                            Text("View More").font(.small)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .overlay(
                            detailsButtonFocused ?
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.highlight, lineWidth: 4)
                            : nil
                        )
                        
                    }
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($detailsButtonFocused)
                    
/*
                    if self.localizedRedeemables.count > 0 || self.localizedFeatures.count > 0{
                        VStack(alignment: .leading, spacing: 10)  {
                            ScrollView(.horizontal) {
                                LazyHStack(alignment: .top, spacing: 50) {
                                    
                                    ForEach(self.localizedFeatures) {media in
                                        if (media.isLive){
                                            MediaView2(mediaItem: media,
                                                       display: MediaDisplay.video)
                                        }else{
                                            MediaView2(mediaItem: media)
                                        }
                                    }
                                    
                                    ForEach(self.localizedRedeemables) {redeemable in
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
*/
                    /*
                    VStack(spacing: 40){
                        if self.featuredMedia.count > 0 {
                            VStack(alignment: .leading, spacing: 10)  {
                                ScrollView(.horizontal) {
                                    LazyHStack(alignment: .top, spacing: 50) {
                                        
                                        ForEach(self.featuredMedia) {media in
                                            if (!preferredLocation.isEmpty) {
                                                if media.location.lowercased() != preferredLocation.lowercased() {
                                                    if (media.isLive){
                                                        MediaView2(mediaItem: media,
                                                                   display: MediaDisplay.video)
                                                    }else{
                                                        MediaView2(mediaItem: media)
                                                    }
                                                }
                                            }else{
                                                if (media.isLive){
                                                    MediaView2(mediaItem: media,
                                                               display: MediaDisplay.video)
                                                }else{
                                                    MediaView2(mediaItem: media)
                                                }
                                            }
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
                        */
                    
                    //Just features for initial release
                    VStack(spacing: 40){
                        if self.featuredMedia.count > 0 {
                            VStack(alignment: .leading, spacing: 10)  {
                                ScrollView(.horizontal) {
                                    LazyHStack(alignment: .top, spacing: 50) {
                                        ForEach(self.featuredMedia) {media in
                                            if (media.isLive){
                                                MediaView2(mediaItem: media,
                                                           display: MediaDisplay.video)
                                            }else{
                                                MediaView2(mediaItem: media)
                                            }
                                        
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

                        if(!sections.isEmpty){
                            ForEach(sections) { section in
                                VStack(alignment: .leading, spacing: 20){
                                    Text(section.name).font(.rowTitle).foregroundColor(Color.white)
                                    ForEach(section.collections) { collection in
                                        if(!collection.media.isEmpty){
                                            VStack(alignment: .leading, spacing: 10){
                                                Text(collection.name).font(.rowSubtitle).foregroundColor(Color.white)
                                                MediaCollectionView(mediaCollection: collection)
                                            }
                                            .focusSection()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(80)
                .focusSection()
            }
            .introspectScrollView { view in
                view.clipsToBounds = false
            }
            .onAppear(){
                //print("NFT FEATURES: \(self.nft.additional_media_sections?.featured_media)")

                Task {
                    
                    if let redeemableOffers = nft.redeemable_offers {
                        //print("RedeemableOffers ", redeemableOffers)
                        if !redeemableOffers.isEmpty {
                            var redeemableFeatures: [RedeemableViewModel] = []
                            var localizedRedeemables : [RedeemableViewModel] = []
                            for redeemable in redeemableOffers {
                                do{
                                    if (!preferredLocation.isEmpty) {
                                        
                                        if redeemable.location.lowercased() == preferredLocation.lowercased(){
                                            //Expensive operation
                                            let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                            localizedRedeemables.append(redeem)
                                        }
                                        
                                        if redeemable.location == "" {
                                            //Expensive operation
                                            let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                            redeemableFeatures.append(redeem)
                                        }
                                    }else{
                                        //Expensive operation
                                        let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                        redeemableFeatures.append(redeem)
                                    }
                                }catch{
                                    print("Error processing redemption ", error)
                                }
                            }
                            self.redeemableFeatures = redeemableFeatures
                            self.localizedRedeemables = localizedRedeemables
                        }
                    }
                }
                
                Task{
                    if let additions = nft.additional_media_sections {
                        if (!preferredLocation.isEmpty) {
                            var features:[MediaItem] = []
                            var locals:[MediaItem] = []
                            
                            for feature in additions.featured_media {
                                if (feature.location == ""){
                                    features.append(feature)
                                }
                                
                                if (feature.location == preferredLocation){
                                    locals.append(feature)
                                }
                            }
                            self.featuredMedia = features
                            self.localizedFeatures = locals
                        }else{
                            self.featuredMedia = additions.featured_media
                        }
                        
                        var collections: [MediaCollection] = []
                        for section in additions.sections {
                            for collection in section.collections {
                                collections.append(collection)
                            }
                        }
                        
                        self.collections = collections
                        //print("Collections: ",collections)
                    }
                }
                
                Task {
                   let data = Data(nft.meta_full?["description_rich_text"].stringValue.utf8 ?? "".utf8)
                   if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSUTF8StringEncoding], documentAttributes: nil) {
                       self.richText = AttributedString(attributedString)
                       self.richText.foregroundColor = .white
                       self.richText.font = .body
                   }
                    
                   self.description = nft.meta_full?["short_description"].stringValue ?? ""
                   
                   if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
                       self.backgroundImageUrl = "https://picsum.photos/600/800"
                   }else{
                       var imageLink: JSON? = nil
                       do {
                           if (!localizedFeatures.isEmpty) {
                               imageLink = localizedFeatures[0].background_image_tv
                               self.backgroundImageUrl = try fabric.getUrlFromLink(link: imageLink)
                           }
                           
                           if self.backgroundImageUrl == "" {
                               if let bg = nft.background_image_tv {
                                   if bg != "" {
                                       self.backgroundImageUrl = bg
                                   }
                               }else{
                                   
                                   //Use the NFT's background image
                                   if let featured = nft.additional_media_sections?.featured_media {
                                       if !featured.isEmpty {
                                           imageLink = featured[0].background_image_tv
                                           self.backgroundImageUrl = try fabric.getUrlFromLink(link: imageLink)
                                       }
                                   }
                               }
                           }

                       }catch{
                           print("Error getting background image:", error)
                       }
                   }
                }
            }
        }
        .background(Color.mainBackground)
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .ignoresSafeArea()
        .focusSection()
        .fullScreenCover(isPresented: $showDetails) {
            NFTXRayView(nft: nft, richText:self.richText)
        }
    }
}


struct NFTXRayView: View {
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @State var nft : NFTModel
    @State var richText: AttributedString = ""
    
    var body: some View {
        ZStack{
            VStack{
                ScrollView{
                    HStack(alignment:.top, spacing:100){
                        Spacer()
                        WebImage(url:URL(string:nft.meta.image ?? ""))
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFit()
                            .frame(width:400)
                        
                        VStack(alignment: .leading, spacing: 30) {
                            VStack(alignment:.leading, spacing:10){
                                Text(nft.meta.displayName ?? "").font(.title3)
                                    .foregroundColor(.white)
                                
                                HStack(spacing:10){
                                    Text(nft.meta.editionName ?? "")
                                    if (nft.token_id_str != nil){
                                        Text("#" + nft.token_id_str!)
                                    }
                                }
                                .font(.rowSubtitle)
                                .italic(true)
                            }
                            
                            VStack(alignment: .leading, spacing: 20){
                                Text(richText)
                                    .padding(.bottom,20)
                            }
                        }
                        Spacer()
                    }
                    .padding(50)
                    .padding(.top, 100)

                }
            }
            .ignoresSafeArea()
            .frame( maxWidth: .infinity, maxHeight:.infinity)
            .background(Color.black.opacity(0.5))
        }
        .background(.thinMaterial)
    }
    
}


struct NFTDetail: View {
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @State var nft : NFTModel
    
    var body: some View {
        VStack{
            NFTDetailView(nft:$nft)
                .environmentObject(fabric)
        }
        .background(Color.secondaryBackground)
    }
    
}

struct NFTDetail_Previews: PreviewProvider {
    static var previews: some View {
        NFTDetail(nft: test_NFTs[0])
                .listRowInsets(EdgeInsets())
    }
}
