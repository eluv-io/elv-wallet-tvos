//
//  AVPlayerView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-11-21.
//

import SwiftUI
import UIKit
import AVKit


struct AVPlayerView: UIViewControllerRepresentable {

   /* @Binding var videoURL: URL?

    private var player: AVPlayer {
        return AVPlayer(url: videoURL!)
    }
*/
    @Binding var player: AVPlayer
    
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
        //debugPrint("AVPlayerView makeUIViewController()")
        return AVPlayerViewController()
    }
}



