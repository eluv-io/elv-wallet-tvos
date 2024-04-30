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
    
    @StateObject
    var fabric = Fabric()
    @StateObject
    var viewState = ViewState()
    @State var showLoader: Bool = false
    
    @State var opacity : CGFloat = 0.0
    
    init(){
        print("App Init")
    }

    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.edgesIgnoringSafeArea(.all)
                ContentView()
                    .opacity(opacity)
                    .environmentObject(fabric)
                    .environmentObject(viewState)
                    .preferredColorScheme(.dark)
                if showLoader {
                        ZStack{
                            Color.black.edgesIgnoringSafeArea(.all)
                            ProgressView()
                        }
                        .frame(width: .infinity, height: .infinity)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .onAppear(){
                Task {
                    do {
                        try await fabric.connect(network:"")
                    }catch{
                        print("Error connecting to the fabric: ", error)
                    }
                }
            }
            .onChange(of: scenePhase) { newPhase in
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
                    await viewState.handleLink(url:url, fabric:fabric)
                    self.showLoader = false
                    debugPrint("handle link done opened: ", url)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}
