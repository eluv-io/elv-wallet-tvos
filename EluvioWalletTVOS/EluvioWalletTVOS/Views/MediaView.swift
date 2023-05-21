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

enum MediaDisplay {case apps; case video; case feature; case books; case album; case property}

struct MediaCollectionView: View {
    @EnvironmentObject var fabric: Fabric
    @State var mediaCollection: MediaCollection
    @Binding var showPlayer : Bool
    @Binding var playerItem : AVPlayerItem?
    @Binding var playerImageOverlayUrl : String
    @Binding var playerTextOverlay : String
    var display: MediaDisplay = MediaDisplay.apps
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 20) {
                ForEach(self.mediaCollection.media) {media in
                    MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem,
                              playerImageOverlayUrl:$playerImageOverlayUrl,
                              playerTextOverlay:$playerTextOverlay,
                              display: display
                    )
                }
            }
            .padding(20)
        }
    }
}

struct NFTMediaView: View {
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
                                
                                var offering = "default"
 
                                if (media?.offerings?.count ?? 0 > 0){
                                    offering = media?.offerings?[0] ?? "default"
                                }

                                var optionsUrl = try fabric.getUrlFromLink(link: media?.media_link?["sources"]["default"], params: media?.parameters ?? [] )
                                
                                //There's no offering other than sources.default
                                //let optionsUrl = try fabric.getOptionsFromLink(resolvedLink: media?.media_link, offering: offering)

                                
                                if(offering != "default" && optionsUrl.contains("default/options.json")){
                                    optionsUrl = optionsUrl.replaceFirst(of: "default/options.json", with: "\(offering)/options.json")
                                }
                                
                                print ("Offering \(offering)")
                                print("options url \(optionsUrl)")
                                
                                
                                guard let hash = FindContentHash(uri: optionsUrl) else {
                                    throw RuntimeError("Could not find hash from \(optionsUrl)")
                                }
                                
                                let optionsJson = try await fabric.getJsonRequest(url: optionsUrl)
                                print("options json \(optionsJson)")
                                
                                var hlsPlaylistUrl: String = ""
                                
                                if optionsJson["hls-clear"].exists() {
                                    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: hash, drm:"hls-clear")
                                    print("Playlist URL \(hlsPlaylistUrl)")
                                    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
                                    
