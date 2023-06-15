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
    @Binding var showPlayer : Bool
    @Binding var playerItem : AVPlayerItem?
    @Binding var playerImageOverlayUrl : String
    @Binding var playerTextOverlay : String
    var display: MediaDisplay = MediaDisplay.square
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 52) {
                ForEach(self.mediaCollection.media) {media in
                    MediaView2(mediaItem: media,
                              display: display
                    )
                }
            }
            .padding([.top,.bottom],20)
        }
        .introspectScrollView { view in
            view.clipsToBounds = false
        }
    }
}

func MakePlayerItem(fabric: Fabric, media: MediaItem?, offering: String = "default") async throws -> AVPlayerItem {
    
    return try await MakePlayerItemFromLink(fabric:fabric, link: media?.media_link?["sources"][offering], params: media?.parameters, offering: offering)
}

func MakePlayerItemFromLink(fabric: Fabric, link: JSON?, params: [JSON]? = [], offering: String = "default") async throws -> AVPlayerItem {

    let options = try await fabric.getOptionsFromLink(link: link, offering: offering)
    return try MakePlayerItemFromOptionsJson(fabric: fabric, optionsJson: options.optionsJson, versionHash: options.versionHash)
}

func MakePlayerItemFromOptionsJson(fabric: Fabric, optionsJson: JSON?, versionHash: String, offering: String = "default") throws -> AVPlayerItem {
    var hlsPlaylistUrl: String = ""
    
    guard let options = optionsJson else {
        throw RuntimeError("MakePlayerItemFromOptionsJson options is nil")
    }
    
    if options["hls-clear"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash, drm:"hls-clear")
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
        print("Playlist URL \(hlsPlaylistUrl)")
        
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
        ContentKeyManager.shared.contentKeyDelegate.setDRM(licenseServer:licenseServer, authToken: fabric.fabricToken)
        return AVPlayerItem(asset: urlAsset)
        
    }else{
        throw RuntimeError("No available playback options \(options)")
    }
}

struct MediaView: View {
    @EnvironmentObject var fabric: Fabric
    @State var media: MediaItem? = nil
    @Binding var showPlayer : Bool
    @Binding var playerItem : AVPlayerItem?
    @FocusState var isFocused
    @State var showGallery = false
    @State var gallery: [GalleryItem] = []
    @State var showQRView = false
    @State var qrUrl = "https://eluv.io"
    @Binding var playerImageOverlayUrl : String
    @Binding var playerTextOverlay : String

