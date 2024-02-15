//
//  WalletLinkTestApp.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-13.
//

import SwiftUI

@main
struct WalletLinkTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(.thinMaterial)
            .onOpenURL { url in
                debugPrint("url opened: ", url)
            }
            .preferredColorScheme(.dark)
            .onAppear() {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
    }
}

