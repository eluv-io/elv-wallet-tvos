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
    //@Binding var player: AVPlayer
    //@Binding var playerViewController : AVPlayerViewController
    @ObservedObject var viewModel: VideoPlayerViewModel
    @EnvironmentObject var eluvio : EluvioAPI
    /*
    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        playerController.modalPresentationStyle = .fullScreen
        /*let glasses = UIImage(systemName: "eyeglasses")
        let watchLater = UIAction(title: "Watch Later", image: glasses) { action in
            // Add or remove the item from the user's watch list,
            // and update the action state accordingly.
        }
        // Append the action to the array.
        playerController.infoViewActions.append(watchLater)*/
        playerController.player = player
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        return playerViewController
    }
     */
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = viewModel.player
        
        // Configure for tvOS
        controller.allowsPictureInPicturePlayback = false
        
        // Create default info view controller
        //let defaultInfoVC = DefaultInfoViewController(viewModel: viewModel, eluvio: eluvio)
        
        // Create custom stream selector view controller
        let streamSelectorVC = StreamSelectorViewController(viewModel: viewModel, eluvio: eluvio)
        
        /*
        // Add custom info tabs
        let defaultInfoTab = UITabBarItem(
            title: "Info",
            image: UIImage(systemName: "info.circle"),
            tag: 0
        )
        defaultInfoVC.tabBarItem = defaultInfoTab
         */
        
        let streamSelectorTab = UITabBarItem(
            title: "Streams",
            image: UIImage(systemName: "play.rectangle.on.rectangle"),
            tag: 1
        )
        streamSelectorVC.tabBarItem = streamSelectorTab
        
        // Set custom info view controllers
        controller.customInfoViewControllers = [streamSelectorVC]
        
        context.coordinator.playerViewController = controller
        viewModel.playerViewController = controller
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== viewModel.player {
            uiViewController.player = viewModel.player
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerViewController: AVPlayerViewController?
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



