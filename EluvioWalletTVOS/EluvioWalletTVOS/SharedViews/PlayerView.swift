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
    @State var currentTimeS: Double = -1
    @Binding var finished: Bool
    var progressCallback: ((_ progress: Double,_ currentTimeS: Double,_ durationS: Double)->Void )?
    
    @FocusState private var focusedField: Field?

    var backLink: String = ""
    var backLinkIcon: String = ""

    enum Field: Hashable {
        case startFromBeginningField
    }
    
    var hasSeeked : Bool {
        return currentTimeS > seekTimeS
    }

    var body: some View {
        ZStack{
            AVPlayerView(player: $player)
            .ignoresSafeArea()
            
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
                
                currentTimeS = player.currentItem?.currentTime().seconds ?? -1.0
                
                if currentTimeS == -1.0 {
                    return
                }
                
                /*if self.player.status == .readyToPlay {
                    debugPrint("Play")

                }*/
                
                if let progressCallback = self.progressCallback {
                    progressCallback(progress,
                                     player.currentItem?.currentTime().seconds ?? 0.0,
                                     player.currentItem?.duration.seconds ?? 0.0)
                }
            }
            
            
            //TODO: Fix the playing from start end then seeking
            self.player.seek(to: CMTime(seconds: seekTimeS, preferredTimescale: 1),
                             toleranceBefore: .zero, toleranceAfter: .zero
            )
            player.play()

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
}

struct PlayerView2: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @State var player = AVPlayer()
    @State var playoutUrl: URL?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var finishedObserver = PlayerFinishedObserver()
    @Binding var finished: Bool
    
    @State var playerItem : AVPlayerItem?
    @Binding var currentTimeMS: Int64
    @Binding var durationMS: Int64
    @Binding var seekTimeMS: Int64
    @Binding var playPause: Bool
    
    init(playoutUrl: URL?, finished : Binding<Bool> = .constant(false),
         currentTimeMS: Binding<Int64> = .constant(0),
         durationMS: Binding<Int64> = .constant(0),
         seekTimeMS: Binding<Int64> = .constant(0),
         playPause: Binding<Bool> = .constant(false)
    ){
        
        _finished = finished
        _currentTimeMS = currentTimeMS
        _durationMS = durationMS
        _seekTimeMS = seekTimeMS
        _playoutUrl = State(initialValue: playoutUrl)
        _playPause = playPause
    }
    
    func seekMS(_ ms: Double){
        debugPrint("PlayerView seekMS ", ms)
        self.player.pause()
        self.player.seek(to: CMTime(seconds:ms / 1000, preferredTimescale: 1))
        self.player.play()
    }
    
    var body: some View {
        ZStack{
            VideoPlayer(player: player)
        }
        .onChange(of:seekTimeMS){
            seekMS(Double(seekTimeMS))
        }
        .onChange(of:playPause){
            if playPause == true {
                player.play()
            }else{
                player.pause()
            }
        }
        .ignoresSafeArea()
        .onReceive(finishedObserver.publisher) {
            debugPrint("Video Finished!")
            self.finished = true
        }
        .onReceive(timer) { time in
        }
        .onAppear(){
            debugPrint("PlayerView onAppear ", playoutUrl)
            if let url = self.playoutUrl {
                let urlAsset = AVURLAsset(url: url)
                self.playerItem = AVPlayerItem(asset: urlAsset)
                self.player.replaceCurrentItem(with: playerItem)
                self.finished = false
                //self.player.seek(to: CMTime(seconds:240, preferredTimescale: 1))
                self.player.play()
                self.finishedObserver = PlayerFinishedObserver(player: player)
                debugPrint("PlayerView onAppear finsihed.")
                
                player.addProgressObserver(intervalSeconds:0.1) { progress in

                    //debugPrint("Player progress: ", progress)
                    //debugPrint("Player duration seconds: ", player.currentItem?.duration.seconds)
                    //debugPrint("Player currentTime seconds: ", player.currentItem?.currentTime().seconds)
                    
                    let currentTimeS = player.currentItem?.currentTime().seconds ?? -1.0
                    
                    if currentTimeS == -1.0 {
                        return
                    }
                    
                    if (currentTimeS.isNormal) {
                        currentTimeMS = Int64(currentTimeS * 1000)
                    }
                    let duration = player.currentItem?.duration.seconds ?? 0.0
                    if duration.isNormal {
                        self.durationMS = Int64(duration * 1000)
                    }
                    
                    if player.timeControlStatus == .playing && !playPause{
                        playPause = true
                    }
                }
            }
        }
        .onDisappear(){
            if let playerItem = self.player.currentItem {
                self.player.pause()
            }
        }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("Video Finished")
    }
}

struct SoundPlayer: View {
    @State var playoutUrl: URL?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var finishedObserver = PlayerFinishedObserver()
    @Binding var finished: Bool
    @Binding var currentTimeMS: Int64
    @Binding var durationMS: Int64
    @Binding var seekTimeMS: Int64
    @Binding var playPause: Bool
    @State var audioPlayer :AVAudioPlayer?
    
    init(playoutUrl: URL?, finished : Binding<Bool> = .constant(false),
         currentTimeMS: Binding<Int64> = .constant(0),
         durationMS: Binding<Int64> = .constant(0),
         seekTimeMS: Binding<Int64> = .constant(0),
         playPause: Binding<Bool> = .constant(false)
    ){
        
        _finished = finished
        _currentTimeMS = currentTimeMS
        _durationMS = durationMS
        _seekTimeMS = seekTimeMS
        _playoutUrl = State(initialValue: playoutUrl)
        _playPause = playPause
    }
    
    var body: some View {
        Image(systemName: playPause ? "mic.fill" : "mic")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width:48, height:48)
            .foregroundColor(playPause ? .blue : .white)
    
        .onChange(of:seekTimeMS){
            AudioPlayer.pause()
            self.play()
        }
        .onChange(of:playPause){
            self.play()
        }
        .onAppear(){
            debugPrint("SoundPlayer on Appear ", playoutUrl)
            self.play()
        }
        .onDisappear(){
            AudioPlayer.pause()
        }
    }
    
    func play() {
        if playPause {
            if let audioUrl = playoutUrl {
                AudioPlayer.play(url:audioUrl, seekS: Double(_seekTimeMS.wrappedValue) / 1000.0) { current, duration in
                    debugPrint("AudioProgress: current \(current) duration \(duration)")
                    if current.isNormal {
                        self.currentTimeMS = Int64(current * 1000)
                    }
                    
                    if duration.isNormal {
                        self.durationMS = Int64(duration * 1000)
                    }
                    
                    if currentTimeMS == durationMS {
                        finished = true
                    }
                }
            }
        }else {
            AudioPlayer.pause()
        }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("Video Finished")
    }
}
