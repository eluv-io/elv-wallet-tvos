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
        //MainView2(property: fabric.currentProperty, nfts: fabric.playable)
        NavigationView {
            MainView(nfts:fabric.items)
                .preferredColorScheme(colorScheme)
                .fullScreenCover(isPresented: $fabric.isLoggedOut) {
                    SignInView()
                        .environmentObject(self.fabric)
                        .preferredColorScheme(colorScheme)
                }
                .background(Color.mainBackground)
        }
        .navigationViewStyle(.stack)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Fabric())
            .preferredColorScheme(.dark)
    }
}
