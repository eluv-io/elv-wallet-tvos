//
//  CardThemeUI.swift
//  EluvioWalletTVOS
//
//  Turns a `CardTheme` into the SwiftUI values `MediaCard` draws with.
//

import EluvioCore
import Foundation
import SwiftUI

extension CardBorderRadius {
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

extension CardTheme {
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
