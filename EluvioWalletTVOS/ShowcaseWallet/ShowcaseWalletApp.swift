//
//  ShowcaseWalletApp.swift
//  ShowcaseWallet
//
//  Created by Wayne Tran on 2024-02-15.
//

import SwiftUI


/*
@main
struct ShowcaseWalletApp: App {
    @State var isBranded = true
    @State var openUrl : URL? = nil
    @State var opacity : CGFloat = 0.0
    
    init(){
        print("App Init")
    }
    
    var body: some Scene {
        WindowGroup {
            WalletApp(isBranded: true)
        }
    }
}
*/

@main
struct ShowcaseWalletApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    static let signInBackground = RadialGradient(gradient: Gradient(colors: [Color(hex:0x0e2765),
                                                                             Color(hex:0x040b1d)]),
                                                                                   center: .top, startRadius: 0, endRadius:1200)
    @StateObject
    var fabric = Fabric(createDemoProperties:false)
    @StateObject
    var viewState = ViewState(isBranded: true, signInBackground:signInBackground)
    
    @State var showApp = false
    @State var isBranded = true
    @State var openUrl : URL? = nil
    
    init(){
        print("App Init")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.edgesIgnoringSafeArea(.all)
                if showApp {
                    ContentView()
                        .environmentObject(fabric)
                        .environmentObject(viewState)
                        .preferredColorScheme(.dark)
                }
            }
            .edgesIgnoringSafeArea(.all)
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
                    //Task {
                    //    await MainActor.run {
                            if let url = openUrl {
                                viewState.handleLink(url:url, fabric:fabric)
                                self.openUrl = nil
                            }
                            showApp = true
                       // }
                        //try? await Task.sleep(nanoseconds: 1500000000)
                    //}
                } else if newPhase == .background {
                    print("Background")
                    showApp = false
                }
            }
            .onOpenURL { url in
                debugPrint("url opened: ", url)
                self.openUrl = url
                //viewState.handleLink(url:url, fabric:fabric)
            }

        }
    }
}

