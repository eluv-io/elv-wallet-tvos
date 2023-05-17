//
//  MainView.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-08-10.
//

import SwiftUI
import Combine
import SwiftyJSON

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    
    var property : JSON
    @State var nfts : [NFTModel] = []
    
    enum Tab: Hashable { case items, media, profile, search }
    @State var selection: Tab = Tab.items
    @State private var cancellable: AnyCancellable? = nil
    @FocusState var searchFocused : Bool
    @FocusState var tabFocused : Bool

    var body: some View {
        VStack {
            ZStack{
                HStack(spacing:10) {
                    Spacer()
                    Image(property["image"].stringValue)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:80)
                    Text(property["title"].stringValue)
                        .foregroundColor(Color.white)
                        .font(.title3)
                    Spacer()
                }

                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(IconButtonStyle(focused:searchFocused))
                    .focused($searchFocused)
                    
                    Spacer()
                    Picker("", selection: $selection) {
                        Text("My Items").tag(Tab.items)
                        Text("My Media").tag(Tab.media)
                        Text("Profile").tag(Tab.profile)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                    .scaleEffect(0.7)
                    .padding(.trailing, -100)
                    .focused($tabFocused)
                    
                }
            }
            .padding(.bottom, 40)
            ZStack{
                if (selection == Tab.items) {
                    MyItemsView(property: property, nfts: nfts).preferredColorScheme(colorScheme)
                        .tag(Tab.items)
                }else if (selection == Tab.media) {
                    WalletView(nfts: nfts).preferredColorScheme(colorScheme)
                        .tag(Tab.media)
                }else if (selection == Tab.profile){
                    ProfileView().preferredColorScheme(colorScheme)
                        .tag(Tab.profile)
                }else if (selection == Tab.search){
                    SearchView().preferredColorScheme(colorScheme)
                }
            }
        }
        .frame(maxWidth:.infinity, maxHeight: .infinity)
        .onAppear(){
            self.cancellable = fabric.objectWillChange.sink { val in
                if fabric.isLoggedOut == true {
                    self.selection = Tab.items
                }
            }
            
            //Need to set delay to set FocusState
            DispatchQueue.main.asyncAfter(deadline: .now()+0.7) {
                self.tabFocused = true
                self.searchFocused = false
            }
        }
        .onChange(of: selection){ newValue in
            if (newValue == Tab.items){
                Task {
                    await fabric.refresh()
                }
            }
        }
        .onChange(of: searchFocused){ newValue in
            if (newValue == true){
                selection = Tab.search
            }
        }
        .onChange(of: property){ newValue in
            print("property changed")
            do {
                self.nfts = try JSONDecoder().decode([NFTModel].self, from:newValue["contents"][0]["contents"].rawData())
                //self.nfts = newValue["contents"][0]["contents"].rawValue as! [NFTModel]
                //print ("Decoded NFTS: \(nfts)")
            }catch{
                print("Error decoding NFTs \(error) \(newValue.object)")
            }
        }
    }
}

/*
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
        .onChange(of: selection){ newValue in
            if (newValue == Tab.Watch){
                Task {
                    await fabric.refresh()
                }
            }
        }
    }
}
*/

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(property: CreateTestProperty(num: 10))
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
