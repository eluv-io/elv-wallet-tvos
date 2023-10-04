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

struct MediaCollectionView: View {
    @EnvironmentObject var fabric: Fabric
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
        .introspectScrollView { view in
            view.clipsToBounds = false
        }
    }
}

func MakePlayerItemFromVersionHash(fabric: Fabric, versionHash: String, params: [JSON]? = [], offering: String = "default") async throws -> AVPlayerItem {
    let options = try await fabric.getOptions(versionHash: versionHash, offering: offering)
    return try MakePlayerItemFromOptionsJson(fabric: fabric, optionsJson: options, versionHash: versionHash, offering: offering)
}


func MakePlayerItem(fabric: Fabric, media: MediaItem?, offering: String = "default") async throws -> AVPlayerItem {
    
    return try await MakePlayerItemFromLink(fabric:fabric, link: media?.media_link?["sources"][offering], params: media?.parameters, offering: offering)
}

func MakePlayerItemFromLink(fabric: Fabric, link: JSON?, params: [JSON]? = [], offering: String = "default") async throws -> AVPlayerItem {
    let options = try await fabric.getOptionsFromLink(link: link, params: params, offering: offering)
    return try MakePlayerItemFromOptionsJson(fabric: fabric, optionsJson: options.optionsJson, versionHash: options.versionHash, offering: offering)
}

