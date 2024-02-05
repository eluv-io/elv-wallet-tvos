//
//  AudioPlayer.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-02-04.
//

import Foundation

import AVFoundation

 class AudioPlayer {

     static var isPlaying: Bool {
         return audioPlayer?.isPlaying ?? false
     }
     static var audioPlayer:AVAudioPlayer?
     static var timer:Timer?

     static func play(url: URL, seekS: TimeInterval = 0.0, progressCallback: @escaping (TimeInterval,TimeInterval)->()) {
        do{
            stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            if seekS > 0.0 {
                debugPrint("AudioPlayer seek \(seekS)")
                let shortStartDelay: TimeInterval = 0.01    // seconds
                let now: TimeInterval = audioPlayer?.deviceCurrentTime ?? 0
                let timeDelayPlay: TimeInterval = now + shortStartDelay
                audioPlayer?.currentTime = seekS
                audioPlayer?.play(atTime: timeDelayPlay)
            }else{
                audioPlayer?.play()
            }
           
           timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
               if let player = audioPlayer {
                   if player.isPlaying {
                       progressCallback(player.currentTime, player.duration)
                   }
               }
           }

        }catch {
           print("Error")
        }
     }
     
     static func pause() {
         audioPlayer?.pause()
     }
     
     static func stop() {
         audioPlayer?.stop()
     }
}