    var display: MediaDisplay = MediaDisplay.apps
    @State var imageUrl: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                if media?.media_type == "Video" || media?.media_type == "Audio"{
                    if media?.media_type == "Video" {
                        self.playerImageOverlayUrl = ""
                        self.playerTextOverlay = ""
                    } else {
                        self.playerImageOverlayUrl = media?.image ?? ""
                        self.playerTextOverlay = media?.name ?? ""
                    }
                    self.showPlayer = true
                        Task {
                            do {
                                self.playerItem = try await MakePlayerItem(fabric:fabric, media:media)
                            } catch {
                                print("Error getting Options url from link \(error)")
                            }
                        }
                    }
                else if media?.media_type == "HTML" {
                    do {
                        //let htmlUrl = try fabric.getUrlFromLink(link: media?.media_file, params: media?.parameters ?? [])
                        let htmlUrl = try fabric.getMediaHTML(link: media?.media_file, params: media?.parameters ?? [])
                        self.qrUrl = htmlUrl
                        self.showQRView = true
                        
                    } catch {
                        print("Error getting Options url from link \(error)")
                    }
                }
                else if media?.media_type == "Gallery" {
                    if media?.gallery != nil {
                        self.gallery = media?.gallery ?? []
                        self.showGallery = true
                    }
                }
 
            }) {
                MediaCard(display:display, image:self.imageUrl,
                          isFocused:isFocused,
                          title: media?.name ?? "",
                          isLive: media?.isLive ?? false
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .overlay(content: {
                if (media?.media_type == "Video" && !isFocused){
                    Image(systemName: "play.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .opacity(0.7)
                }
            })
        }
        .onAppear(){
            if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
                self.imageUrl = "https://picsum.photos/600/800"
            }else{
                do {
                    var image: String = media?.image ?? ""
                    
                    if(self.display == MediaDisplay.feature || image == ""){
                        if let posterImage = media?.poster_image {
                            image = try fabric.getUrlFromLink(link: posterImage)
                        }
                    }
                    
                    self.imageUrl = image
                }catch{
                    print("Error getting image URL from link ", media?.image as Any)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .edgesIgnoringSafeArea(.all)
                .background(.thinMaterial)
        }
    }
}

struct MediaView2: View {
    @EnvironmentObject var fabric: Fabric
    @State var mediaItem: MediaItem?
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
    var display: MediaDisplay = MediaDisplay.apps
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                if media.mediaType == "Video" || media.mediaType == "Audio"{
                    if(media.defaultOptionsLink != nil) {
                        if media.mediaType == "Video" {
                            self.playerImageOverlayUrl = ""
                            self.playerTextOverlay = ""
                        } else {
                            self.playerImageOverlayUrl = media.image
                            self.playerTextOverlay = media.name
                        }

                            Task{
                                do {
                                    self.playerItem = try await MakePlayerItemFromLink(fabric:fabric, link: media.defaultOptionsLink, params: media.parameters)
                                    self.showPlayer = true
                                    //print("****** showPlayer = true")
                                    //print("****** playerItem set ", self.playerItem)
                                }catch{
                                    print("Error creating MediaItemViewModel playerItem",error)
                                }
                            }
                    }
                } else if media.mediaType == "HTML" {
                    self.qrUrl = media.htmlUrl
                    self.showQRView = true
                } else if media.mediaType == "Gallery" {
                    if(!media.gallery.isEmpty){
                        self.gallery = media.gallery
                        self.showGallery = true
                    }
                }
 
            }) {
                MediaCard(display:display,
                          image: display == MediaDisplay.feature ? media.posterImage : media.image,
                          playerItem: display == MediaDisplay.square ? media.animation: nil,
                          isFocused:isFocused,
                          title: media.name,
                          isLive: media.isLive
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .overlay(content: {
                if (media.mediaType == "Video" && !isFocused){
                    Image(systemName: "play.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .opacity(0.7)
                }
            })
        }
        .onChange(of: mediaItem) {newValue in
            Task {
                do{
                    //print("*** MediaView onChange")
                    self.media = try await MediaItemViewModel.create(fabric:fabric, mediaItem:self.mediaItem)
                }catch{
                    print("MediaView could not create MediaItemViewModel ", error)
                }
            }
        }
        .onAppear(){
            Task {
                do{
                    //print("*** MediaView onChange")
                    self.media = try await MediaItemViewModel.create(fabric:fabric, mediaItem:self.mediaItem)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .edgesIgnoringSafeArea(.all)
                .background(.thinMaterial)
        }
        
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView(playerItem:self.$playerItem,
                       playerImageOverlayUrl:$playerImageOverlayUrl,
                       playerTextOverlay:$playerTextOverlay
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

}

struct RedeemableCardView: View {
    @EnvironmentObject var fabric: Fabric
    @State var redeemable: RedeemableViewModel
    @FocusState var isFocused
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                
            }) {
                MediaCard(image:redeemable.imageUrl,
                          playerItem: redeemable.animationPlayerItem,
                          isFocused:isFocused,
                          title: redeemable.name
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .overlay(content: {
                
            })
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
                }
            }

            if (isFocused){
                VStack(alignment: .leading, spacing: 7) {
                    Spacer()
                    Text(title.capitalized)
                        .foregroundColor(Color.white)
                        .font(.subheadline)
                    Text(subtitle.capitalized)
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth:.infinity, maxHeight:.infinity)
                .padding(20)
                .background(Color.black.opacity(0.8))
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
                .background(Color.black.opacity(0.8))
            }
            
            if (isLive){
                VStack() {
                    Spacer()
                    HStack{
                        Spacer()
                        Image("live_flag")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame( width: 70, alignment: .bottomTrailing)
                            .padding(20)
                    }
                }
                .frame( maxWidth: .infinity, maxHeight:.infinity)
            }
        }
        .frame( width: width, height: height)
        .onAppear(){
            if display == MediaDisplay.feature {
                width = 400
                height = 560
                cornerRadius = 3
            }else if display == MediaDisplay.video {
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
        }
    }
}
