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

struct NFTDetailViewDemo: View {
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
    @State var description = ""
    @FocusState var isFocused
    @State var backgroundImageUrl : String = ""
    @FocusState private var headerFocused: Bool
    @FocusState private var detailsButtonFocused: Bool
    
    @State var redeemableFeatures: [RedeemableViewModel] = []
    @State var localizedFeatures: [MediaItem] = []
    @State var localizedRedeemables: [RedeemableViewModel] = []
    @State private var cancellable: AnyCancellable? = nil
    
    private var sections: [MediaSection] {
        if let additionalMedia = nft.additional_media_sections {
            return additionalMedia.sections
        }
        
        return []
    }
    
    private var preferredLocation:String {
        return fabric.profile.profileData.preferredLocation ?? ""
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
                                    .lineLimit(10)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($headerFocused)
                    
 
                    //Just features for initial release
                    LazyVStack(spacing: 40){
                        
                        if self.localizedRedeemables.count > 0 || self.localizedFeatures.count > 0{
                            VStack(alignment: .leading, spacing: 10)  {
                                ScrollView(.horizontal) {
                                    LazyHStack(alignment: .top, spacing: 50) {
                                        
                                        ForEach(self.localizedFeatures) {media in
                                            MediaView2(mediaItem: media)
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
                        }else{
                            if self.featuredMedia.count > 0 || self.redeemableFeatures.count > 0{
                                VStack(alignment: .leading, spacing: 10)  {
                                    ScrollView(.horizontal) {
                                        LazyHStack(alignment: .top, spacing: 50) {
                                            ForEach(self.featuredMedia) {media in
                                                MediaView2(mediaItem: media)
                                            }
                                            
                                            ForEach(redeemableFeatures) {redeemable in
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
                .focusSection()
            }
            .introspectScrollView { view in
                view.clipsToBounds = false
            }
            .onAppear(){
                debugPrint("NFTDetailViewDemo onAppear", nft.contract_name)
                self.cancellable = fabric.$library.sink { val in
                    update()
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
    func update(){
        debugPrint("preferredLocation ", preferredLocation)
        Task {
            if let redeemableOffers = nft.redeemable_offers {
                //debugPrint("RedeemableOffers ", redeemableOffers)
                if !redeemableOffers.isEmpty {
                    var redeemableFeatures: [RedeemableViewModel] = []
                    var localizedRedeemables : [RedeemableViewModel] = []
                    for redeemable in redeemableOffers {
                        do{
                            if (!preferredLocation.isEmpty) {
                                
                                if redeemable.location.lowercased() == preferredLocation.lowercased(){
                                    //Expensive operation
                                    let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                    if (redeem.shouldDisplay(currentUserAddress: try fabric.getAccountAddress())){
                                        localizedRedeemables.append(redeem)
                                    }
                                }
                                
                                if redeemable.location == "" {
                                    //Expensive operation
                                    let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                    if (redeem.shouldDisplay(currentUserAddress: try fabric.getAccountAddress())){
                                        redeemableFeatures.append(redeem)
                                    }
                                }
                            }else{
                                //Expensive operation
                                let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                                if (redeem.shouldDisplay(currentUserAddress: try fabric.getAccountAddress())){
                                    redeemableFeatures.append(redeem)
                                }
                                print("Appended redeemable isRedeemer \(redeem.name)", redeem.isRedeemer(address:try fabric.getAccountAddress()))
                                print("Appended redeemable status \(redeem.name)", redeem.status)
                                print("Appended redeemable expired? \(redeem.name)", redeem.isExpired)
                                print("Appended redeemable expiry time? \(redeem.name)", redeem.expiresAtFormatted)
                                
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
                    await MainActor.run {
                        self.featuredMedia = features
                        self.localizedFeatures = locals
                    }
                }else{
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
        }
        
        Task {
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
            
            await MainActor.run {
                self.description = nft.meta_full?["short_description"].stringValue ?? ""
            }
            
            //print("short_description ", nft.meta_full?["short_description"].stringValue)
            //print("description ", nft.meta_full?["description"].stringValue)
            //print("saved ", self.description)
            
            if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
                self.backgroundImageUrl = "https://picsum.photos/600/800"
            }else{
                var imageLink: JSON? = nil
                var imageUrl = ""
                do {
                    if (!localizedFeatures.isEmpty) {
                        imageLink = localizedFeatures[0].background_image_tv
                        imageUrl = try fabric.getUrlFromLink(link: imageLink)
                        
                    }
                    
                    if imageUrl == "" {
                        if let bg = nft.background_image_tv {
                            if bg != "" {
                                imageUrl = bg
                            }
                        }else{
                            
                            //Use the NFT's background image
                            if let featured = nft.additional_media_sections?.featured_media {
                                if !featured.isEmpty {
                                    imageLink = featured[0].background_image_tv
                                    imageUrl  = try fabric.getUrlFromLink(link: imageLink)
                                }
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.backgroundImageUrl = imageUrl
                    }
                    
                }catch{
                    print("Error getting background image:", error)
                }
            }
        }
    }
}

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
    @State var description = ""
    @FocusState var isFocused
    @State var backgroundImageUrl : String = ""
    @FocusState private var headerFocused: Bool
    @FocusState private var detailsButtonFocused: Bool
    
    @State var redeemableFeatures: [RedeemableViewModel] = []
    @State var localizedFeatures: [MediaItem] = []
    @State var localizedRedeemables: [RedeemableViewModel] = []
    @State private var cancellable: AnyCancellable? = nil
    
    private var sections: [MediaSection] {
        if let additionalMedia = nft.additional_media_sections {
            return additionalMedia.sections
        }
        
        return []
    }
    
    private var preferredLocation:String {
        return fabric.profile.profileData.preferredLocation ?? ""
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
                                    .lineLimit(10)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($headerFocused)
   
                    //Just features for initial release
                    LazyVStack(spacing: 40){
                        if self.featuredMedia.count > 0 || self.redeemableFeatures.count > 0{
                            VStack(alignment: .leading, spacing: 10)  {
                                ScrollView(.horizontal) {
                                    LazyHStack(alignment: .top, spacing: 50) {
                                        ForEach(self.featuredMedia) {media in
                                            MediaView2(mediaItem: media)
                                        }
                                        
                                        ForEach(redeemableFeatures) {redeemable in
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
                .focusSection()
            }
            .introspectScrollView { view in
                view.clipsToBounds = false
            }
            .onAppear(){
                self.cancellable = fabric.$library.sink { val in
                    update()
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
    func update(){
        Task {
            if let redeemableOffers = nft.redeemable_offers {
                debugPrint("RedeemableOffers ", redeemableOffers)
                if !redeemableOffers.isEmpty {
                    var redeemableFeatures: [RedeemableViewModel] = []
                    for redeemable in redeemableOffers {
                        do{
                            //Expensive operation
                            let redeem = try await RedeemableViewModel.create(fabric:fabric, redeemable:redeemable, nft:nft)
                            if (redeem.shouldDisplay(currentUserAddress: try fabric.getAccountAddress())){
                                redeemableFeatures.append(redeem)
                            }
                            debugPrint("Appended redeemable isRedeemer \(redeem.name)", redeem.isRedeemer(address:try fabric.getAccountAddress()))
                            debugPrint("Appended redeemable status \(redeem.name)", redeem.status)
                            debugPrint("Appended redeemable expired? \(redeem.name)", redeem.isExpired)
                            debugPrint("Appended redeemable expiry time? \(redeem.name)", redeem.expiresAtFormatted)
                        }catch{
                            print("Error processing redemption ", error)
                        }
                    }
                    await MainActor.run {
                        self.redeemableFeatures = redeemableFeatures
                    }
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
                    await MainActor.run {
                        self.featuredMedia = features
                        self.localizedFeatures = locals
                    }
                }else{
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
            }
        }
        
        Task {
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
            
            await MainActor.run {
                self.description = nft.meta_full?["short_description"].stringValue ?? ""
            }
            
            //print("short_description ", nft.meta_full?["short_description"].stringValue)
            //print("description ", nft.meta_full?["description"].stringValue)
            //print("saved ", self.description)
            
            if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
                self.backgroundImageUrl = "https://picsum.photos/600/800"
            }else{
                var imageLink: JSON? = nil
                var imageUrl = ""
                do {
                    if (!localizedFeatures.isEmpty) {
                        imageLink = localizedFeatures[0].background_image_tv
                        imageUrl = try fabric.getUrlFromLink(link: imageLink)
                        
                    }
                    
                    if imageUrl == "" {
                        if let bg = nft.background_image_tv {
                            if bg != "" {
                                imageUrl = bg
                            }
                        }else{
                            
                            //Use the NFT's background image
                            if let featured = nft.additional_media_sections?.featured_media {
                                if !featured.isEmpty {
                                    imageLink = featured[0].background_image_tv
                                    imageUrl  = try fabric.getUrlFromLink(link: imageLink)
                                }
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.backgroundImageUrl = imageUrl
                    }
                    
                }catch{
                    print("Error getting background image:", error)
                }
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
    
    var body: some View {
        VStack{
            if IsDemoMode() {
                NFTDetailViewDemo(nft:nft)
                    .environmentObject(fabric)
            }else{
                NFTDetailView(nft:nft)
                    .environmentObject(fabric)
            }
        }
        .background(Color.secondaryBackground)
        .onAppear(){
            debugPrint("NFTDetail onAppear", nft.contract_name)
        }
    }
    
}

struct NFTDetail_Previews: PreviewProvider {
    static var previews: some View {
        NFTDetail(nft: test_NFTs[0])
                .listRowInsets(EdgeInsets())
    }
}
