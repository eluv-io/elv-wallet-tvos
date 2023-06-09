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
            if (newValue == Tab.Items){
                //Task {
                    //TOO SLOW!!
                    //await fabric.refresh()
                //}
            }
        }
    }
}

/*
struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    
    var property : JSON
    @State var nfts : [NFTModel] = []
    
    enum Tab: Hashable { case items, media, profile, search, properties}
    @State var selection: Tab = Tab.items
    @State private var cancellable: AnyCancellable? = nil
    @FocusState var searchFocused : Bool
    @FocusState var tabFocused : Bool
    @FocusState var propertiesFocused : Bool
    @State var searchString : String = ""
    
    var body: some View {
        VStack {
            ZStack{
                HStack(spacing:0) {
                    Button {
                    } label: {
                        HStack(spacing:10) {
                            Image(property["image"].stringValue)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width:80)
                            Text(property["title"].stringValue)
                                .foregroundColor(Color.white)
                                .font(.title3)
                        }
                    }
                    .frame(idealWidth:500,alignment: .leading)
                    .buttonStyle(TitleButtonStyle(focused: propertiesFocused))
                    .focused($propertiesFocused)
                    
                    Spacer().frame(width:250)
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
                    
                    Spacer()
                    
                    HStack(spacing:20){
                        Image(systemName: "magnifyingglass")
                        TextField("Search...", text: $searchString)
                            .frame(width:400, height:50, alignment: .leading)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.body)
                            .focused($searchFocused)
                    }
                    .padding(20)
                    
                    Spacer()
                }
            }
            .padding(.bottom, 40)
            .focusSection()
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
                }else if (selection == Tab.properties){
                    PropertiesView().preferredColorScheme(colorScheme)
                }
                
            }
            .padding(20)
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
                self.propertiesFocused = false
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
        .onChange(of: propertiesFocused){ newValue in
            if (newValue == true){
                selection = Tab.properties
            }
        }
        .onChange(of: property){ newValue in
            print("property changed")
            do {
                self.nfts = try JSONDecoder().decode([NFTModel].self, from:newValue["contents"][0]["contents"].rawData())
            }catch{
                print("Error decoding NFTs \(error) \(newValue.object)")
            }
        }
    }
}
*/
/*
struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    
    var property : JSON
    @State var nfts : [NFTModel] = []
    
    enum Tab: Hashable { case items, media, profile, search, properties}
    @State var selection: Tab = Tab.items
    @State private var cancellable: AnyCancellable? = nil
    @FocusState var searchFocused : Bool
    @FocusState var tabFocused : Bool
    @FocusState var propertiesFocused : Bool

    var body: some View {
        VStack {
            ZStack{
                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(IconButtonStyle(focused:searchFocused))
                    .focused($searchFocused)
                    
                    Spacer()
                    Button {
                    } label: {
                        HStack(spacing:10) {
                            Image(property["image"].stringValue)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width:80)
                            Text(property["title"].stringValue)
                                .foregroundColor(Color.white)
                                .font(.title3)
                        }
                    }
                    .frame(idealWidth:500,alignment: .trailing)
                    .buttonStyle(TitleButtonStyle(focused: propertiesFocused))
                    .focused($propertiesFocused)
                    
                    Spacer().frame(width:250)
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
            .focusSection()
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
                }else if (selection == Tab.properties){
                    PropertiesView().preferredColorScheme(colorScheme)
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
                self.propertiesFocused = false
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
        .onChange(of: propertiesFocused){ newValue in
            if (newValue == true){
                selection = Tab.properties
            }
        }
        .onChange(of: property){ newValue in
            print("property changed")
            do {
                self.nfts = try JSONDecoder().decode([NFTModel].self, from:newValue["contents"][0]["contents"].rawData())
            }catch{
                print("Error decoding NFTs \(error) \(newValue.object)")
            }
        }
    }
}
*/

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
        MainView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
