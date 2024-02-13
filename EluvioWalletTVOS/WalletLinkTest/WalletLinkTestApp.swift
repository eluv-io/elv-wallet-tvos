//
//  WalletLinkTestApp.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-13.
//

import SwiftUI

/*
struct TitleButtonStyle: ButtonStyle {
    let focused: Bool
    var scale = 1.04
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(.clear)
            .scaleEffect(self.focused ? scale: 1, anchor: .center)
            .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
    }
}

struct IconButtonStyle: ButtonStyle {
    let focused: Bool
    var initialOpacity: CGFloat = 1.0
    var highlightColor: Color = Color.clear
    var buttonColor: Color = Color.clear
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(focused ? highlightColor : buttonColor)
            .cornerRadius(10)
            .scaleEffect(self.focused ? 1.03: 1, anchor: .center)
            .animation(self.focused ? .easeIn(duration: 0.1) : .easeOut(duration: 0.1), value: self.focused)
            .opacity(self.focused ? 1.0 : initialOpacity)
    }
}

struct NonSelectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.clear)
            .background(.clear)
    }
}
*/

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

