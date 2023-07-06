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
    var initialOpacity: CGFloat = 1.0
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(Color.clear)
            .cornerRadius(5)
            .scaleEffect(self.focused ? 1.1: 1, anchor: .center)
            .shadow(color: self.focused ? .gray.opacity(0.5) : .black, radius: self.focused ? 8 : 0, x: 2, y: 2)
            .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
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



extension Font {
    
    /// Create a font with the large title text style.
    public static var itemTitle: Font {
        return Font.system(size: 36)
    }
    
    /// Create a font with the title text style.
    public static var itemSubtitle: Font {
        return Font.system(size: 20)
    }
    
    public static var description: Font {
        return Font.system(size: 40)
    }
    
    public static var fine: Font {
        return Font.system(size: 20)
    }
    
    public static var fineBold: Font {
        return Font.system(size: 20)
    }
    
    public static var small: Font {
        return Font.system( size: 28)
    }
    
    public static var smallBold: Font {
        return Font.system(size: 28).bold()
    }

    public static var rowTitle: Font {
        return Font.system(size: 36)
    }
    
    public static var rowSubtitle: Font {
        return Font.system(size: 30)
    }
}
