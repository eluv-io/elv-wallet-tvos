//
//  MediaView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-18.
//

import Foundation
import SwiftUI
import SwiftyJSON
import AVKit
import SDWebImageSwiftUI

enum MediaDisplay {case apps; case video; case feature; case books; case album; case property; case tile; case square}
/*
struct MediaCollectionView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @State var mediaCollection: MediaCollection
    var display: MediaDisplay = MediaDisplay.square
    @State var nameBelow = false
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 52) {
                ForEach(self.mediaCollection.media) {media in
                    VStack(alignment:.leading, spacing:10){
                        if (media.isLive || media.media_type == "Video"){
                            MediaView2(mediaItem: media,
                                       showFocusName: !nameBelow, display: MediaDisplay.video
                            )
                        }else{
                            MediaView2(mediaItem: media,
                                       showFocusName: !nameBelow, display: display
                            )
                        }
                        
                        //Move this to the MediaView2
                        if nameBelow == true {
                            Text(media.name).font(.rowSubtitle).foregroundColor(Color.white)
                                .frame(maxWidth: 500)
                        }
                    }
                }
            }
            .padding([.top,.bottom],20)
        }
        .scrollClipDisabled()
    }
}
 */
/*
func MakePlayerItemFromVersionHash(fabric: Fabric, versionHash: String, params: [JSON]? = [], offering: String = "default") async throws -> AVPlayerItem {
    let options = try await fabric.getOptions(versionHash: versionHash, offering: offering)
    return try MakePlayerItemFromOptionsJson(fabric: fabric, optionsJson: options, versionHash: versionHash, offering: offering)
}


func MakePlayerItem(fabric: Fabric, media: MediaItem?, offering: String = "default") async throws -> AVPlayerItem {
    
    return try await MakePlayerItemFromLink(fabric:fabric, link: media?.media_link?["sources"][offering], params: media?.parameters, offering: offering)
}

func MakePlayerItemFromLink(fabric: Fabric, link: JSON?, params: [JSON]? = [], offering: String = "default", hash: String = "") async throws -> AVPlayerItem {
    debugPrint("MakePlayerItemFromLink ", link)
    let options = try await fabric.getOptionsFromLink(link: link, params: params, offering: offering, hash:hash)
    debugPrint("options finished ", options)
    return try MakePlayerItemFromOptionsJson(fabric: fabric, optionsJson: options.optionsJson, versionHash: options.versionHash, offering: offering)
}

func MakePlayerItemFromOptionsJson(fabric: Fabric, optionsJson: JSON?, versionHash: String, offering: String = "default") throws -> AVPlayerItem {
    
    debugPrint("MakePlayerItemFromOptionsJson ", optionsJson)
    
    var hlsPlaylistUrl: String = ""
    
    guard let options = optionsJson else {
        throw RuntimeError("MakePlayerItemFromOptionsJson options is nil")
    }
    
    if options["hls-clear"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash, drm:"hls-clear", offering: offering)
        //print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else if options["hls-sample-aes"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash, drm:"hls-sample-aes", offering: offering)
        print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else if options["hls-fairplay"].exists() {
        let licenseServer = options["hls-fairplay"]["properties"]["license_servers"][0].stringValue
        
        if(licenseServer.isEmpty)
        {
            throw RuntimeError("Error getting licenseServer")
        }
        print("license_server \(licenseServer)")
        
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash, drm:"hls-fairplay", offering: offering)
        //print("Playlist URL \(hlsPlaylistUrl)")
        
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
        ContentKeyManager.shared.contentKeyDelegate.setDRM(licenseServer:licenseServer, authToken: fabric.fabricToken)
        return AVPlayerItem(asset: urlAsset)
        
    }else{
        throw RuntimeError("No available playback options \(options)")
    }
}
*/
/*
struct MediaView2: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @State var mediaItem: MediaItem?
    @State var showSharing: Bool = false
    @State private var media = MediaItemViewModel()
    @FocusState var isFocused
    @State var showGallery = false
    @State var gallery: [GalleryItem] = []
    @State var showQRView = false
    @State var qrUrl = "https://eluv.io"

    @State var showPlayer : Bool = false
    @State private var playerItem : AVPlayerItem?
    @State var playerImageOverlayUrl : String = ""
    @State var playerTextOverlay : String = ""
    @State var playerFinished = false
    @State var showFocusName = true
    @State var showError = false
    @State var errorMessage = ""
    @State var startTimeS = 0.0
    @State var mediaProgress: MediaProgress?
    var progressText: String {
        guard let progress = mediaProgress else {
            return ""
        }
        
        let left = progress.duration_s - progress.current_time_s
        let timeStr = left.asTimeString(style: .abbreviated)
        return "\(timeStr) left"
    }
    var progressValue: Double {
        guard let progress = mediaProgress else {
            return 0.0
        }
        
        if (progress.duration_s != 0) {
            return progress.current_time_s / progress.duration_s
        }
        
        return 0.0
    }
    
    @State var showImage = false
    var image: String {
        if self.media.posterImage != "" {
            return media.posterImage
        }
        
        return self.media.image
    }
    
    var display: MediaDisplay = MediaDisplay.square
    
    @State private var showSeriesView = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                debugPrint("Media Type: ", media.mediaType)
                
                if media.isReference == true{
                    showSeriesView = true
                    debugPrint("Media: ", media.isReference)
                    return
                }
                
                if media.mediaType == "Video" || media.mediaType == "Audio" || media.isLive {
                    if(media.defaultOptionsLink != nil) {
                        if media.mediaType == "Video" || media.isLive{
                            self.playerImageOverlayUrl = ""
                            self.playerTextOverlay = ""
                        } else {
                            self.playerImageOverlayUrl = media.image
                            self.playerTextOverlay = media.name
                        }

                        Task{
                            do {

                                var item : AVPlayerItem? = nil
                                if (media.offering != "default"){
                                    debugPrint("MediaView2 Offering: ", media.offering)
                                    item = try await MakePlayerItemFromVersionHash(fabric:eluvio.fabric, versionHash:media.mediaHash, params: media.parameters, offering:media.offering)
                       
                                }else{
                                    item = try await MakePlayerItemFromLink(fabric:eluvio.fabric, link: media.defaultOptionsLink, params: media.parameters, offering:media.offering)
                                }
                                
                                var image : UIImage? = nil
                                
                                do {
                                    debugPrint("Fetching image ", media.image)
                                    let imageData = try await eluvio.fabric.httpDataRequest(url: media.image, method:.get)
                                    image = UIImage(data: imageData)
                                    debugPrint("Downloaded image ", image)
                                }catch{
                                    print("Could not fetch image from media ", media.mediaId ?? "")
                                }

                                await MainActor.run {
                                    guard var playerItem = item else {
                                        print("Could not create player.")
                                        errorMessage = "Sorry...something went wrong"
                                        showError = true
                                        return
                                    }
                                    
                                   let titleMetadataItem = AVMutableMetadataItem()
                                    titleMetadataItem.identifier = .commonIdentifierTitle
                                    titleMetadataItem.value = media.name as NSCopying & NSObjectProtocol
                                    //TODO:
                                    titleMetadataItem.extendedLanguageTag = "und"
                                    
                                    let descriptionMetadataItem = AVMutableMetadataItem()
                                    descriptionMetadataItem.identifier = .commonIdentifierDescription
                                    descriptionMetadataItem.value = media.description_text as NSCopying & NSObjectProtocol
                                    //TODO:
                                    descriptionMetadataItem.extendedLanguageTag = "und"
                                    
                                    let artworkMetadataItem = AVMutableMetadataItem()
                                    artworkMetadataItem.identifier = .commonIdentifierArtwork
                                    artworkMetadataItem.value = image?.pngData() as? NSCopying & NSObjectProtocol
                                    //TODO:
                                    artworkMetadataItem.extendedLanguageTag = "und"
                                    
                                    playerItem.externalMetadata.append(titleMetadataItem)
                                    playerItem.externalMetadata.append(descriptionMetadataItem)
                                    playerItem.externalMetadata.append(artworkMetadataItem)
                                    
                                    self.playerItem = playerItem
                                    self.showPlayer = true
                                }
                                //print("****** showPlayer = true")
                                //print("****** playerItem set ", self.playerItem)
                            }catch{
                                print("Error creating MediaItemViewModel playerItem",error)
                                do{
                                    let meta = try await eluvio.fabric.contentObjectMetadata(id:media.mediaHash, metadataSubtree: "public/asset_metadata/permissions_message")
                                    
                                    print("permissions_message: ", meta)
                                    
                                    if meta.stringValue != "" {
                                        errorMessage = meta.stringValue
                                        showError = true
                                        await eluvio.fabric.refresh()
                                        return
                                    }
                                }catch{
                                    print("Error getting permissions message", error)
                                }
                                
                                errorMessage = "Could not access content"
                                showError = true
                                await eluvio.fabric.refresh()
                            }
                        }
                    }
                } else if media.mediaType == "HTML" {
                    //debugPrint("locked: ",mediaItem?.locked)
                    //debugPrint("locked_state", mediaItem?.locked_state)
                    self.qrUrl = media.htmlUrl
                    self.showQRView = true
                } else if media.mediaType == "Gallery" {
                    if(!media.gallery.isEmpty){
                        self.gallery = media.gallery
                        self.showGallery = true
                    }
                } else if media.mediaType == "Image" {
                    self.showImage = true
                }
 
            }) {
                MediaCard(display:display,
                          image: display == MediaDisplay.feature ? media.posterImage : media.image,
                          playerItem: display == MediaDisplay.square ? media.animation: nil,
                          isFocused:isFocused,
                          title: media.name,
                          isLive: media.isLive,
                          showFocusedTitle: showFocusName
                          //image_ratio: mediaItem?.image_aspect_ratio
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .overlay(content: {
                if (media.mediaType == "Video"){
                    if !isFocused  {
                        Image(systemName: "play.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .opacity(0.7)
                    }else{
                        //TODO: when enabling resume again
                        if !media.isLive && mediaProgress?.current_time_s ?? 0.0 > 0.0{
                            VStack{
                                Spacer()
                                VStack(alignment:.leading, spacing:5){
                                    Text(progressText).foregroundColor(.white)
                                        .font(.system(size: 12))
                                    ProgressView(value:progressValue)
                                        .foregroundColor(.white)
                                        .frame(height:4)
                                }
                                .padding()
                            }
                        }
                    }
                }
                
            })
        }
        .fullScreenCover(isPresented: $showSeriesView) {
            SeriesDetailView(seriesMediaItem: media)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .onAppear(){
            updateProgress()
        }
        .fullScreenCover(isPresented: $showGallery) { [gallery] in
            GalleryView(gallery: gallery)
                .environmentObject(self.eluvio.fabric)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .edgesIgnoringSafeArea(.all)
                .background(.thinMaterial)
        }
        .fullScreenCover(isPresented: $showQRView) { [qrUrl] in
            QRView(url: qrUrl)
                .environmentObject(self.eluvio.fabric)
        }
        
        .fullScreenCover(isPresented: $showPlayer, onDismiss: onPlayerDismiss) { [playerItem, startTimeS] in //Need the capture list to update state https://stackoverflow.com/questions/75498944/why-is-this-swiftui-state-not-updated-when-passed-as-a-non-binding-parameter
            PlayerView(playerItem:playerItem,
                       playerImageOverlayUrl:playerImageOverlayUrl,
                       playerTextOverlay:playerTextOverlay,
                       seekTimeS: startTimeS, 
                       finished:$playerFinished,
                       progressCallback: onPlayerProgress
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .fullScreenCover(isPresented: $showImage){
            ZStack{
                WebImage(url: URL(string: self.image))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .edgesIgnoringSafeArea(.all)
                    .background(.thinMaterial)
                
                if IsDemoMode(){
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Image("Share - placeholder")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 200, maxHeight: 200, alignment: .trailing)
                        }
                    }
                }
            
            }
        }
        .alert(errorMessage, isPresented:$showError){
        }
    }
    
    func updateProgress() {
        Task {
            do{
                //print("*** MediaView onChange")
                self.media = try await MediaItemViewModel.create(fabric:eluvio.fabric, mediaItem:self.mediaItem)
                    if let contract = media.nft?.contract_addr {
                    if let mediaId = media.mediaId {
                        if let account = eluvio.accountManager.currentAccount {
                            let progress = try eluvio.fabric.getUserViewedProgress(address: account.getAccountAddress(), nftContract: contract, mediaId: mediaId)
                            if (progress.current_time_s > 0){
                                debugPrint("Found saved progress ", progress)
                                await MainActor.run {
                                    self.startTimeS = progress.current_time_s
                                    self.mediaProgress = progress
                                }
                            }
                        }
                    }
                }

            }catch{
                print("MediaView could not create MediaItemViewModel ", error)
            }
        }
    }
    
    func onPlayerDismiss() {
        debugPrint("Player Dismiss")
        self.playerItem = nil
        updateProgress()
    }
    
    func onPlayerProgress(_ progress: Double,_ currentTimeS: Double,_ durationS: Double) {
        debugPrint("MediaView2 progress: ", progress)
        debugPrint("MediaView2 duration seconds: ", durationS)
        debugPrint("MediaView2 currentTime seconds: ", currentTimeS)

        //print("media view model", self.media.nft)
        //print("media model ", self.mediaItem?.nft)

        guard let contract = self.media.nft?.contract_addr else {
            print("Could not get nft contract \(self.media.nft?.contract_addr )")
            return
        }
        guard let mediaId = self.media.mediaId else{
            print("Could not get media ", self.media.mediaId)
            return
        }
        
        let mediaProgress = MediaProgress(id: mediaId,  duration_s: durationS, current_time_s: currentTimeS)

        do {
            if let account = eluvio.accountManager.currentAccount {
                try eluvio.fabric.setUserViewedProgress(address:account.getAccountAddress(), nftContract:contract, mediaId: mediaId, progress:mediaProgress)
            }
        }catch{
            print(error)
        }
    }

}
*/

