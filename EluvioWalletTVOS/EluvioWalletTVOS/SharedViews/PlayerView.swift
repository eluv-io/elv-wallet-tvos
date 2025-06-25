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
    @State var player = AVPlayer()
    @State var playerViewController = AVPlayerViewController()
    @State var isPlaying: Bool = false
    var mediaId: String = ""
    var playerItem : AVPlayerItem?
    var property: MediaProperty?
    var title: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var newItem : Bool = false
    @State var playerImageOverlayUrl = ""
    @State var playerTextOverlay = ""
    @State var finishedObserver = PlayerFinishedObserver()
    var seekTimeS: Double = 0
    @State var currentTimeS: Double = -1
    @Binding var finished: Bool
    var progressCallback: ((_ progress: Double,_ currentTimeS: Double,_ durationS: Double)->Void )?
    
    @FocusState private var focusedField: Field?

    var backLink: String = ""
    var backLinkIcon: String = ""
    @State var audioLoaded = false

    enum Field: Hashable {
        case startFromBeginningField
    }
    
    var hasSeeked : Bool {
        return currentTimeS > seekTimeS
    }
    func seekS(_ s: Double){
        debugPrint("PlayerView seeMS ", s)
        self.player.pause()
        self.player.seek(to: CMTime(seconds:s, preferredTimescale: 1))
        self.player.play()
    }

    var body: some View {
        ZStack{
            AVPlayerView(player: $player, playerViewController: $playerViewController)
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
            Task{
                let initTime = ((Date().now) as NSNumber)
                debugPrint("*** PlayerView onAppear() ", self.playerItem)
                //print("PlayerItem",self.playerItem)
                if self.playerItem == nil {
                    print("playerItem == nil")
                    return
                }
                if (self.playerItem != self.player.currentItem){
                    self.player.replaceCurrentItem(with: playerItem)
                    print("player.replaceCurrentItem()")
                }
                    
                var objectId: String = ""
                var versionHash: String = ""
                var videoHostname: String = ""
                var userId: String = ""
                var tenantId: String = ""
                var sessionId: String = ""
                var offering: String = ""
                
                if let account = eluvio.accountManager.currentAccount {
                    //If our token expires in 4 hours we force a sign in.
                    if (account.isTokenExpiredIn(seconds: 60*60*4)){
                        _ = eluvio.pathState.path.popLast()
                        eluvio.viewState.login(eluvio: eluvio)
                        return;
                    }
                    
                    let address = account.getAccountAddress()
                    debugPrint("Address ", address)
                    
                    //FIXME: Can't find viewer_user_id to store userId
                    userId = Hash(account.getAccountAddress());
                    debugPrint("UserID: ", userId)
                }
                
                if let urlAsset = self.playerItem?.asset as? AVURLAsset {
                    debugPrint("Playout URL: ", urlAsset.url)
                    videoHostname = urlAsset.url.host() ?? ""
                    
                    let pathComponents = urlAsset.url.pathComponents
                    if pathComponents.count > 2 {
                        debugPrint("PATH: ", pathComponents[2])
                        if pathComponents[2].hasPrefix("hq_") {
                            versionHash = pathComponents[2]
                            debugPrint("HASH: ", versionHash)
                        }
                    }
                    
                    sessionId = urlAsset.url.queryParameters?["sid"] ?? ""
                    debugPrint("sessionId ", sessionId)
                    
                    let reg = /\/rep\/(playout|channel)\/([^\/]+)/
                    
                    if let match = urlAsset.url.absoluteString.firstMatch(of:reg) {
                        debugPrint("match 1", match.1)
                        debugPrint("match 2", match.2)
                        offering = String(match.2)
                        debugPrint("offering", offering)
                    }
                    
                    if !versionHash.isEmpty {
                        let dec = DecodeVersionHash(versionHash: versionHash)
                        debugPrint("Decoded VersionHash ", dec)
                        if !dec.objectId.isEmpty {
                            objectId = dec.objectId
                            debugPrint("objectId ", objectId)
                            
                            do {
                                tenantId = try await eluvio.fabric.getTenantId(objectId: objectId)
                                debugPrint("tenantID: ", tenantId)
                            }catch {
                                print("Could not get tenantId from object \(objectId).", error);
                            }
                            
                        }
                    }
                    
                }
                
                //debugPrint("AVPlayerView makeUIViewController()")
                let playerData = MUXSDKCustomerPlayerData(environmentKey: APP_CONFIG.network[eluvio.fabric.network]?.mux.env_key ?? "");
                // insert player metadata
                playerData?.playerName = "AVPlayer"
                playerData?.subPropertyId = tenantId
                playerData?.viewerUserId = userId
                playerData?.playerInitTime = initTime
                
                let videoData = MUXSDKCustomerVideoData()
                // insert videoData metadata
                videoData.videoId = objectId
                videoData.videoVariantId = versionHash
                videoData.videoVariantName = offering
                videoData.videoTitle = self.title
                videoData.videoCdn = videoHostname
                
                let viewData = MUXSDKCustomerViewData()
                viewData.viewSessionId = sessionId
                
                
                if let customerData = MUXSDKCustomerData(customerPlayerData: playerData, videoData: videoData, viewData: viewData, customData: nil, viewerData: nil){
                    let playerBinding = MUXSDKStats.monitorAVPlayerViewController(self.playerViewController, withPlayerName: "mainPlayer", customerData: customerData)
                    debugPrint("MUX initialized.")
                }
                
                
                player.addProgressObserver { progress in
                    
                    currentTimeS = player.currentItem?.currentTime().seconds ?? -1.0
                    
                    if currentTimeS == -1.0 {
                        return
                    }
                    
                    if let progressCallback = self.progressCallback {
                        progressCallback(progress,
                                         player.currentItem?.currentTime().seconds ?? 0.0,
                                         player.currentItem?.duration.seconds ?? 0.0)
                    }else {
                        self.onPlayerProgress(progress,
                                              player.currentItem?.currentTime().seconds ?? 0.0,
                                              player.currentItem?.duration.seconds ?? 0.0)
                    }
                    
                    if player.status == .readyToPlay {
                        if !audioLoaded {
                            if let group = playerItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
                                debugPrint("group options ", group.options)
                                debugPrint("group default option", group.defaultOption)
                                if let defaultOption = group.defaultOption {
                                    playerItem?.select(defaultOption, in: group)
                                }else {
                                    playerItem?.select(group.options.first, in: group)
                                }
                            }
                            audioLoaded = true
                        }
                    }
                    
                }
                
                NotificationCenter.default.addObserver(forName: .AVPlayerItemNewErrorLogEntry, object: player.currentItem, queue: .main) { [self] _ in
                    print(player.currentItem?.errorLog()?.events.last?.errorComment)
                }
                
                if seekTimeS == 0 {
                    do {
                        if let account = eluvio.accountManager.currentAccount {
                            let progress = try eluvio.fabric.getUserViewedProgress(address:account.getAccountAddress(), mediaId: mediaId)
                            debugPrint("Finsihed getting progress ", progress)
                            seekS(progress.current_time_s)
                        }
                    }catch{
                        debugPrint(error)
                    }
                }else {
                    seekS(seekTimeS)
                }

                player.play()
                print("*** PlayerView errors: ", player.error)
                

                newItem = true
                self.finishedObserver = PlayerFinishedObserver(player: player)
            }

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
    
    func onPlayerProgress(_ progress: Double,_ currentTimeS: Double,_ durationS: Double) {
        debugPrint("progress observer mediaId ", mediaId)
        debugPrint("onPlayerProgress progress: ", progress)
        debugPrint("onPlayerProgress duration seconds: ", durationS)
        debugPrint("onPlayerProgress currentTime seconds: ", currentTimeS)

        if mediaId.isEmpty {
            return
        }
        
        if durationS.isNaN || durationS.isInfinite {
            return
        }
        
        let mediaProgress = MediaProgress(id: mediaId,  duration_s: durationS, current_time_s: currentTimeS)

        do {
            if let account = eluvio.accountManager.currentAccount {
                try eluvio.fabric.setUserViewedProgress(address:account.getAccountAddress(), mediaId: mediaId, progress:mediaProgress)
                debugPrint("Finsihed setting progress.")
            }
        }catch{
            print(error)
        }
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
