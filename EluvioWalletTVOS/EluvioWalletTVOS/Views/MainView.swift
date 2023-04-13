//
//  MainView.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-08-10.
//

import SwiftUI
import Combine

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    var nfts : [NFTModel]
    var playable : [NFTModel]
    
    enum Tab { case Watch, Nfts, Profile }
    @State var selection: Tab = Tab.Watch
    @State private var cancellable: AnyCancellable? = nil
    
    var body: some View {
        NavigationView {
            TabView(selection: $selection) {
                WalletView(nfts: playable).preferredColorScheme(colorScheme)
                    .tabItem{
                        Text("Watch")
                    }
                    .tag(Tab.Watch)
                
                WalletView(nfts: nfts).preferredColorScheme(colorScheme)
                    .tabItem{
                        Text("NFTs")
                    }
                    .tag(Tab.Nfts)
                
                ProfileView().preferredColorScheme(colorScheme)
                    .tabItem{
                        Text("Profile")
                    }
                    .tag(Tab.Profile)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear(){
            self.cancellable = fabric.objectWillChange.sink { val in
                if fabric.isLoggedOut == true {
                    self.selection = Tab.Watch
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(nfts: CreateTestNFTs(num: 10), playable: CreateTestNFTs(num: 10), selection: MainView.Tab.Watch)
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
