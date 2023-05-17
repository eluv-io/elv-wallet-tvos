//
//  MainView2.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-15.
//

import SwiftUI
import Combine
import SwiftyJSON

struct MainView2: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var property : JSON
    @State var nfts : [NFTModel]
    
    enum Tab { case Watch, Nfts, Profile }
    @State var selection: Tab = Tab.Watch
    @State private var cancellable: AnyCancellable? = nil
    
    var body: some View {
        NavigationView {
            TabView(selection: $selection) {
                MyItemsView(property: property).preferredColorScheme(colorScheme)
                    .tabItem{
                        Text("My Items")
                    }
                    .tag(Tab.Watch)
                
                MyItemsView(property: property).preferredColorScheme(colorScheme)
                    .tabItem{
                        Text("My Media")
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
        .onChange(of: selection){ newValue in
            if (newValue == Tab.Watch){
                Task {
                    await fabric.refresh()
                }
            }
        }
        .onChange(of: property){ newValue in
            print("property changed")
            /*do {
                self.nfts = try JSONDecoder().decode([NFTModel].self, from:property["contents"][0]["contents"].rawData())
                print ("Decoded NFTS: \(nfts)")
            }catch{
                print("Error decoding NFTs \(error)")
            }*/
        }
    }
}

struct MainView2_Previews: PreviewProvider {
    static var previews: some View {
        MainView2(property: CreateTestProperty(num: 2), nfts: CreateTestNFTs(num: 2), selection: MainView2.Tab.Watch)
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
