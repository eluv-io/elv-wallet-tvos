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
    @EnvironmentObject var viewState: ViewState
    var logo = "e_logo"
    var logoUrl = ""
    var name = APP_CONFIG.app.name
    
    var body: some View {
        VStack {
            HStack(spacing:20) {
                if !viewState.isBranded {
                    Image(logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:60)
                    Text(name)
                        .foregroundColor(Color.white)
                        .font(.headline)
                }else{
                    Image(logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:250, height:60)
                }
                
            }
            .frame(maxWidth:.infinity, alignment: .leading)
        }
    }
}

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    
    enum Tab { case Items, Media, Profile, Search }
    @State var selection: Tab = Tab.Items
    @State private var cancellable: AnyCancellable? = nil
    @State var logOutTimer = Timer.publish(every:24*60*60, on: .main, in: .common)

    init() {
        UITabBar.appearance().barTintColor = UIColor(white: 1, alpha: 0.2)
    }
    
    var body: some View {
        TabView(selection: $selection) {
            MyItemsView(nfts: fabric.library.items).preferredColorScheme(colorScheme)
                .tabItem{
                    Text("My Items")
                }
                .tag(Tab.Items)
            
            if IsDemoMode(){
                MyMediaViewDemo(library: fabric.library).preferredColorScheme(colorScheme)
                    .tabItem{
                        Text("My Media")
                    }
                    .tag(Tab.Media)
            }else{
                MyMediaView2(library: fabric.library).preferredColorScheme(colorScheme)
                    .tabItem{
                        Text("My Media")
                    }
                    .tag(Tab.Media)
            }
            
            ProfileView().preferredColorScheme(colorScheme)
                .tabItem{
                    Text("Profile")
                }
                .tag(Tab.Profile)
                .preferredColorScheme(.dark)
            
            if IsDemoMode(){
                SearchView().preferredColorScheme(colorScheme)
                    .tabItem{
                        Image(systemName: "magnifyingglass")
                    }
                    .tag(Tab.Search)
            }
             
            
        }
        .onAppear(){
            self.cancellable = fabric.$isLoggedOut.sink { val in
                print("MainView fabric changed, ", val)
                if fabric.isLoggedOut == true {
                    self.selection = Tab.Items
                }
            }
        }
        .onChange(of: selection){ newValue in
            debugPrint("onChange of selection viewState ", viewState.op)
            Task {
                await fabric.refresh()
            }
        }
        .onReceive(logOutTimer) { _ in
            fabric.signOutIfExpired()
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
