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

enum MainTab { case Discover, Items, Profile}

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @EnvironmentObject var pathState: PathState
    @Namespace var MAIN
    

    @State var selection: MainTab = MainTab.Discover
    @State private var cancellable: AnyCancellable? = nil
    @State var logOutTimer = Timer.publish(every:24*60*60, on: .main, in: .common)
    @FocusState var navFocused
    @State var showNav = false
    @State var navDisabled = true
    @State var justDismissed = false
    
    init() {
        UITabBar.appearance().barTintColor = UIColor(white: 1, alpha: 0.2)
    }
    
    var body: some View {
        ZStack{
            TabView(selection:$selection){
                DiscoverView().preferredColorScheme(colorScheme)
                    .environmentObject(self.pathState)
                    .prefersDefaultFocus(in: MAIN)
                    .opacity(selection == .Discover ? 1.0 : 0.0)
                    .tabItem{Text("Home")}
                    .tag(MainTab.Discover)
                
                MyItemsView(nfts: fabric.library.items).preferredColorScheme(colorScheme)
                    .environmentObject(self.pathState)
                    .opacity(selection == .Items ? 1.0 : 0.0)
                    .tabItem{Text("My Items")}
                    .tag(MainTab.Items)
                
                ProfileView().preferredColorScheme(colorScheme)
                    .environmentObject(self.pathState)
                    .opacity(selection == .Profile ? 1.0 : 0.0)
                    .preferredColorScheme(.dark)
                    .tabItem{Text("Profile")}
                    .tag(MainTab.Profile)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear(){
            debugPrint("MainView onAppear")
            self.cancellable = fabric.$isLoggedOut.sink { val in
                print("MainView fabric changed, ", val)
                if fabric.isLoggedOut == true {
                    self.selection = MainTab.Discover
                }
            }
            Task {
                await MainActor.run {
                    navDisabled = false
                }
            }
        }
        .onChange(of: selection){
            debugPrint("onChange of selection viewState ", viewState.op)
            Task {
                await fabric.refresh()
            }
        }
        .onChange(of: navFocused){ old,new in
            debugPrint("on Nav Focused ", new)
            debugPrint("justDismissed ", justDismissed)
            
            if (new){
                if (!justDismissed){
                    debugPrint("showing nav ")
                    navDisabled = true
                    showNav = true
                }else{
                    //navFocused = false
                    justDismissed = false
                }
            }
            
        }
        .onChange(of: navDisabled){ old,new in
            debugPrint("on Nav navDisabled ", new)
            /*
            if (new) {
                Task {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(3 * Double(NSEC_PER_SEC)))
                        await MainActor.run {
                            //navDisabled = false
                        }
                    }catch{}
                }
            }
             */
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
