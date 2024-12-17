//
//  PlayerCountdownView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-20.
//

import SwiftUI
import SDWebImageSwiftUI

struct PlayerErrorView: View {
    var backgroundImageUrl : String = "https://picsum.photos/1920/1080"
    var title: String = "The media is not available"
    
    var body: some View {
        ZStack(alignment:.center){
            
            WebImage(url:URL(string:backgroundImageUrl))
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment:.center, spacing:0){
                Spacer()
                Image(systemName:"lock")
                    .resizable()
                    .scaledToFit()
                    .frame(width:100, height:100)
                    .padding(.bottom, 52)

                Text(title).font(.system(size:32, weight:.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: 1600)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 52)

                Spacer()
            }
        }
    }
}

struct CountDownView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    var backgroundImageUrl : String = ""
    var images : [String] = []
    var imageUrl : String = ""
    var title: String = ""
    var description: String = ""
    var infoText: String = ""
    var mediaItem: MediaPropertySectionMediaItem
    var propertyId: String = ""
    @State var timeRemaining : String = " "


    @State var timer:Timer?
    
    var body: some View {
        ZStack(alignment:.center){
            
            WebImage(url:URL(string:backgroundImageUrl))
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment:.center, spacing:0){
                Spacer()
                if images.isEmpty {
                    WebImage(url:URL(string:imageUrl))
                        .resizable()
                        .scaledToFit()
                        .frame(width:600, height:300)
                        .padding(.bottom, 52)
                }else if !images.isEmpty {
                    HStack(spacing:52) {
                        ForEach(0..<images.count, id:\.self) { index in
                            WebImage(url:URL(string:images[index]))
                                .resizable()
                                .scaledToFit()
                                .frame(width:200, height:200)
                                .padding(.bottom, 52)
                        }
                    }
                }
                
                Text(infoText).font(.system(size:32))
                    .lineLimit(1)
                    .frame(maxWidth: 1600)
                    .padding(.bottom, 28)
                
                Text(title).font(.system(size:32, weight:.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: 1600)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 52)
                
                Text(timeRemaining).font(.system(size:62, weight:.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: 1600)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    .id("time remainging: " + timeRemaining)
                    .padding()
                Spacer()
            }
        }
        .onDisappear(){
            if let timer = self.timer {
                timer.invalidate()
            }
        }
        .onAppear(){
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if let startDate = mediaItem.startDate{
                    if startDate > Date() && !mediaItem.hasStarted{
                        timeRemaining = mediaItem.timeUntilStartLong
                    }else{
                        if (timeRemaining.isEmpty || timeRemaining == " "){
                            withAnimation(.easeInOut(duration: 1), {
                                timeRemaining = "Starting soon"
                            })
                        }else{
                            timeRemaining = "Starting soon"
                        }
                        
                        if mediaItem.hasStarted {
                            timer.invalidate()
                            debugPrint("Starting stream...")
                            if ( mediaItem.media_type?.lowercased() == "video") {
                                Task{
                                    if var link = mediaItem.media_link?["sources"]["default"] {
                                        if mediaItem.media_link?["."]["resolution_error"]["kind"].stringValue == "permission denied" {
                                            debugPrint("permission denied! ", mediaItem.title)
                                            
                                            let videoErrorParams = VideoErrorParams(mediaItem:mediaItem, type: .permission, backgroundImage: backgroundImageUrl, images: images)
                                            
                                            eluvio.pathState.videoErrorParams = videoErrorParams
                                            await MainActor.run {
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.videoError)
                                                return
                                            }
                                        }
                                        
                                        do {
                                            let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(propertyId: propertyId, mediaId: mediaItem.id ?? "")
                                            
                                            var thumbnail = imageUrl;
                                            if thumbnail.isEmpty {
                                                thumbnail = images[0]
                                            }
                                            
                                            let playerItem = try await  MakePlayerItemFromMediaOptionsJson(fabric: eluvio.fabric, optionsJson: optionsJson, title:title, description:description, imageThumb: thumbnail)
                                            let params = VideoParams(mediaId:mediaItem.id ?? "", playerItem: playerItem)
                                            eluvio.pathState.videoParams = params
    
                                            await MainActor.run {
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.video)
                                                return
                                            }
                                        }catch{
                                            print("Error getting link url for playback ", error)
                                            let videoErrorParams = VideoErrorParams(mediaItem:mediaItem, type:.permission, backgroundImage: backgroundImageUrl)
                                            eluvio.pathState.videoErrorParams = videoErrorParams
                                            await MainActor.run {
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.videoError)
                                                return
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }
    }
}
