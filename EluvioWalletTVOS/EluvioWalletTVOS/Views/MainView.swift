//
//  MainView.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-08-10.
//

import SwiftUI
import Combine
import SwiftyJSON

struct HeaderView: View {
    var logo = "e_logo"
    var logoUrl = ""
    var name = APP_CONFIG.app.name

    var body: some View {
        VStack {
            HStack(spacing:20) {
                Image(logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:60)
                Text(name)
                    .foregroundColor(Color.white)
                    .font(.headline)
                
            }
            .frame(maxWidth:.infinity, alignment: .leading)
        }
    }
}

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    var nfts : [NFTModel] = []
    enum Tab { case Items, Media, Profile, Search }
    @State var selection: Tab = Tab.Items
    @State private var cancellable: AnyCancellable? = nil
    var logo = "e_logo"
    var logoUrl = ""
    var name = "Eluvio Wallet"
    
    init(nfts:[NFTModel] = []) {
        UITabBar.appearance().barTintColor = UIColor(white: 1, alpha: 0.2)
        self.nfts = nfts
    }
    
    var body: some View {
        TabView(selection: $selection) {
            MyItemsView(nfts: nfts,
                        drops: fabric.drops
                        ).preferredColorScheme(colorScheme)
                .tabItem{
                    Text("My Items")
                }
                .tag(Tab.Items)
            
            
            MyMediaView(featured: fabric.featured,
                        library: fabric.library,
                        albums: fabric.albums).preferredColorScheme(colorScheme)
                .tabItem{
                    Text("My Media")
                }
                .tag(Tab.Media)
            
            ProfileView().preferredColorScheme(colorScheme)
                .tabItem{
                    Text("Profile")
                }
                .tag(Tab.Profile)
            
            SearchView().preferredColorScheme(colorScheme)
                .tabItem{
                    Image(systemName: "magnifyingglass")
                }
                .tag(Tab.Search)
            
        }
        //.edgesIgnoringSafeArea(.all)
        .onAppear(){
            self.cancellable = fabric.objectWillChange.sink { val in
                if fabric.isLoggedOut == true {
                    self.selection = Tab.Items
                }
            }
        }
        .onChange(of: selection){ newValue in
            if (newValue == Tab.Profile){
                Task {
                    await fabric.refresh()
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
