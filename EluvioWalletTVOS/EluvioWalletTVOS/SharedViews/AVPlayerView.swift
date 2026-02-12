//
//  AVPlayerView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-11-21.
//

import SwiftUI
import UIKit
import AVKit
import MUXSDKStats

struct AVPlayerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @EnvironmentObject var eluvio : EluvioAPI
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = viewModel.player
        
        // Configure for tvOS
        controller.allowsPictureInPicturePlayback = false
        // Only show stream selector tab if there are multiple videos
        var customViewControllers: [UIViewController] = []

        if viewModel.videos.count > 1 {

            // Create custom stream selector view controller
            let streamSelectorVC = StreamSelectorViewController(viewModel: viewModel, eluvio: eluvio)

            let streamSelectorTab = UITabBarItem(
                title: "Streams",
                image: UIImage(systemName: "play.rectangle.on.rectangle"),
                tag: 1
            )
            streamSelectorVC.tabBarItem = streamSelectorTab

            customViewControllers.append(streamSelectorVC)

            // Store reference in coordinator to reuse later
            context.coordinator.streamSelectorVC = streamSelectorVC
        }

        // Set custom info view controllers (empty array if no multiple videos)
        controller.customInfoViewControllers = customViewControllers
        context.coordinator.playerViewController = controller
        viewModel.playerViewController = controller
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== viewModel.player {
            uiViewController.player = viewModel.player
        }

        // Update custom info view controllers based on videos count
        let shouldShowStreamSelector = viewModel.videos.count > 1
        let hasStreamSelector = uiViewController.customInfoViewControllers.contains { $0 is StreamSelectorViewController }

        if shouldShowStreamSelector && !hasStreamSelector {
            // Reuse existing stream selector if available, otherwise create new one
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
            // Remove stream selector tab
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
    
    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        playerController.modalPresentationStyle = .fullScreen
        playerController.player = player
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        //debugPrint("AVPlayerView makeUIViewController()")
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.view.isUserInteractionEnabled = false
        return controller
    }
}



