//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI

@main
struct EluvioWalletTVOSApp: App {
    @StateObject
    var fabric = Fabric()
    
    init(){
        print("App Init")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fabric)
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
        }
    }
}
   
