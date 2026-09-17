//
//  CardThemeUI.swift
//  EluvioCore
//
//  Turns a `CardTheme` into the SwiftUI values cards draw with.
//

import Foundation
import SwiftUI

public extension CardBorderRadius {
  /// Corner radius in points. The server's values are Android dp, which are
  /// half a 1080p pixel, so they double to match this app's card dimensions.
  var cornerRadius: CGFloat {
    switch self {
    case .none: 0
    case .subtle: 10
    case .curved: 40
    }
  }
}

public extension CardTheme {
  /// Whether a card with the given `aspectRatio` renders as a circle under this
  /// theme. Only square cards get circularized - any other aspect ratio would
  /// turn into an ellipse.
  func isCircular(aspectRatio: AspectRatio) -> Bool {
    isCircularized && aspectRatio == .square
  }

  /// The border to draw around a card. Only meaningful when `hasBorder` is true.
  func borderColor(focused: Bool) -> Color {
    Color(hexString: state(focused: focused)?.border_color) ?? .white
  }

  /// How saturated a card's image should be: fully grey while the desaturate
  /// effect applies, full color otherwise. Like the web, focusing a card
  /// restores its color.
  func imageSaturation(focused: Bool) -> Double {
    cardEffect == .desaturate && !focused ? 0 : 1
  }

  /// The background this theme paints behind a card's image, sized to `size` so
  /// the gradient line can span the card. A theme that doesn't name a color
  /// gets opaque black, matching the web's defaults.
  func background(focused: Bool, size: CGSize) -> LinearGradient? {
    guard let state = state(focused: focused), size.width > 0, size.height > 0 else { return nil }
    let start = Self.color(state.background_color, opacity: state.startOpacity)
    // A solid background is just a gradient between two identical colors, which
    // is how the web renders it too.
    let end =
      state.isGradient
      ? Self.color(state.background_color_2, opacity: state.endOpacity) : start

    // The angle is a CSS angle, so the gradient line is rotated clockwise from
    // "up" and sized to span the card in whatever direction it ends up pointing.
    let radians = state.gradientAngle * .pi / 180
    let directionX = sin(radians)
    let directionY = -cos(radians)
    let length = abs(size.width * directionX) + abs(size.height * directionY)
    let halfX = directionX * length / 2
    let halfY = directionY * length / 2
    return LinearGradient(
      colors: [start, end],
      startPoint: UnitPoint(x: 0.5 - halfX / size.width, y: 0.5 - halfY / size.height),
      endPoint: UnitPoint(x: 0.5 + halfX / size.width, y: 0.5 + halfY / size.height)
    )
  }

  private static func color(_ hex: String?, opacity: Double) -> Color {
    (Color(hexString: hex) ?? .black).opacity(opacity)
  }
}

public extension View {
  /// Dresses a search filter's image in the Property's card theme: the theme's
  /// background behind the image, its corner shape clipping both, and its
  /// border drawn on top. Without a theme the image is left exactly as it was.
  ///
  /// `active` picks the theme's focused half - the platforms differ on what
  /// earns it, so the caller decides.
  func cardThemedFilter(_ theme: CardTheme?, active: Bool) -> some View {
    modifier(CardThemedFilter(theme: theme, active: active))
  }
}

/// Filters don't declare an aspect ratio the way section items do, so the card
/// takes the shape of its own image and only a square one gets circularized.
private struct CardThemedFilter: ViewModifier {
  let theme: CardTheme?
  let active: Bool

  /// The image's rendered size, which is all we know of its shape. It also
  /// orients the theme's gradient, so the background measures it as it draws.
  @State private var size: CGSize = .zero

  private var shape: AnyShape {
    // Within a point, an image that renders as tall as it is wide is square.
    if theme?.isCircularized == true, size.width > 0, abs(size.width - size.height) < 1 {
      return AnyShape(Circle())
    }
    return AnyShape(RoundedRectangle(cornerRadius: theme?.borderRadius.cornerRadius ?? 0))
  }

  func body(content: Content) -> some View {
    if let theme {
      content
        .saturation(theme.imageSaturation(focused: active))
        .background {
          GeometryReader { proxy in
            // Both states are stacked and cross-faded so they don't pop as
            // focus moves along the row, like a themed card's background does.
            ZStack {
              theme.background(focused: false, size: proxy.size)
              theme.background(focused: true, size: proxy.size)
                .opacity(active ? 1 : 0)
            }
            .onAnyChange(of: proxy.size) { _, newSize in size = newSize }
          }
        }
        .clipShape(shape)
        .overlay {
          if theme.hasBorder {
            shape.stroke(
              theme.borderColor(focused: active), lineWidth: CGFloat(theme.borderWidth))
          }
        }
        .animation(.easeInOut(duration: 0.3), value: active)
        // Filter rows dim their unpicked cards. Without this the dimming is
        // applied to the image and the background separately, which makes the
        // image translucent and lets the theme's color bleed through it.
        .compositingGroup()
    } else {
      content
    }
  }
}
