//
//  AVPlayerView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-11-21.
//

import AVKit
import EluvioCore
import SwiftUI
import UIKit

/// Renders whatever the model is playing. One item or a set of streams look the same here: the
/// stream picker appears as an info tab only once there is more than one to pick from.
struct AVPlayerView: UIViewControllerRepresentable {
  @ObservedObject var viewModel: VideoPlayerViewModel
  @EnvironmentObject var eluvio: EluvioAPI

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.modalPresentationStyle = .fullScreen
    controller.allowsPictureInPicturePlayback = false
    controller.player = viewModel.player
    // Handed over before playback is set up, since analytics attaches to the controller
    viewModel.playerViewController = controller
    return controller
  }

  func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
    if playerController.player !== viewModel.player {
      playerController.player = viewModel.player
    }

    updateStreamSelector(playerController, context: context)
    updateWatchLiveAction(playerController)
  }

  /// The stream picker lives in the info panel, and only exists while there are streams to
  /// choose between.
  private func updateStreamSelector(
    _ playerController: AVPlayerViewController, context: Context
  ) {
    let wanted = viewModel.videos.count > 1
    let installed = playerController.customInfoViewControllers.contains {
      $0 is StreamSelectorViewController
    }
    guard wanted != installed else { return }

    guard wanted else {
      playerController.customInfoViewControllers = []
      return
    }

    let selector =
      context.coordinator.streamSelectorVC
      ?? StreamSelectorViewController(viewModel: viewModel, eluvio: eluvio)
    selector.tabBarItem = UITabBarItem(
      title: "Streams",
      image: UIImage(systemName: "play.rectangle.on.rectangle"),
      tag: 1
    )
    context.coordinator.streamSelectorVC = selector
    playerController.customInfoViewControllers = [selector]
  }

  /// A DVR stream can be rejoined at the live edge, which is worth an action of its own.
  private func updateWatchLiveAction(_ playerController: AVPlayerViewController) {
    guard let urlAsset = viewModel.player?.currentItem?.asset as? AVURLAsset else { return }
    let dvr = urlAsset.url.queryParameters?["dvr"] ?? ""
    guard dvr == "true" || dvr == "1" else { return }

    let watchLive = UIAction(title: "Watch Live") { _ in
      viewModel.watchLive()
    }
    playerController.infoViewActions = [watchLive]
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator {
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