func MakePlayerItemFromOptionsJson(fabric: Fabric, optionsJson: JSON?, versionHash: String, offering: String = "default") throws -> AVPlayerItem {
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

struct MediaView2: View {
    @EnvironmentObject var fabric: Fabric
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

                                if (media.offering != "default"){
                                    debugPrint("MediaView2 Offering: ", media.offering)
                                    self.playerItem = try await MakePlayerItemFromVersionHash(fabric:fabric, versionHash:media.mediaHash, params: media.parameters, offering:media.offering)
                                }else{
                                    self.playerItem = try await MakePlayerItemFromLink(fabric:fabric, link: media.defaultOptionsLink, params: media.parameters, offering:media.offering)
                                }
                            
                                self.showPlayer = true
                                //print("****** showPlayer = true")
                                //print("****** playerItem set ", self.playerItem)
                            }catch{
                                print("Error creating MediaItemViewModel playerItem",error)
                                do{
                                    let meta = try await fabric.contentObjectMetadata(versionHash:media.mediaHash, metadataSubtree: "public/asset_metadata/permissions_message")
                                    
                                    print("permissions_message: ", meta)
                                    
                                    if meta.stringValue != "" {
                                        errorMessage = meta.stringValue
                                        showError = true
                                        await fabric.refresh()
                                        return
                                    }
                                }catch{
                                    print("Error getting permissions message", error)
                                }
                                
                                errorMessage = "Could not access content"
                                showError = true
                                await fabric.refresh()
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
                if ((media.mediaType == "Video" || media.isLive) && !isFocused){
                    Image(systemName: "play.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .opacity(0.7)
                }
            })
        }
        .fullScreenCover(isPresented: $showSeriesView) {
            SeriesDetailView(seriesMediaItem: media)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .onAppear(){
            Task {
                do{
                    //print("*** MediaView onChange")
                    self.media = try await MediaItemViewModel.create(fabric:fabric, mediaItem:self.mediaItem)
                    //print ("MediaView name ", media.name)
                    //debugPrint("MediaItem title: ", self.mediaItem?.name)
                    //debugPrint("display: ", display)
                }catch{
                    print("MediaView could not create MediaItemViewModel ", error)
                }
            }
        }
        .fullScreenCover(isPresented: $showGallery) {
            GalleryView(gallery: $gallery)
                .environmentObject(self.fabric)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .edgesIgnoringSafeArea(.all)
                .background(.thinMaterial)
        }
        .fullScreenCover(isPresented: $showQRView) {
            QRView(url: $qrUrl)
                .environmentObject(self.fabric)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView(playerItem:self.$playerItem,
                       playerImageOverlayUrl:playerImageOverlayUrl,
                       playerTextOverlay:playerTextOverlay,
                       finished:$playerFinished
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

}

enum MediaFlagPosition{case bottomRight; case bottomCenter}


//TODO: Make this generic
struct RedeemFlag: View {
    @State var redeemable: RedeemableViewModel
    @State var position: MediaFlagPosition = .bottomCenter
    
    private var padding: CGFloat {
        return 20
    }
    
    private var text: String {
        return "REWARD"
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
    @EnvironmentObject var fabric: Fabric
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
                        playerItem = try await MakePlayerItemFromLink(fabric: fabric, link: redeemable.animationLink)
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
    var title: String = ""
    var subtitle: String = ""
    var isLive: Bool = false
    var centerFocusedText: Bool = false
    var showFocusedTitle = true
    var image_ratio: String? = nil //Square, Wide, Tall or nil

    @State var width: CGFloat = 300
    @State var height: CGFloat = 300
    @State var cornerRadius: CGFloat = 3
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var newItem : Bool = true
    
    var body: some View {
        ZStack{
            if (playerItem != nil){
                LoopingVideoPlayer([playerItem!], endAction: .loop)
                    .frame(width:width, height:height, alignment: .center)
                    .cornerRadius(cornerRadius)
            }else{
                if (image.hasPrefix("http")){
                    WebImage(url: URL(string: image))
                        .resizable()
                        .indicator(.activity) // Activity Indicator
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                        .frame( width: width, height: height)
                        .cornerRadius(cornerRadius)
                }else if (image != ""){
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame( width: width, height: height)
                        .cornerRadius(cornerRadius)
                }else {
                    //No image, display like the focused state with a lighter background
                    VStack(alignment: .center, spacing: 7) {
                        if ( !centerFocusedText ){
                            Spacer()
                        }
                        if showFocusedTitle {
                            Text(title)
                                .foregroundColor(Color.white)
                                .font(.subheadline)
                        }
                        Text(subtitle)
                            .font(.small)
                            .foregroundColor(Color.white)
                            .lineLimit(3)
                    }
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
                    .padding(20)
                    .cornerRadius(cornerRadius)
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                }
            }

            if (isFocused){
                VStack(alignment: .center, spacing: 7) {
                    if ( !centerFocusedText ){
                        Spacer()
                    }
                    if showFocusedTitle {
                        Text(title)
                            .foregroundColor(Color.white)
                            .font(.subheadline)
                    }
                    Text(subtitle)
                        .font(.small)
                        .foregroundColor(Color.white)
                        .lineLimit(3)
                }
                .frame(maxWidth:.infinity, maxHeight:.infinity)
                .padding(20)
                .cornerRadius(cornerRadius)
                .background(Color.black.opacity(showFocusedTitle ? 0.8 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.highlight, lineWidth: 4)
                )
            }else if (isUpcoming){
                VStack(alignment: .trailing, spacing: 7) {
                    Spacer()
                    Text(title)
                        .foregroundColor(Color.white)
                        .font(.subheadline)
                    Text(subtitle)
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.trailing)
                .padding(20)
                .background(Color.black.opacity( 0.8))
            }
            
            if (isLive && display != .feature){
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
            }
        }
        .frame( width: width, height: height)
        .onAppear(){
            /*
            if let ratio = image_ratio {
                if ratio == "Square"{
                    width =  300
                    height = 300
                    cornerRadius = 16
                } else if ratio == "Tall"{
                    width = 393
                    height = 590
                    cornerRadius = 3
                } else if ratio == "Wide" {
                    width =  534
                    height = 300
                    cornerRadius = 16
                }
            }else {*/
            //debugPrint("Media ", title)
            //debugPrint("Media Display ", display)
                
                if display == MediaDisplay.feature {
                    width = 393
                    height = 590
                    cornerRadius = 3
                }else if display == MediaDisplay.video{
                    width =  534
                    height = 300
                    cornerRadius = 16
                }else if display == MediaDisplay.books {
                    width =  235
                    height = 300
                    cornerRadius = 16
                }else if display == MediaDisplay.property {
                    width =  405
                    height = 247
                    cornerRadius = 16
                }else if display == MediaDisplay.tile {
                    width =  887
                    height = 551
                    cornerRadius = 0
                }else {
                    width =  300
                    height = 300
                    cornerRadius = 16
                }
            //}
        }
    }
}
