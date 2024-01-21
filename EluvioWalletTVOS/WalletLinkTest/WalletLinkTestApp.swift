//
//  WalletLinkTestApp.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-13.
//

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct ThumbnailButtonStyle: ButtonStyle {
    let focused: Bool
    let selected: Bool
    
    private var opacity: CGFloat {
        if focused {
            return 1.0
        }
        
        if selected  {
           return 0.6
        }
        
        return 0.4
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .opacity(opacity)
            .shadow(color: self.focused || self.selected ? .gray : .black, radius: self.focused || self.selected ? 15 : 2, x: 1, y: 1)
            .cornerRadius(10)
            .scaleEffect(self.focused || self.selected ? 1.14: 1, anchor: .center)
            .animation(.easeIn(duration: 0.2), value: self.focused)
    }
}

struct TextButtonStyle: ButtonStyle {
    let focused: Bool
    var scale = 1.00
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding([.leading,.trailing],20)
            .padding([.top,.bottom],10)
            .background(focused ? .white : .clear)
            .foregroundColor(focused ? .black : .white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.5 : 1)

    }
}

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
        }
    }
}