enum MediaFlagPosition{case bottomRight; case bottomCenter}


//TODO: Make this generic
struct RedeemFlag: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @State var redeemable: RedeemableViewModel
    @State var position: MediaFlagPosition = .bottomCenter
    
    private var padding: CGFloat {
        return 20
    }
    
    private var text: String {
        if let account = eluvio.accountManager.currentAccount {
            return redeemable.displayLabel(currentUserAddress: account.getAccountAddress())
        }
        
        return ""
    }
    
    private var textColor: Color {
        return Color.black
    }
    
    private var bgColor: Color {
        return Color(red: 255/255, green: 215/255, blue: 0/255)
    }
    
    var body: some View {
        VStack{
            Spacer()
            if (position == .bottomCenter){
                Text(text)
                    .font(.custom("HelveticaNeue", size: 21))
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                    .padding(3)
                    .padding(.leading,7)
                    .padding(.trailing,7)
                    .background(RoundedRectangle(cornerRadius: 5).fill(bgColor))
            }else{
                HStack {
                    Spacer()
                    Text(text)
                        .font(.custom("Helvetica Neue", size: 21))
                        .multilineTextAlignment(.center)
                        .foregroundColor(textColor)
                        .padding(3)
                        .padding(.leading,7)
                        .padding(.trailing,7)
                        .background(RoundedRectangle(cornerRadius: 5).fill(bgColor))
                }
            }
        }
        //.frame(maxWidth:.infinity, maxHeight: .infinity)
        .padding(padding)
    }
}

