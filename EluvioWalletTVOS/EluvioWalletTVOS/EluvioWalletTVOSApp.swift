//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI

/*
@main
struct EluvioWalletTVOSApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject
    var fabric = Fabric()
    @StateObject
    var viewState = ViewState()
    
    @State var showApp = false
    
    @State var opacity : CGFloat = 0.0
    
    init(){
        print("App Init")
    }
    
    var body: some Scene {
        WindowGroup {
            WalletApp(isBranded: false)
        }
    }
}
   
*/

@main
struct EluvioWalletTVOSApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var eluvio = EluvioAPI()
    
    @State var showLoader: Bool = false
    
    @State var opacity : CGFloat = 0.0
    
    init(){
        print("App Init")
        let items = [23,32,32,34,23,34,43,43,43]
        let groups = items.dividedIntoGroups(of:7)
        
        print("groups: ", groups)
    }

    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.edgesIgnoringSafeArea(.all)
                if showLoader {
                        ZStack{
                            Color.black.edgesIgnoringSafeArea(.all)
                            ProgressView()
                        }
                        .frame(minWidth: 0, maxWidth: .infinity , minHeight: 0, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                }else {
                    ContentView()
                        .opacity(opacity)
                        .environmentObject(eluvio)
                        .preferredColorScheme(.dark)
                }
            }
            .onAppear(){
                Task {
                    /*
                    do {
                
                    }catch{
                        print("Error connecting to the fabric: ", error)
                        eluvio.pathState.path.append(.errorView("Please check your network and try again."))
                    }
                     */
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive {
                    print("Inactive")
                    self.opacity = 0.0
                } else if newPhase == .active {
                    print("Active ")
                    Task {
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 3)) {
                                self.opacity = 1.0
                            }
                        }
                    }
                } else if newPhase == .background {
                    print("Background")
                    self.opacity = 0.0
                }
            }
            .onOpenURL { url in
                Task {
                    debugPrint("url opened: ", url)
                    self.showLoader = true
                    await eluvio.viewState.handleLink(url:url, fabric:eluvio.fabric)
                    self.showLoader = false
                    debugPrint("handle link done opened: ", url)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}
