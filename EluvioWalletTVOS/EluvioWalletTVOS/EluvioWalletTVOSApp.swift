//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI

@main
struct EluvioWalletTVOSApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject
    var fabric = Fabric()
    @StateObject
    var viewState = ViewState()
    
    @State var showApp = false
    
    var opacity : CGFloat {
        showApp ? 1.0 : 0.0
    }
    
    init(){
        print("App Init")
    }

    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.edgesIgnoringSafeArea(.all)
                ContentView()
                    .environmentObject(fabric)
                    .environmentObject(viewState)
                    .preferredColorScheme(.dark)
                    .opacity(opacity)
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
                            showApp = false
                        } else if newPhase == .active {
                            print("Active ")
                            Task {
                                try? await Task.sleep(nanoseconds: 1500000000)
                                await MainActor.run {
                                    showApp = true
                                }
                            }
                        } else if newPhase == .background {
                            print("Background")
                            showApp = false
                        }
                    }
                    .onOpenURL { url in
                        debugPrint("url opened: ", url)
                        
                        viewState.handleLink(url:url, fabric:fabric)
                    }
                    .edgesIgnoringSafeArea(.all)
            }
        }
        
    }
}
   