struct RedeemableCardView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    var redeemable: RedeemableViewModel
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.square
    @State var showOfferView: Bool = false
    @State var playerItem: AVPlayerItem?
    var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Button(action: {
                    self.showOfferView = true
                }) {
                    ZStack{
                        MediaCard(display: display, image: display == MediaDisplay.feature ? redeemable.posterUrl : redeemable.imageUrl,
                                  playerItem: playerItem,
                                  isFocused:isFocused,
                                  title: redeemable.name,
                                  centerFocusedText: true
                        )
                        RedeemFlag(redeemable: redeemable)
                    }
                }
                .buttonStyle(TitleButtonStyle(focused: isFocused))
                .focused($isFocused)
        }
        .onAppear(){
            debugPrint("REDEEMABLE ONAPPEAR", redeemable.id)
            Task{
                do{
                    if (display == MediaDisplay.square){
                        playerItem = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: redeemable.animationLink)
                    }
                }catch{
                    print("Error creating player item", error)
                }
            }
        }
        .fullScreenCover(isPresented: $showOfferView) {
            OfferView(redeemable:redeemable)
        }
    }
}

struct MediaCard: View {
    var display: MediaDisplay = MediaDisplay.square
    var image: String = ""
    var playerItem : AVPlayerItem? = nil
    var isFocused: Bool = false
    var isUpcoming: Bool = false
    var startTimeString: String = ""
    var title: String = ""
    var subtitle: String = ""
    var timeString: String = ""
    var isLive: Bool = false
    var centerFocusedText: Bool = false
    var showFocusedTitle = true
    var showBottomTitle = true
    var image_ratio: String? = nil //Square, Wide, Tall or nil