                                    self.playerItem = AVPlayerItem(asset: urlAsset)
                                }else if optionsJson["hls-fairplay"].exists() {
                                    let licenseServer = optionsJson["hls-fairplay"]["properties"]["license_servers"][0].stringValue
                                    
                                    if(licenseServer.isEmpty)
                                    {
                                        throw RuntimeError("Error getting licenseServer")
                                    }
                                    print("license_server \(licenseServer)")
                                    
                                    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: hash, drm:"hls-fairplay", offering: offering)
                                    print("Playlist URL \(hlsPlaylistUrl)")
                                    
                                    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
                                    
                                    ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
                                    ContentKeyManager.shared.contentKeyDelegate.setDRM(licenseServer:licenseServer, authToken: fabric.fabricToken)
                                    self.playerItem = AVPlayerItem(asset: urlAsset)
                                    
                                }else{
                                    throw RuntimeError("No available playback options \(optionsJson)")
                                }
                            } catch {
                                print("Error getting Options url from link \(error)")
                            }
                        }
                    }
                else if media?.media_type == "HTML" {
                    do {
                        //let htmlUrl = try fabric.getUrlFromLink(link: media?.media_file, params: media?.parameters ?? [])
                        let htmlUrl = try fabric.getMediaHTML(link: media?.media_file, params: media?.parameters ?? [])
                        print("url \(htmlUrl)")
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
                
                WebImage(url: URL(string: media?.image ?? ""))
                    .resizable()
                    .indicator(.activity) // Activity Indicator
                    .transition(.fade(duration: 0.5))
                    .aspectRatio(contentMode: .fill)
                    .frame( width: 225, height: 225)
                    .cornerRadius(15)
            }
            .buttonStyle(DetailButtonStyle(focused: isFocused))
            .focused($isFocused)
            .overlay(content: {
                if (media?.media_type == "Video"){
                    Image(systemName: "play.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .opacity(0.7)
                }
            })
            
            Text(media?.name ?? "")
                .foregroundColor(Color.white)
                .lineLimit(3)
                .font(.caption)
                .frame(width: 300, height: 80, alignment: .topLeading)
            
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


func MakePlayerItem(fabric: Fabric, media: MediaItem?) async throws -> AVPlayerItem {

        var offering = "default"

        if (media?.offerings?.count ?? 0 > 0){
            offering = media?.offerings?[0] ?? "default"
        }

        var optionsUrl = try fabric.getUrlFromLink(link: media?.media_link?["sources"]["default"], params: media?.parameters ?? [] )
        
        //There's no offering other than sources.default
        //let optionsUrl = try fabric.getOptionsFromLink(resolvedLink: media?.media_link, offering: offering)

        
        if(offering != "default" && optionsUrl.contains("default/options.json")){
            optionsUrl = optionsUrl.replaceFirst(of: "default/options.json", with: "\(offering)/options.json")
        }
        
        print ("Offering \(offering)")
        print("options url \(optionsUrl)")
        
        
        guard let hash = FindContentHash(uri: optionsUrl) else {
            throw RuntimeError("Could not find hash from \(optionsUrl)")
        }
        
        let optionsJson = try await fabric.getJsonRequest(url: optionsUrl)
        print("options json \(optionsJson)")
        
        var hlsPlaylistUrl: String = ""
        
        if optionsJson["hls-clear"].exists() {
            hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: hash, drm:"hls-clear")
            print("Playlist URL \(hlsPlaylistUrl)")
            let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
            
            return AVPlayerItem(asset: urlAsset)
        }else if optionsJson["hls-fairplay"].exists() {
            let licenseServer = optionsJson["hls-fairplay"]["properties"]["license_servers"][0].stringValue
            
            if(licenseServer.isEmpty)
            {
                throw RuntimeError("Error getting licenseServer")
            }
            print("license_server \(licenseServer)")
            
            hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: hash, drm:"hls-fairplay", offering: offering)
            print("Playlist URL \(hlsPlaylistUrl)")
            
            let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
            
            ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
            ContentKeyManager.shared.contentKeyDelegate.setDRM(licenseServer:licenseServer, authToken: fabric.fabricToken)
            return AVPlayerItem(asset: urlAsset)
            
        }else{
            throw RuntimeError("No available playback options \(optionsJson)")
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
                        print("MEDIA APP FOUND:  \(htmlUrl)")
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
                MediaCard(display:display, imageUrl:self.imageUrl, isFocused:isFocused, title: media?.name ?? "")
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .overlay(content: {
                if (media?.media_type == "Video"){
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
                    print("MEDIA APP FOUND \(media?.name)")
                    
                    var image: String = media?.image ?? ""
                    
                    if(self.display == MediaDisplay.feature || image == ""){
                        if let posterImage = media?.poster_image {
                            image = try fabric.getUrlFromLink(link: posterImage)
                            //print("Poster image found: ", image)
                            if media?.media_type == "HTML"{
                                //print("MEDIA APP FOUND \(media?.name):  \(image)")
                            }
                        }
                    }
                    
                    self.imageUrl = image
                    //print("Media Image URL: ", self.imageUrl)
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

struct MediaCard: View {
    var display: MediaDisplay = MediaDisplay.apps
    var image: String = ""
    var imageUrl: String = ""
    var isFocused: Bool = false
    var title: String = ""
    var subtitle: String = ""
    @State var width: CGFloat = 300
    @State var height: CGFloat = 300
    @State var cornerRadius: CGFloat = 3
    
    var body: some View {
        ZStack{
            if (imageUrl != ""){
                WebImage(url: URL(string: imageUrl))
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
            }
        }
        .frame( width: width, height: height)
        .onAppear(){
            if display == MediaDisplay.feature {
                width = 400
                height = 560
                cornerRadius = 3
            }else if display == MediaDisplay.video {
                width =  500
                height = 281
                cornerRadius = 16
            }else if display == MediaDisplay.books {
                width =  235
                height = 300
                cornerRadius = 16
            }else if display == MediaDisplay.property {
                width =  405
                height = 247
                cornerRadius = 16
            }else {
                width =  300
                height = 300
                cornerRadius = 16
            }
        }
    }
}
