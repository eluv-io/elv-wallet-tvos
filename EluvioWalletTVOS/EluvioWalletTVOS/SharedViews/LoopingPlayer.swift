//
//  LoopingPlayer.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-06-14.
//



import SwiftUI
import AVKit
import Foundation

//Adapted from https://swiftuirecipes.com/blog/play-video-in-swiftui

struct LoopingVideoPlayer<VideoOverlay: View>: View {
    @StateObject private var viewModel: ViewModel
    @ViewBuilder var videoOverlay: () -> VideoOverlay
    
    init(_ playerItems: [AVPlayerItem],
         endAction: EndAction = .none,
         @ViewBuilder videoOverlay: @escaping () -> VideoOverlay) {
        _viewModel = StateObject(wrappedValue: ViewModel(playerItems: playerItems, endAction: endAction))
        self.videoOverlay = videoOverlay
    }
    
    
    var body: some View {
        //VideoPlayer(player: viewModel.player, videoOverlay: videoOverlay)
        AVLoopingPlayerView(player: $viewModel.player)
            .onDisappear {
                print("ContentView disappeared!")
                viewModel.player.pause()
                viewModel.player.replaceCurrentItem(with: nil)
            }
    }
    
    class ViewModel: ObservableObject {
        var player: AVQueuePlayer
        
        init(playerItems: [AVPlayerItem], endAction: EndAction) {

            player = AVQueuePlayer(items: playerItems)
            player.actionAtItemEnd = .none
            player.volume = 0.0
            player.play()
            
            if endAction != .none {
                NotificationCenter.default.addObserver(self, selector: #selector(rewindVideo(notification:)),
                                                       name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            }
        }
        
        @objc
        func rewindVideo(notification: Notification) {
            player.seek(to: .zero)
        }
    }
    
    enum EndAction: Equatable {
        case none,
             loop,
             perform(() -> Void)
        
        static func == (lhs: LoopingVideoPlayer<VideoOverlay>.EndAction,
                        rhs: LoopingVideoPlayer<VideoOverlay>.EndAction) -> Bool {
            if case .none = lhs,
               case .none = rhs {
                return true
            }
            if case .loop = lhs,
               case .loop = rhs {
                return true
            }
            if case .perform(_) = lhs,
               case .perform(_) = rhs {
                return true
            }
            return false
        }
    }
}

extension LoopingVideoPlayer where VideoOverlay == EmptyView {
    init(_ playerItems: [AVPlayerItem], endAction: EndAction) {
        self.init(playerItems, endAction: endAction) {
            EmptyView()
        }
    }
    
    init(urls: [URL], endAction: EndAction) {
        
        var playerItems : [AVPlayerItem] = []
        for url in urls {
            playerItems.append(AVPlayerItem(url: url))
        }
        
        self.init(playerItems, endAction: endAction) {
            EmptyView()
        }
    }
}
