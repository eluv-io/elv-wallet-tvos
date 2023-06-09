//
//  PlayerView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-10.
//

import Foundation
import SwiftUI
import AVKit
import SDWebImageSwiftUI

class PlayerItemObserver: NSObject, ObservableObject {
    @Published var playerItemContext = 0
}

//This player plays the main video of an NFTModel
struct NFTPlayerView: View {
    @EnvironmentObject var fabric: Fabric
    @State var player = AVPlayer()
    @State var isPlaying: Bool = false
    @State var playerItem : AVPlayerItem?
    @State var nft: NFTModel
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var newItem : Bool = false
    
    var body: some View {
        VideoPlayer(player: player)
        .ignoresSafeArea()
        .onChange(of: playerItem) { value in
            if (self.playerItem != nil) {
                self.player.replaceCurrentItem(with: self.playerItem)
                print("PlayerView: replaced current Item \(self.playerItem?.asset)")
                newItem = true

            }
        }
        .onReceive(timer) { time in
            print("Item Status \(self.playerItem?.status.rawValue)")
            if (newItem && self.playerItem?.status == .readyToPlay){
                self.player.play()
                newItem = false
                print("Play!!")
            }
        }
        .onAppear(){
            Task{
                if let mediaType = nft.meta_full?["media_type"].stringValue {
                    if mediaType == "Video" {
                        if let embedUrl = nft.meta_full?["embed_url"].stringValue {
                            print("EMBED URL: ", embedUrl)
                            if let versionHash = FindContentHash(uri: embedUrl) {
                                print("Content Hash: ", versionHash)
                                do {
                                    let optionsJson = try await fabric.getOptionsJsonFromHash(versionHash: versionHash)
                                    print("Options: ",optionsJson)
                                    let playListUrl = try await fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash)
                                    print("PlaylistUrl: ",playListUrl)
                                    self.playerItem = try MakePlayerItemFromOptionsJson(fabric: fabric,
                                                                                    optionsJson: optionsJson,
                                                                                    versionHash: versionHash)
                                }catch{
                                    print("NFTPlayerView: ", error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var player = AVPlayer()
    @State var isPlaying: Bool = false
    @Binding var playerItem : AVPlayerItem?
    @ObservedObject var playerItemObserver = PlayerItemObserver()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var newItem : Bool = false
    @Binding var playerImageOverlayUrl : String
    @Binding var playerTextOverlay : String
    
    var body: some View {
            VideoPlayer(player: player)
            .ignoresSafeArea()
            .onChange(of: playerItem) { value in
                if (self.playerItem != nil) {
                    self.player.replaceCurrentItem(with: self.playerItem)
                    print("PlayerView: replaced current Item \(self.playerItem?.asset)")
                    newItem = true

                }
            }
            .onReceive(timer) { time in
                print("Item Status \(self.playerItem?.status.rawValue)")
                if (newItem && self.playerItem?.status == .readyToPlay){
                    self.player.play()
                    newItem = false
                    print("Play!!")
                }
            }
            .overlay {
                VStack {
                    if !playerImageOverlayUrl.isEmpty {
                        WebImage(url: URL(string: playerImageOverlayUrl))
                            .resizable()
                            .indicator(.activity) // Activity Indicator
                            .transition(.fade(duration: 0.5))
                            .aspectRatio(contentMode: .fill)
                            .frame( width: 600, height: 600)
                            .cornerRadius(15)
                    }
                    
                    if !playerTextOverlay.isEmpty {
                        Text(playerTextOverlay)
                            .foregroundColor(Color.white)
                            .font(.title)
                            .lineLimit(3)
                            .frame(width: 1000, alignment: .center)
                    }
                }
            }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
