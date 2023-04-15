//
//  PlayerView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-10.
//

import Foundation
import SwiftUI
import AVKit

class PlayerItemObserver: NSObject, ObservableObject {
    @Published var playerItemContext = 0
}

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var player = AVPlayer()
    @State var isPlaying: Bool = false
    @Binding var playerItem : AVPlayerItem?
    @ObservedObject var playerItemObserver = PlayerItemObserver()
    
    var body: some View {
            VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear(perform:{
                print("PlayerView: onAppear \(self.playerItem)")
                if (self.playerItem != nil) {
                    self.playerItem!.addObserver(playerItemObserver,
                                           forKeyPath: #keyPath(AVPlayerItem.status),
                                           options: [.old, .new],
                                                context: &playerItemObserver.$playerItemContext)
                    
                    self.player.replaceCurrentItem(with: self.playerItem)
                    print("PlayerView: replaced current Item \(self.playerItem?.asset)")
                }
            })
            .onChange(of: playerItemObserver.playerItemContext) { value in
                if playerItem?.status == .readyToPlay {
                    print("current item status is ready")
                    self.player.play()
                }
            }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
