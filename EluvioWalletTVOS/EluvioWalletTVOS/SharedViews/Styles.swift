//
//  Styles.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import EluvioCore
import SwiftUI

struct IconButtonStyle: ButtonStyle {
  let focused: Bool
  var initialOpacity: CGFloat = 1.0
  var highlightColor: Color = .clear
  var buttonColor: Color = .clear
  var scale = 1.03
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .foregroundColor(.white)
      .background(focused ? highlightColor : buttonColor)
      .cornerRadius(10)
      .scaleEffect(focused ? scale : 1.0, anchor: .center)
      .animation(focused ? .easeIn(duration: 0.1) : .easeOut(duration: 0.1), value: focused)
      .opacity(focused ? 1.0 : initialOpacity)
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
      .scaleEffect(focused ? scale : 1, anchor: .center)
      .animation(focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: focused)
      .background(
        RoundedRectangle(
          cornerRadius: 0,
          style: .continuous
        )
        .stroke(.tint, lineWidth: bordered && focused ? 4 : 0)
        .scaleEffect(focused ? scale : 1, anchor: .center)
        .animation(focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: focused)
      )
  }
}

struct TitleButtonStyle: ButtonStyle {
  let focused: Bool
  var scale = 1.00
  var bordered = false
  var borderRadius = 0.0
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .foregroundColor(.white)
      .background(.clear)
      .scaleEffect(focused ? scale : 1, anchor: .center)
      .animation(focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: focused)
      .background(
        RoundedRectangle(
          cornerRadius: borderRadius,
          style: .continuous
        )
        .stroke(.tint, lineWidth: bordered && focused ? 4 : 0)
        .scaleEffect(focused ? scale : 1, anchor: .center)
        .animation(focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: focused)
      )
  }
}

struct GalleryButtonStyle: ButtonStyle {
  let focused: Bool
  var scale = 1.00
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .foregroundColor(.white)
      .opacity(focused ? 1.0 : 0.5)
      .shadow(color: focused ? .gray : .black, radius: focused ? 15 : 2, x: 1, y: 1)
      .cornerRadius(20)
      .scaleEffect(focused ? scale : 1, anchor: .center)
      .animation(.easeIn(duration: 0.2), value: focused)
  }
}

struct TextButtonStyle: ButtonStyle {
  let focused: Bool
  var scale = 1.00
  var selected: Bool = false
  var bordered = false
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding([.leading, .trailing], 20)
      .padding([.top, .bottom], 10)
      .background(focused ? .white : .clear)
      .foregroundColor(focused ? .black : .white)
      .cornerRadius(10)
      .opacity(configuration.isPressed || focused || selected ? 1 : 0.6)
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
  var scale = 1.08
  var isImage: Bool = true
  func makeBody(configuration: Self.Configuration) -> some View {
    if isImage {
      configuration.label
        .foregroundColor(selected ? .black : .white)
        .padding(10)
        .opacity(configuration.isPressed || focused || selected ? 1 : 0.3)
        .scaleEffect(focused ? scale : 1, anchor: .center)
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
        .animation(.easeIn(duration: 0.2), value: focused)
    } else {
      configuration.label
        .padding([.leading, .trailing], 20)
        .padding([.top, .bottom], 10)
        .background(selected ? .white : focused ? Color(hex: 0x8B8B8B) : .clear)
        .foregroundColor(selected ? .black : .white)
        .cornerRadius(10)
        .opacity(configuration.isPressed || focused || selected ? 1 : 0.6)
        .scaleEffect(focused ? scale : 1, anchor: .center)
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
        .animation(.easeIn(duration: 0.2), value: focused)
    }
  }
}

struct primaryFilterButtonStyle: ButtonStyle {
  let focused: Bool
  let selected: Bool
  var scale = 1.08
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding([.leading, .trailing], 20)
      .padding([.top, .bottom], 10)
      .background(selected ? .white : focused ? Color(hex: 0x8B8B8B) : Color(hex: 0x3B3B3B))
      .foregroundColor(selected ? .black : .white)
      .cornerRadius(10)
      .opacity(configuration.isPressed || focused || selected ? 1 : 0.6)
      .scaleEffect(focused ? scale : 1, anchor: .center)
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(.easeIn(duration: 0.2), value: focused)
  }
}

struct propertyFilterButtonStyle: ButtonStyle {
  let focused: Bool
  let selected: Bool
  var scale = 1.00
  func makeBody(configuration: Self.Configuration) -> some View {
    ZStack {
      RoundedRectangle(
        cornerRadius: 10,
        style: .continuous
      )
      .stroke(.tint, lineWidth: focused ? 4 : 1)
      .fill(selected || focused ? Color(hex: 0x3B3B3B) : .clear)
      // .fill(focused ? Color(hex:0x8b8b8b)  : .clear)

      configuration.label
        .padding([.leading, .trailing], 20)
        .foregroundColor(selected ? .white : .white)
        .cornerRadius(10)
    }
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
    .animation(.easeIn(duration: 0.1), value: configuration.isPressed)
    .opacity(configuration.isPressed || selected || focused ? 1 : 0.6)
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

  public static var small: Font {
    return Font.system(size: 28)
  }

  public static var rowTitle: Font {
    return Font.system(size: 34, weight: .medium)
  }

  public static var rowSubtitle: Font {
    return Font.system(size: 28)
  }

  public static var sectionLogoText: Font {
    return Font.system(size: 24)
  }

  public static var propertyDescription: Font {
    return Font.system(size: 26)
  }

  public static var sectionContainerTitle: Font {
    return Font.system(size: 46, weight: .semibold)
  }

  public static var sectionContainerSubtitle: Font {
    return Font.system(size: 30)
  }
}

