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
    @Binding var player: AVPlayer
    @Binding var playerViewController : AVPlayerViewController
    
    var seekS : (Double) -> Void
    
    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        playerController.modalPresentationStyle = .fullScreen
        
        if let duration = player.currentItem?.duration {
            //debugPrint("##### DURATIION ##### ", duration.isIndefinite)
            
            if let urlAsset = player.currentItem?.asset as? AVURLAsset {
                //debugPrint("Playout URL: ", urlAsset.url)
                let dvr = urlAsset.url.queryParameters?["dvr"] ?? ""
                let isLive = dvr == "true" || dvr == "1"
                //debugPrint("##### DURATIION READY ##### ", duration.isIndefinite)
                if isLive {
                    //let live = UIImage(systemName: "forward.end.fill")
                    let watchLive = UIAction(title: "Watch Live"/*, image: live*/) { action in
                        guard let playerItem = player.currentItem else { return }
                        let seekableRanges = playerItem.seekableTimeRanges
                        if let lastRange = seekableRanges.last?.timeRangeValue {
                            let liveEdgeTime = CMTimeRangeGetEnd(lastRange)
                            // Seek to the end of the last seekable range
                            player.seek(to: liveEdgeTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                            debugPrint("Seek to the end")
                        }
                    }

                    playerController.infoViewActions = [watchLive]
                
                }
            }
        }
        playerController.player = player
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        return playerViewController
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



