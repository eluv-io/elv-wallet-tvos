//
//  AVPlayerView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-11-21.
//

import AVKit
import MUXSDKStats
import SwiftUI
import UIKit

struct AVPlayerView: UIViewControllerRepresentable {
  @Binding var player: AVPlayer
  @Binding var playerViewController: AVPlayerViewController

  var seekS: (Double) -> Void

  func updateUIViewController(_ playerController: AVPlayerViewController, context _: Context) {
    playerController.modalPresentationStyle = .fullScreen

    if let duration = player.currentItem?.duration {
      // debugPrint("##### DURATIION ##### ", duration.isIndefinite)

      if let urlAsset = player.currentItem?.asset as? AVURLAsset {
        // debugPrint("Playout URL: ", urlAsset.url)
        let dvr = urlAsset.url.queryParameters?["dvr"] ?? ""
        let isLive = dvr == "true" || dvr == "1"
        // debugPrint("##### DURATIION READY ##### ", duration.isIndefinite)
        if isLive {
          // let live = UIImage(systemName: "forward.end.fill")
          let watchLive = UIAction(title: "Watch Live" /* , image: live */) { _ in
            guard let playerItem = player.currentItem else { return }
            let seekableRanges = playerItem.seekableTimeRanges
            if let lastRange = seekableRanges.last?.timeRangeValue {
              let liveEdgeTime = CMTimeRangeGetEnd(lastRange)
              // Seek to the end of the last seekable range
              player.seek(
                to: liveEdgeTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
              debugPrint("Seek to the end")
            }
          }

          playerController.infoViewActions = [watchLive]
        }
      }
    }
    playerController.player = player
  }

  func makeUIViewController(context _: Context) -> AVPlayerViewController {
    return playerViewController
  }
}

// MARK: - Multiview AVPlayerView
struct AVPlayerViewMulti: UIViewControllerRepresentable {
  @ObservedObject var viewModel: VideoPlayerViewModel
  @EnvironmentObject var eluvio: EluvioAPI

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = viewModel.player
    controller.allowsPictureInPicturePlayback = false

    var customViewControllers: [UIViewController] = []
    if viewModel.videos.count > 1 {
      let streamSelectorVC = StreamSelectorViewController(viewModel: viewModel, eluvio: eluvio)
      let streamSelectorTab = UITabBarItem(
        title: "Streams",
        image: UIImage(systemName: "play.rectangle.on.rectangle"),
        tag: 1
      )
      streamSelectorVC.tabBarItem = streamSelectorTab
      customViewControllers.append(streamSelectorVC)
      context.coordinator.streamSelectorVC = streamSelectorVC
    }

    controller.customInfoViewControllers = customViewControllers
    context.coordinator.playerViewController = controller
    viewModel.playerViewController = controller

    return controller
  }

  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    if uiViewController.player !== viewModel.player {
      uiViewController.player = viewModel.player
    }

    let shouldShowStreamSelector = viewModel.videos.count > 1
    let hasStreamSelector = uiViewController.customInfoViewControllers.contains {
      $0 is StreamSelectorViewController
    }

    if shouldShowStreamSelector && !hasStreamSelector {
      let streamSelectorVC: StreamSelectorViewController
      if let existingVC = context.coordinator.streamSelectorVC {
        streamSelectorVC = existingVC
      } else {
        streamSelectorVC = StreamSelectorViewController(viewModel: viewModel, eluvio: eluvio)
        let streamSelectorTab = UITabBarItem(
          title: "Streams",
          image: UIImage(systemName: "play.rectangle.on.rectangle"),
          tag: 1
        )
        streamSelectorVC.tabBarItem = streamSelectorTab
        context.coordinator.streamSelectorVC = streamSelectorVC
      }
      uiViewController.customInfoViewControllers = [streamSelectorVC]
    } else if !shouldShowStreamSelector && hasStreamSelector {
      uiViewController.customInfoViewControllers = []
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator {
    var playerViewController: AVPlayerViewController?
    var streamSelectorVC: StreamSelectorViewController?
  }
}

struct AVLoopingPlayerView: UIViewControllerRepresentable {
  @Binding var player: AVQueuePlayer

  func updateUIViewController(_ playerController: AVPlayerViewController, context _: Context) {
    playerController.modalPresentationStyle = .fullScreen
    playerController.player = player
  }

  func makeUIViewController(context _: Context) -> AVPlayerViewController {
    // debugPrint("AVPlayerView makeUIViewController()")
    let controller = AVPlayerViewController()
    controller.showsPlaybackControls = false
    controller.view.isUserInteractionEnabled = false
    return controller
  }
}
