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
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var newItem : Bool = false
    @Binding var playerImageOverlayUrl : String
    @Binding var playerTextOverlay : String
    
    var body: some View {
            VideoPlayer(player: player)
            .ignoresSafeArea()
            .onChange(of: playerItem) { value in
                if (self.playerItem != nil) {
                    self.player.replaceCurrentItem(with: self.playerItem)
                    print("PlayerView: replaced current Item \(self.playerItem?.asset)")
                    newItem = true

                }
            }
            .onReceive(timer) { time in
                print("Item Status \(self.playerItem?.status.rawValue)")
                if (newItem && self.playerItem?.status == .readyToPlay){
                    self.player.play()
                    newItem = false
                    print("Play!!")
                }
            }
            .overlay {
                VStack {
                    if !playerImageOverlayUrl.isEmpty {
                        CacheAsyncImage(url: URL(string: playerImageOverlayUrl)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame( width: 600, height: 600)
                                .cornerRadius(15)
                        } placeholder: {
                            
                        }
                    }
                    
                    if !playerTextOverlay.isEmpty {
                        Text(playerTextOverlay)
                            .foregroundColor(Color.white)
                            .font(.title)
                            .lineLimit(3)
                            .frame(width: .infinity, alignment: .center)
                    }
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
