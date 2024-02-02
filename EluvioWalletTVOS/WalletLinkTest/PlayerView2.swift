//
//  PlayerView.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-02.
//

/*
import Foundation
import SwiftUI
import AVKit
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

extension AVPlayer {
    func addProgressObserver(intervalSeconds: Double = 5, action:@escaping ((Double) -> Void)) -> Any {
        return self.addPeriodicTimeObserver(forInterval: CMTime.init(value: Int64(intervalSeconds *  1000), timescale: 1000), queue: .main, using: { time in
            if let duration = self.currentItem?.duration {
                let duration = CMTimeGetSeconds(duration), time = CMTimeGetSeconds(time)
                let progress = (time/duration)
                action(progress)
            }
        })
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
            /*HStack(alignment:.top){
                Spacer()
                VStack{
                    Text("\(currentTimeMS.msToSeconds.hourMinuteSecond)")
                        .font(.scriptTimeStart)
                        .frame(alignment:.topTrailing)
                    Spacer()
                }
            }*/
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
*/
