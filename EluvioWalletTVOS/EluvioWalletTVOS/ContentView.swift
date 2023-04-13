//
//  ContentView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric

    
    var body: some View {
        
        MainView(nfts: fabric.nonPlayable, playable: fabric.playable)
            .preferredColorScheme(colorScheme)
            .fullScreenCover(isPresented: $fabric.isLoggedOut) {
                SignInView()
                    .environmentObject(self.fabric)
                    .preferredColorScheme(colorScheme)
            }
            .background(Color.mainBackground)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Fabric())
            .preferredColorScheme(.dark)
    }
}
