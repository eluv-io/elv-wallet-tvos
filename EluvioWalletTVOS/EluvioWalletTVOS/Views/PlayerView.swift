//
//  PlayerView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-10.
//

import SwiftUI
import AVKit

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var player = AVPlayer()
    @State var isPlaying: Bool = false
    @Binding var playerItem : AVPlayerItem?
    
    var body: some View {
            VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear(perform:{
                print("PlayerView: onAppear \(self.playerItem)")
                if (self.playerItem != nil) {
                    self.player.replaceCurrentItem(with: self.playerItem)
                    print("PlayerView: replaced current Item \(self.playerItem?.asset)")
                    self.player.play()
                }
            })
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
