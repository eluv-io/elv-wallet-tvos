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
import MUXSDKStats

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

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    @EnvironmentObject var viewState: ViewState
    @Environment(\.openURL) private var openURL
    @Namespace var playerNamespace
    @StateObject private var viewModel = VideoPlayerViewModel()
    @State var isPlaying: Bool = false
    var mediaId: String = ""
    var property: MediaProperty?
    var title: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var playerImageOverlayUrl = ""
    @State var playerTextOverlay = ""
    @Binding var finished: Bool
    
    @FocusState private var focusedField: Field?

    var backLink: String = ""
    var backLinkIcon: String = ""

    enum Field: Hashable {
        case startFromBeginningField
    }
    
    var body: some View {
        ZStack{
            AVPlayerView(viewModel: viewModel)
                .environmentObject(self.eluvio)
            .ignoresSafeArea()
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
            Task{
                let initTime = ((Date().now) as NSNumber)
                viewModel.clear()
                viewModel.eluvio = eluvio
                viewModel.propertyId = self.property?.id
                debugPrint("*** PlayerView onAppear()")
                debugPrint("Property: ", self.property?.id)
                debugPrint("Media Id: ", self.mediaId)
                
                if let media = eluvio.fabric.getMediaItem(mediaId: self.mediaId) {
                    
                    var medias: [MediaPropertySectionMediaItem] = []
                    do {
                        medias = try await eluvio.fabric.getPropertyLiveMediaItems(property: property?.id ?? "", exclude:[media.id ?? ""]);

                    } catch {
                        print("Could not get multiview media ", error)
                    }
                    
                    medias.insert(media, at: 0)
                    viewModel.videos = medias
                    viewModel.selectVideo(media)
                    

                }
            }

        }
        .onWillDisappear {
            print("PlayerView onDisappear")
            //self.player.pause()
            //self.player.replaceCurrentItem(with: nil)
            viewModel.clear()
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
            debugPrint("PlayerView2 onAppear ", playoutUrl)
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
