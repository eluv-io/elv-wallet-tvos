//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI

class ViewState: ObservableObject {
    @Published var headerVisible = true
}

@main
struct EluvioWalletTVOSApp: App {
    @StateObject
    var fabric = Fabric()
    @StateObject
    var viewState = ViewState()
    
    init(){
        print("App Init")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fabric)
                .environmentObject(viewState)
                .preferredColorScheme(.dark)
                .onAppear(){
                    Task {
                        do {
                            try await fabric.connect(network:"")
                        }catch{
                            print("Error connecting to the fabric: ", error)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
        }
    }
}
   
