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
import Combine
//import SwiftUIIntrospect

struct NFTDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @Namespace var nftDetails
    @EnvironmentObject var fabric: Fabric
    @State var showDetails = false
    @State var searchText = ""
    var title = ""
    var nft: NFTModel
    @State var featuredMedia: [MediaItem] = []
    @State var collections: [MediaCollection] = []
    @State var richText : AttributedString = ""
    var description : String {
        if let desc = nft.meta_full?["short_description"].stringValue {
            return desc
        }
        
        return ""
    }
    @FocusState var isFocused
    @State var backgroundImageUrl : String = ""
    @FocusState private var headerFocused: Bool
    @FocusState private var detailsButtonFocused: Bool
    
    @State var redeemableFeatures: [RedeemableViewModel] = []
    @State var localizedFeatures: [MediaItem] = []
    @State var localizedRedeemables: [RedeemableViewModel] = []
    @State private var cancellable: AnyCancellable? = nil
    
    @State private var showProgress = true
    
    private var sections: [MediaSection] {
        if let additionalMedia = nft.additional_media_sections {
            return additionalMedia.sections
        }
        
        return []
    }
    
    private var preferredLocation:String {
        if IsDemoMode() {
            return fabric.profile.profileData.preferredLocation ?? ""
        }else{
            return ""
        }
    }
    
    var body: some View {
            ZStack(alignment:.topLeading) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
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
                                            .lineLimit(10)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(NonSelectionButtonStyle())
                            .focused($headerFocused)

                            //Just features for initial release
                            VStack(spacing: 40){
                                VStack(alignment: .leading, spacing: 10)  {
                                    ScrollView(.horizontal) {
                                        HStack(alignment: .top, spacing: 50) {
                                            
                                            ForEach(self.localizedFeatures) {media in
                                                MediaView2(mediaItem: media)
                                            }
                                            
                                            ForEach(self.featuredMedia) {media in
                                                MediaView2(mediaItem: media)
                                            }
                                            
                                            ForEach(self.localizedRedeemables) {redeemable in
                                                RedeemableCardView(redeemable:redeemable)
                                            }

                                            ForEach(redeemableFeatures) {redeemable in
                                                RedeemableCardView(redeemable:redeemable)
                                            }
                                            
                                        }
                                        .padding(20)
                                    }
                                    .scrollClipDisabled()
                                }
                                .padding(.top)
                                
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
                            .padding(.bottom, 200) //This fixes bottom row being cut off
                        }
                        .padding(80)
                    }
                    .opacity(showProgress ? 0.0 : 1.0)
                    .scrollClipDisabled()
            }
            .frame(maxWidth:.infinity, maxHeight:.infinity)
            .background(
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    if (self.backgroundImageUrl.hasPrefix("http")){
                        WebImage(url: URL(string: self.backgroundImageUrl))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth:.infinity, maxHeight:.infinity)
                            .frame(alignment: .topLeading)
                            .clipped()
                            .opacity(showProgress ? 0.0 : 1.0)
                    }else if(self.backgroundImageUrl != "") {
                        Image(self.backgroundImageUrl)
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
            .fullScreenCover(isPresented: $showDetails) {
                NFTXRayView(nft: nft, richText:self.richText)
            }
            .onAppear(){
                debugPrint("NFTDetailViewDemo onAppear", nft.contract_name)
                self.cancellable = fabric.$library.sink { val in
                    update()
                }
            }
    }
        
    func update(){
        debugPrint("preferredLocation ", preferredLocation)
        self.showProgress = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1500000000)
            if self.showProgress {
                await MainActor.run {
                    self.showProgress = false
                }
            }
        }

        Task {
            if let redeemableOffers = nft.redeemable_offers {
                debugPrint("RedeemableOffers ", redeemableOffers)
                if !redeemableOffers.isEmpty {
                    var redeemableFeatures: [RedeemableViewModel] = []
                    var localizedRedeemables : [RedeemableViewModel] = []
                    for redeemable in redeemableOffers {
                        do{
                            if (!preferredLocation.isEmpty) {
                                debugPrint("Preferred Location ", preferredLocation)
                                debugPrint("Redeemable Location ", redeemable.location)
                                if redeemable.location.lowercased() == preferredLocation.lowercased(){
                                    //Expensive operation
                                    let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                    if (redeem.shouldDisplay(currentUserAddress: try fabric.getAccountAddress())){
                                        debugPrint("Redeemable should display!")
                                        localizedRedeemables.append(redeem)
                                    }else{
                                        debugPrint("Redeemable should NOT display")
                                    }
                                }
                                
                                if redeemable.location == "" {
                                    debugPrint("redeemable location is empty")
                                    //Expensive operation
                                    let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                    if (redeem.shouldDisplay(currentUserAddress: try fabric.getAccountAddress())){
                                        debugPrint("Redeemable should display!")
                                        redeemableFeatures.append(redeem)
                                    }else{
                                        debugPrint("Redeemable should NOT display")
                                    }
                                }
                            }else{
                                debugPrint("No profile location ")
                                //Expensive operation
                                let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                if (redeem.shouldDisplay(currentUserAddress: try fabric.getAccountAddress())){
                                    redeemableFeatures.append(redeem)
                                    debugPrint("Redeemable should display!")
                                }else{
                                    debugPrint("Redeemable should NOT display")
                                }
                                debugPrint("Redeemable isRedeemer \(redeem.name)", redeem.isRedeemer(address:try fabric.getAccountAddress()))
                                debugPrint(" redeemable status \(redeem.name)", redeem.status)
                                debugPrint(" redeemable expired? \(redeem.name)", redeem.isExpired)
                                debugPrint(" redeemable expiry time? \(redeem.name)", redeem.expiresAtFormatted)
                                
                            }
                        }catch{
                            print("Error processing redemption ", error)
                        }
                    }
                    await MainActor.run {
                        self.redeemableFeatures = redeemableFeatures
                        self.localizedRedeemables = localizedRedeemables
                    }
                }
            }
            
            if let additions = nft.additional_media_sections {
                if (!preferredLocation.isEmpty) {
                    var features:[MediaItem] = []
                    var locals:[MediaItem] = []
                    
                    for feature in additions.featured_media {
                        debugPrint("feature name ", feature.name)
                        debugPrint("feature nft ", feature.nft)
                        if (feature.location == ""){
                            features.append(feature)
                            debugPrint("feature appended with no location")
                        }else if (feature.location == preferredLocation){
                            locals.append(feature)
                            debugPrint("feature appended with location", feature.location)
                        }
                    }
                    await MainActor.run {
                        self.featuredMedia = features
                        self.localizedFeatures = locals
                    }
                }else{
                    for feature in additions.featured_media {
                        debugPrint("No location feature name ", feature.name)
                        debugPrint("No location feature nft ", feature.nft)
                    }
                    
                    await MainActor.run {
                        self.featuredMedia = additions.featured_media
                    }
                }
                
                var collections: [MediaCollection] = []
                for section in additions.sections {
                    for collection in section.collections {
                        collections.append(collection)
                    }
                }
                
                await MainActor.run {
                    self.collections = collections
                }
                //print("Collections: ",collections)
            }
            
            var descRichText = nft.meta_full?["description_rich_text"].stringValue ?? ""
            if (descRichText == ""){
                descRichText = nft.meta_full?["description"].stringValue ?? ""
            }
            
            if (descRichText != ""){
                let data = Data(descRichText.utf8)
                if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSUTF8StringEncoding], documentAttributes: nil) {
                    self.richText = AttributedString(attributedString)
                    self.richText.foregroundColor = .white
                    self.richText.font = .body
                }
            }
        }
        
        if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
            self.backgroundImageUrl = "https://picsum.photos/600/800"
        }else{
            var imageLink: JSON? = nil
            var imageUrl = ""
            do {
                if (!localizedFeatures.isEmpty) {
                    debugPrint("local feature background Image: ", localizedFeatures[0].background_image_tv)
                    imageLink = localizedFeatures[0].background_image_tv
                    imageUrl = try fabric.getUrlFromLink(link: imageLink)
                    
                }
                
                if imageUrl == "" {
                    
                    if let imageLink = nft.meta_full?["background_image_tv"] {
                        if !imageLink.isEmpty {
                            do {
                                imageUrl  = try fabric.getUrlFromLink(link: imageLink)
                                debugPrint("NFT background Image TV: ", imageUrl )
                            }catch{}

                        }
                    }
                }
                
                if imageUrl == "" {
                    
                    if let imageLink = nft.meta_full?["background_image"] {
                        if !imageLink.isEmpty {
                            do {
                                imageUrl  = try fabric.getUrlFromLink(link: imageLink)
                                debugPrint("NFT background Image: ", imageUrl )
                            }catch{}

                        }
                    }
                }
                
                    
                    
                if imageUrl == "" {
                        
                    //Use the NFT's first feature's background image
                    if let featured = nft.additional_media_sections?.featured_media {
                        if !featured.isEmpty {
                            imageLink = featured[0].background_image_tv
                            imageUrl  = try fabric.getUrlFromLink(link: imageLink)
                            debugPrint("featured background Image: ", imageUrl )
                        }
                    }
                }
            
                
                self.backgroundImageUrl = imageUrl
            }catch{
                print("Error getting background image:", error)
            }
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
    var nft : NFTModel
    @State var feature = MediaItemViewModel()
    @State private var isLoaded: Bool = false
    
    var body: some View {
        Group {
            if isLoaded == true {
                if nft.isMovieLayout {
                    NFTDetailMovieView(seriesMediaItem: feature)
                }else {
                    NFTDetailView(nft:nft)
                        .environmentObject(fabric)
                }
            }else {
                ZStack{
                    Color.black.edgesIgnoringSafeArea(.all)
                    ProgressView()
                }
            }
        }
        .onAppear(){
            debugPrint("NFTDetail OnAppear")
            self.isLoaded = false
            
            Task {
                try? await Task.sleep(nanoseconds: 2000000000)
                if !self.isLoaded {
                    await MainActor.run {
                        self.isLoaded = true
                    }
                }
            }
            
            Task {
                var mediaItem = MediaItemViewModel()
                var ok = false;
                do{
                    //print("*** MediaView onChange")
                    if let media = nft.getFirstFeature {
                        mediaItem = try await MediaItemViewModel.create(fabric:fabric, mediaItem:media)
                        //print ("MediaView name ", media.name)
                        //debugPrint("MediaItem title: ", self.mediaItem?.name)
                        //debugPrint("display: ", display)
                        ok = true
                    }
                    
                }catch{
                    print("MediaView could not create MediaItemViewModel ", error)
                }
                
                await MainActor.run {
                    if ok {
                        self.feature = mediaItem
                    }
                    isLoaded = true
                }
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
