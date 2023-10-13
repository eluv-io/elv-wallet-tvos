//
//  PlayerView.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-02.
//

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

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @State var player = AVPlayer()
    @Binding var playoutUrl: URL?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var finishedObserver = PlayerFinishedObserver()
    @Binding var finished: Bool
    
    @State var playerItem : AVPlayerItem?
    
    var body: some View {
            VideoPlayer(player: player)
            .ignoresSafeArea()
            .onReceive(finishedObserver.publisher) {
                debugPrint("Video Finished!")
                self.finished = true
            }
            .onReceive(timer) { time in
                /*debugPrint("Timer onReceive ", self.playerItem?.status)*/
                
                /*if (self.playerItem?.status == .readyToPlay){
                    debugPrint("Read to play!")
                    self.player.play()
                }*/
            }
            .onAppear(){
                debugPrint("PlayerView onAppear ", playoutUrl)
                
                if let url = self.playoutUrl {
                    let urlAsset = AVURLAsset(url: url)
                    self.playerItem = AVPlayerItem(asset: urlAsset)
                    self.player.replaceCurrentItem(with: playerItem)
                    self.finished = false
                    self.player.play()
                    self.finishedObserver = PlayerFinishedObserver(player: player)
                    debugPrint("PlayerView onAppear finsihed.")
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
