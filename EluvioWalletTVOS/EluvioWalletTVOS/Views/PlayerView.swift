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
import Combine

class PlayerFinishedObserver: ObservableObject {

    @Published
    var publisher = PassthroughSubject<Void, Never>()

    init(player: AVPlayer? = nil) {
        if let player = player {
            let item = player.currentItem
            
            var cancellable: AnyCancellable?
            cancellable = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item).sink { [weak self] change in
                self?.publisher.send()
                cancellable?.cancel()
            }
        }
    }
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
    var progressCallback: ((_ progress: Double,_ currentTimeS: Double,_ durationS: Double)->Void )?

    var body: some View {
        VideoPlayer(player: player)
        .ignoresSafeArea()
        .onReceive(timer) { time in
            //print("Item Status \(self.playerItem?.status.rawValue)")
            if (newItem && self.playerItem?.status == .readyToPlay){
                self.player.play()
                newItem = false
                //print("Play!!")
            }
        }
        .onDisappear {
            print("ContentView disappeared!")
            self.player.pause()
            self.player.replaceCurrentItem(with: nil)
        }
        .onAppear(){
            player.addProgressObserver { progress in
                if let progressCallback = self.progressCallback {
                    progressCallback(progress,
                                     player.currentItem?.currentTime().seconds ?? 0.0,
                                     player.currentItem?.duration.seconds ?? 0.0)
                }
                
            }
            
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
    @Environment(\.openURL) private var openURL
    @Namespace var playerNamespace
    @State var player = AVPlayer()
    @State var isPlaying: Bool = false
    @Binding var playerItem : AVPlayerItem?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var newItem : Bool = false
    @State var playerImageOverlayUrl = ""
    @State var playerTextOverlay = ""
    @State var finishedObserver = PlayerFinishedObserver()
    var seekTimeS: Double
    @Binding var finished: Bool
    var progressCallback: ((_ progress: Double,_ currentTimeS: Double,_ durationS: Double)->Void )?
    
    @FocusState private var focusedField: Field?
    
    @State var showRestartButton = false
    var backLink: String = ""
    var backLinkIcon: String = ""

    enum Field: Hashable {
        case startFromBeginningField
    }

    var body: some View {
        ZStack{
            VideoPlayer(player: player)
                .ignoresSafeArea()
            
            if showRestartButton {
                VStack(alignment:.leading) {
                    Spacer()
                    HStack{
                        Button {
                            self.player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                            showRestartButton = false
                        } label: {
                            HStack(spacing:10){
                                Image(systemName: "play.fill")
                                Text("From Beginning")
                            }
                        }
                        .focused($focusedField, equals: .startFromBeginningField)
                        .padding()
                        .padding(.bottom,100)
                        Spacer()
                    }
                }
            }
        }
        .defaultFocus($focusedField, .startFromBeginningField)
            /*.onReceive(timer) { time in
                //print("Item Status \(self.playerItem?.status.rawValue)")
                if (newItem && self.playerItem?.status == .readyToPlay){
                    if seekTimeS > 5.0 {
                        self.player.seek(to: CMTime(seconds: seekTimeS, preferredTimescale: 1))
                    }
                    self.player.play()
                    newItem = false
                    debugPrint("Play!!")
                }
                
            }*/
        .onChange(of: focusedField) {
            if focusedField != .startFromBeginningField {
                showRestartButton = false
            }
        }
            .onReceive(finishedObserver.publisher) {
                print("Finished!")
                self.finished = true
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
            .onAppear(){
                print("*** PlayerView onAppear() ")
                //print("PlayerItem",self.playerItem)
                if (self.playerItem != self.player.currentItem){
                    self.player.replaceCurrentItem(with: self.playerItem)
                    print("player.replaceCurrentItem()")
                }
                
                player.addProgressObserver { progress in

                    debugPrint("Player progress: ", progress)
                    debugPrint("Player duration seconds: ", player.currentItem?.duration.seconds)
                    debugPrint("Player currentTime seconds: ", player.currentItem?.currentTime().seconds)
                    
                    if let progressCallback = self.progressCallback {
                        progressCallback(progress,
                                         player.currentItem?.currentTime().seconds ?? 0.0,
                                         player.currentItem?.duration.seconds ?? 0.0)
                    }
                    
                    if player.currentItem?.duration.seconds ?? 0 > 0{
                        if showRestartButton {
                            Task {
                                await removeButtons()
                            }
                        }
                    }
                    
                }
                
                
                //TODO: Fix the playing from start end then seeking
                //self.player.seek(to: CMTime(seconds: seekTimeS, preferredTimescale: 1))
                self.player.play()
                
                if !showRestartButton && seekTimeS > 0 {
                    //showRestartButton = true
                }
                print("*** PlayerView PLAY", seekTimeS)

                newItem = true
                self.finishedObserver = PlayerFinishedObserver(player: player)

            }
            .onWillDisappear {
                print("PlayerView onDisappear")
                self.player.pause()
                self.player.replaceCurrentItem(with: nil)
                if backLink != "" {
                    if let url = URL(string: backLink) {
                        openURL(url) { accepted in
                            print(accepted ? "Success" : "Failure")
                            if (!accepted){
                                print("Could not open URL ", backLink)
                            }else{
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("Video Finished")
    }
    
    private func removeButtons() async {
        try? await Task.sleep(nanoseconds: 10_000_000_000)
        showRestartButton = false
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
