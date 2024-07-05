//
//  MainView.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-08-10.
//

import SwiftUI
import Combine
import SwiftyJSON

struct MainViewSideNav: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
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
            ZStack(){
                DiscoverView().preferredColorScheme(colorScheme)
                    .prefersDefaultFocus(in: MAIN)
                    .opacity(selection == .Discover ? 1.0 : 0.0)
                MyItemsView(nfts: fabric.library.items).preferredColorScheme(colorScheme)
                    .opacity(selection == .Items ? 1.0 : 0.0)
                ProfileView().preferredColorScheme(colorScheme)
                    .opacity(selection == .Profile ? 1.0 : 0.0)
                    .preferredColorScheme(.dark)
            }
            .disabled(showNav)
            
            HStack{
                Button{}label:{
                    SideNavBarView(selection: $selection, navFocused: false)
                        .disabled(true)
                }
                .buttonStyle(NonSelectionButtonStyle())
                .focused($navFocused)
                .prefersDefaultFocus(false, in: MAIN)
                .background(.blue)
                
                Spacer()
            }
            .disabled(navDisabled)
            .opacity(showNav ? 0.1 : 1.0)
        }
        .edgesIgnoringSafeArea(.all)
        .fullScreenCover(isPresented: $showNav, onDismiss: {
            debugPrint("Nav dismiss")
            justDismissed = true
            navDisabled = false

            /*Task {
                do {
                    //try await Task.sleep(nanoseconds: UInt64(3 * Double(NSEC_PER_SEC)))
                    await MainActor.run {
                        navDisabled = false
                    }
                }catch{}
            }*/

        }){
            HStack{
                SideNavBarView(selection: $selection, navFocused: true)
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
        }
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



struct VerticalControlGroupStyle: ControlGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing:0) {
            configuration.content
        }
        .focusSection()
    }
}

struct SideNavButton: View {
    @FocusState var focused
    var selected : Bool
    var iconSystemName = ""
    var action = {}
    var text = ""
    var width :CGFloat = 100
    
    var body: some View {
        ZStack(alignment:.leading){
                Button(action: {
                    action()
                }) {
                    HStack(spacing:0) {
                        Image(systemName: iconSystemName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height:40, alignment: .leading)
                            .padding(20)
                        Text(text)
                            .font(.rowSubtitle)
                            .frame(minWidth:0)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 0)
                    }
                    .frame(width: width)
                    .padding(0)
                }
                .frame(width: width, alignment: .leading)
                .buttonStyle(NavButtonStyle(focused: focused || selected, initialOpacity: 0.6))
                .focused($focused)
                .padding(10)
                Spacer(minLength: 0)
            
            Rectangle().frame(width:5, height: 60, alignment: .leading).opacity(selected ? 1.0 : 0.0)
        }
        .frame(width: width, alignment: .leading)
        .fixedSize()
    }
}

struct SideNavBarView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selection: MainTab
    
    @Namespace var SideNav
    var navFocused : Bool = false
    
    @FocusState var homeFocused
    @FocusState var itemsFocused
    @FocusState var profileFocused
    @FocusState var dividerFocused
    
    var width : CGFloat {
        navFocused ? 300 : 100
    }

    var body: some View {
        ZStack(alignment:.leading) {
            HStack(spacing:1){
                ZStack(alignment:.leading){
                    Color.clear
                        .frame(width: width)
                        .frame(maxHeight:.infinity)
                        .edgesIgnoringSafeArea([.top,.bottom])
                        .background(.ultraThickMaterial)
                        .opacity(0.8)
                        .environment(\.colorScheme, .dark)

                    ControlGroup {
                        Spacer()
                        SideNavButton(focused: _homeFocused, selected: selection == .Discover ,iconSystemName: "house.fill", text: navFocused ? "Home" : "", width:width)
                        SideNavButton(focused: _itemsFocused, selected: selection == .Items, iconSystemName: "lanyardcard", text: navFocused ? "My Items" : "", width:width)
                        SideNavButton(focused: _profileFocused, selected: selection == .Profile,  iconSystemName: "person.crop.circle", text: navFocused ? "Profile" : "", width:width)
                        Spacer()
                    }
                    .controlGroupStyle(VerticalControlGroupStyle())
                    .frame(maxHeight:.infinity)
                    .focusSection()
                }
                .frame(maxHeight:.infinity)


                Divider()
                    .frame(width: 2, height: 600)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.clear, .white, .clear]), startPoint: .top, endPoint: .bottom)
                    )
                
                if (navFocused) {
                    Button{}label:{
                        Color.clear.frame(maxHeight:.infinity)
                    }
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($dividerFocused)
                    .padding(.leading,50)
                }
                
                Spacer()
            }
            .frame(minWidth: width+100)
            .frame(maxWidth: navFocused ? width + 200 : width + 100)
            .frame(maxHeight:.infinity)
            .preferredColorScheme(.dark)
            .onChange(of: homeFocused){  oldValue, newValue in
                if (newValue){
                    selection = .Discover
                }
            }
            .onChange(of: itemsFocused){  oldValue, newValue in
                if (newValue){
                    selection = .Items
                }
            }
            .onChange(of: profileFocused){  oldValue, newValue in
                if (newValue){
                    selection = .Profile
                }
            }
            .onChange(of: dividerFocused){  oldValue, newValue in
                debugPrint("DividerFocused ", newValue)
                if (newValue){
                    presentationMode.wrappedValue.dismiss()
                }
            }
            /*
            .onChange(of: navFocused){  oldValue, newValue in
                debugPrint("navFocused ", newValue)
                if (newValue){
                    if (selection == .Discover){
                        homeFocused = true
                    }else if (selection == .Items){
                        itemsFocused = true
                    }else if (selection == .Profile){
                        profileFocused = true
                    }
                    //withAnimation(.easeInOut(duration: 1)) {
                        width = 300
                    //}
                }else{
                    width = 100
                }
            }
             */

        }
        .frame(maxHeight:.infinity)
    }
}

