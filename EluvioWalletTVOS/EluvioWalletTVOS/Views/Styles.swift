//
//  Styles.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let focused: Bool
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(self.focused ? Color.highlight : Color.tinted)
            .cornerRadius(20)
            .scaleEffect(self.focused ? 1.05: 1, anchor: .center)
            .shadow(color: .black, radius: self.focused ? 20 : 5, x: 5, y: 5)
            .animation(.easeIn(duration: 0.2), value: self.focused)
    }
}

struct DetailButtonStyle: ButtonStyle {
    let focused: Bool
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(self.focused ? Color.highlight : Color.tinted)
            .cornerRadius(20)
            .scaleEffect(self.focused ? 1.04: 1, anchor: .center)
            .shadow(color: self.focused ? .gray.opacity(0.5) : .black, radius: self.focused ? 8 : 0, x: 2, y: 2)
            .animation(self.focused ? .linear(duration: 0.5).repeatForever() : .easeIn(duration: 0.2), value: self.focused)
    }
}

struct IconButtonStyle: ButtonStyle {
    let focused: Bool
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(self.focused ? Color.tinted : Color.translucent)
            .cornerRadius(20)
            .scaleEffect(self.focused ? 1.5: 1, anchor: .center)
            .shadow(color: self.focused ? .gray.opacity(0.5) : .black, radius: self.focused ? 8 : 0, x: 2, y: 2)
            .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
    }
}

struct NonSelectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.clear)
            .background(.clear)
    }
}

struct TitleButtonStyle: ButtonStyle {
    let focused: Bool
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(.clear)
            .scaleEffect(self.focused ? 1.04: 1, anchor: .center)
            .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
    }
}

struct GalleryButtonStyle: ButtonStyle {
    let focused: Bool
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .opacity(self.focused ? 1.0 : 0.5)
            .shadow(color: self.focused ? .gray : .black, radius: self.focused ? 15 : 2, x: 1, y: 1)
            .cornerRadius(20)
            .scaleEffect(self.focused ? 1.14: 1, anchor: .center)
            .animation(.easeIn(duration: 0.2), value: self.focused)
    }
}
