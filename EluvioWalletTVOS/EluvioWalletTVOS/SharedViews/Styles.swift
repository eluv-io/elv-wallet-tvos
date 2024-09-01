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
    var highlightColor: Color = Color.clear
    var buttonColor: Color = Color.clear
    var scale = 1.03
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(focused ? highlightColor : buttonColor)
            .cornerRadius(10)
            .scaleEffect(self.focused ? scale: 1.0, anchor: .center)
            .animation(self.focused ? .easeIn(duration: 0.1) : .easeOut(duration: 0.1), value: self.focused)
            .opacity(self.focused ? 1.0 : initialOpacity)
    }
}

struct NavButtonStyle: ButtonStyle {
    let focused: Bool
    var initialOpacity: CGFloat = 1.0
    var highlightColor: Color = Color.clear
    var buttonColor: Color = Color.clear
    var scale = 1.03
    func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .foregroundColor(.white)
                .background(focused ? highlightColor : buttonColor)
                .cornerRadius(10)
                .scaleEffect(self.focused ? scale: 1.0, anchor: .center)
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

struct BannerButtonStyle: ButtonStyle {
    let focused: Bool
    var scale = 1.04
    var bordered = false
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(.clear)
            .scaleEffect(self.focused ? scale: 1, anchor: .center)
            .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
            .background(
                RoundedRectangle(
                    cornerRadius: 0,
                    style: .continuous
                )
                .stroke(.tint, lineWidth: bordered && focused ? 4 : 0)
                .scaleEffect(self.focused ? scale: 1, anchor: .center)
                .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
            )

    }
}


struct TitleButtonStyle: ButtonStyle {
    let focused: Bool
    var scale = 1.04
    var bordered = false
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(.clear)
            .scaleEffect(self.focused ? scale: 1, anchor: .center)
            .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
            .background(
                RoundedRectangle(
                    cornerRadius: 0,
                    style: .continuous
                )
                .stroke(.tint, lineWidth: bordered && focused ? 4 : 0)
                .scaleEffect(self.focused ? scale: 1, anchor: .center)
                .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
            )

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

struct ThumbnailButtonStyle: ButtonStyle {
    let focused: Bool
    let selected: Bool
    
    private var opacity: CGFloat {
        if focused {
            return 1.0
        }
        
        if selected  {
           return 0.7
        }
        
        return 0.6
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
    var bordered = false
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding([.leading,.trailing],20)
            .padding([.top,.bottom],10)
            .background(focused ? .white : .clear)
            .foregroundColor(focused ? .black : .white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .background(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .stroke(.tint, lineWidth: bordered && !focused ? 1 : 0)
            )
            

    }
}

struct secondaryFilterButtonStyle: ButtonStyle {
    let focused: Bool
    let selected: Bool
    var scale = 1.00
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding([.leading,.trailing],20)
            .padding([.top,.bottom],10)
            .background(focused || selected ? .white : Color(hex:0x3b3b3b))
            .foregroundColor(focused || selected ? .black : .white)
            .cornerRadius(10)
            .opacity(configuration.isPressed || focused || selected ? 1 : 0.6)
            .scaleEffect(self.focused || self.selected ? 1.14: 1, anchor: .center)
            .scaleEffect(configuration.isPressed ? 1.16 : 1)
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
        return Font.system(size: 32)
    }
    
    public static var rowSubtitle: Font {
        return Font.system(size: 30)
    }
    
    public static var sectionLogoText: Font {
        return Font.system(size: 24)
    }
    
    public static var propertyDescription: Font {
        return Font.system(size:30)
    }
}
