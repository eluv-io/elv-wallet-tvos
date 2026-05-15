//
//  LoopingPlayer.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-06-14.
//

import AVKit
import EluvioCore
import Foundation
import SwiftUI

// Adapted from https://swiftuirecipes.com/blog/play-video-in-swiftui

struct LoopingVideoPlayer<VideoOverlay: View>: View {
  @StateObject private var viewModel: ViewModel
  @ViewBuilder var videoOverlay: () -> VideoOverlay

  init(
    _ playerItems: [AVPlayerItem],
    endAction: EndAction = .none,
    @ViewBuilder videoOverlay: @escaping () -> VideoOverlay
  ) {
    _viewModel = StateObject(
      wrappedValue: ViewModel(playerItems: playerItems, endAction: endAction))
    self.videoOverlay = videoOverlay
  }

  var body: some View {
    // VideoPlayer(player: viewModel.player, videoOverlay: videoOverlay)
    AVLoopingPlayerView(player: $viewModel.player)
      .onDisappear {
        print("AVLoopingPlayerView disappeared!")
        // viewModel.player.pause()
        // viewModel.player.replaceCurrentItem(with: nil)
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
        NotificationCenter.default.addObserver(
          self, selector: #selector(rewindVideo(notification:)),
          name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
      }
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }

    @objc
    func rewindVideo(notification _: Notification) {
      player.seek(to: .zero)
    }
  }

  enum EndAction: Equatable {
    case none,
      loop
    case
      perform(() -> Void)

    static func == (
      lhs: LoopingVideoPlayer<VideoOverlay>.EndAction,
      rhs: LoopingVideoPlayer<VideoOverlay>.EndAction
    ) -> Bool {
      if case .none = lhs,
        case .none = rhs
      {
        return true
      }
      if case .loop = lhs,
        case .loop = rhs
      {
        return true
      }
      if case .perform = lhs,
        case .perform = rhs
      {
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
    var playerItems: [AVPlayerItem] = []
    for url in urls {
      playerItems.append(AVPlayerItem(url: url))
    }

    self.init(playerItems, endAction: endAction) {
      EmptyView()
    }
  }
}