    @State var width: CGFloat = 300
    @State var height: CGFloat = 300
    var sizeFactor: CGFloat = 1
    @State var cornerRadius: CGFloat = 3
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var newItem : Bool = true
    var permission : ResolvedPermission? = nil
    
    var body: some View {
        VStack(alignment:.leading) {
            ZStack{
                if (playerItem != nil){
                    LoopingVideoPlayer([playerItem!], endAction: .loop)
                        .frame(width:width, height:height, alignment: .center)
                        .cornerRadius(cornerRadius)
                }else{
                    if (image.hasPrefix("http")){
                        WebImage(url: URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame( width: width, height: height)
                            .cornerRadius(cornerRadius)
                            .clipped()
                    }else if (image != ""){
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame( width: width, height: height)
                            .cornerRadius(cornerRadius)
                    }else {
                        //No image, display like the focused state with a lighter background
                        if (!isFocused) {
                            VStack(alignment: .center, spacing: 7) {
                                if ( !centerFocusedText ){
                                    Spacer()
                                }
                                if showFocusedTitle {
                                    Text(title)
                                        .foregroundColor(Color.white)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
                                Text(subtitle)
                                    .font(.small)
                                    .foregroundColor(Color.white)
                                    .lineLimit(3)
                            }
                            .frame(maxWidth:.infinity, maxHeight:.infinity)
                            .padding(20)
                            .padding(.bottom, 50)
                            .cornerRadius(cornerRadius)
                            .background(Color.white.opacity(0.1))
                            .scaleEffect(sizeFactor)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                        }
                    }
                }
                
                if (isFocused){
                    VStack(alignment: .leading, spacing: 7) {

                        if ( !centerFocusedText){
                            Spacer()
                        }
                        
                        if let perm = permission {
                            if perm.showAlternatePage || perm.purchaseGate {
                                Text("VIEW PURCHASE OPTIONS")
                                    .font(.system(size: display == MediaDisplay.square ? 20 : 26))
                                .foregroundColor(Color.white)
                                .lineLimit(display == MediaDisplay.square ? 2 : 1)
                                .bold()
                                .frame(maxWidth:.infinity, alignment:.leading)
                            Spacer()
                            }
                        }
                        
                        if showFocusedTitle {
                            Text(timeString)
                                .font(.system(size: 15))
                                .foregroundColor(Color.gray)
                                .frame(maxWidth:.infinity, alignment:.leading)
                            
                            Text(title)
                                .font(.system(size: 22))
                                .foregroundColor(Color.white)
                                .lineLimit(1)
                                .bold()
                                .frame(maxWidth:.infinity, alignment:.leading)
                            
                            Text(subtitle)
                                .font(.system(size: 19))
                                .foregroundColor(Color.gray)
                                .lineLimit(1)
                                .frame(maxWidth:.infinity, alignment:.leading)
                        }
                    }
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
                    .padding(20)
                    .scaleEffect(sizeFactor)
                    .cornerRadius(cornerRadius)
                    .background(Color.black.opacity(showFocusedTitle ? 0.8 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.highlight, lineWidth: 4)
                    )
                }
                
                if (isUpcoming && !isFocused){
                    VStack(alignment: .trailing, spacing: 7) {
                        Spacer()
                        VStack{
                            Text("UPCOMING")
                                .font(.custom("Helvetica Neue", size: 21))
                                .foregroundColor(Color.white)
                            Text(startTimeString)
                                .font(.custom("Helvetica Neue", size: 21))
                                .foregroundColor(Color.white)
                        }
                        .padding(3)
                        .padding(.leading,7)
                        .padding(.trailing,7)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.6)))
                    }
                    .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.trailing)
                    .padding(20)
                    .scaleEffect(sizeFactor)
                }else if (isLive && display != .feature){
                    VStack() {
                        Spacer()
                        HStack{
                            Spacer()
                            Text("LIVE")
                                .font(.custom("Helvetica Neue", size: 21))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(3)
                                .padding(.leading,7)
                                .padding(.trailing,7)
                                .background(RoundedRectangle(cornerRadius: 5).fill(.red))
                        }
                    }
                    .frame( maxWidth: .infinity, maxHeight:.infinity)
                    .padding(20)
                    .scaleEffect(sizeFactor)
                }
            }
            if showBottomTitle {
                Text(title).font(.system(size: 22*sizeFactor)).lineLimit(1).frame(alignment:.leading)
            }
        }
        .frame( width: width, height: height)
        .onAppear(){
            if display == MediaDisplay.feature {
                width = 248 * sizeFactor
                height = 372 * sizeFactor
                cornerRadius = 3 * sizeFactor
            }else if display == MediaDisplay.video{
                width =  400 * sizeFactor
                height = 225 * sizeFactor
                cornerRadius = 16 * sizeFactor
            }else if display == MediaDisplay.books {
                width =  235 * sizeFactor
                height = 300 * sizeFactor
                cornerRadius = 16 * sizeFactor
            }else if display == MediaDisplay.property {
                width =  330 * sizeFactor
                height = 470 * sizeFactor
                cornerRadius = 16 * sizeFactor
            }else if display == MediaDisplay.tile {
                width =  887 * sizeFactor
                height = 551 * sizeFactor
                cornerRadius = 0
            }else {
                width =  235 * sizeFactor
                height = 235 * sizeFactor
                cornerRadius = 16 * sizeFactor
            }
        }
    }
}
