//
//  CardTheme.swift
//  EluvioCore
//

import Foundation

/// Property-level styling. Themes are defined once here and referenced by id
/// from the Property, its Pages and its Sections.
public struct PropertyStyling: Codable {
  public var card_themes: [String: CardTheme]?
}

/// Defines the visuals of a card. Referenced by `card_theme_id` on
/// `MediaProperty`, `MediaPropertyPage` and `DisplaySettings`.
public struct CardTheme: Codable {
  public var id: String?
  /// none/subtle/curved
  public var border_radius: String?
  public var border_width: Int?
  public var circularize: Bool?
  /// Singular. There's also an "effects" object in some payloads, but the web reads this one.
  public var effect: String?
  public var active: CardThemeState?
  public var inactive: CardThemeState?

  public var borderRadius: CardBorderRadius { CardBorderRadius(border_radius) }

  /// Border thickness. Zero means the card has no border of its own, and keeps
  /// whatever border the app draws by default (on TV, the focus ring).
  public var borderWidth: Int { border_width ?? 0 }

  public var hasBorder: Bool { borderWidth > 0 }

  /// Renders square cards as circles. Cards with any other aspect ratio are unaffected.
  public var isCircularized: Bool { circularize == true }

  public var cardEffect: CardEffect { CardEffect(effect) }

  /// Visuals that differ between the focused ("active") and unfocused states.
  public func state(focused: Bool) -> CardThemeState? { focused ? active : inactive }
}

/// The half of a card theme that depends on whether the card is focused.
/// Colors are hex strings, as they come from the API.
public struct CardThemeState: Codable {
  public var border_color: String?
  /// solid/gradient. Anything but "gradient" means `background_color` fills the whole card.
  public var background_type: String?
  /// Solid fill, or the first stop when `isGradient` is true.
  public var background_color: String?
  /// Percent, 0-100. Missing means fully opaque.
  public var background_color_opacity: Int?
  /// Second stop of the gradient. Only meaningful when `isGradient` is true.
  public var background_color_2: String?
  public var background_color_2_opacity: Int?
  /// Degrees, clockwise from "up", like a CSS gradient.
  public var background_gradient_angle: Int?

  public var isGradient: Bool { background_type == "gradient" }

  public var startOpacity: Double { Self.opacity(background_color_opacity) }
  public var endOpacity: Double { Self.opacity(background_color_2_opacity) }

  public var gradientAngle: Double { Double(background_gradient_angle ?? 0) }

  /// Opacities are percentages, and a missing one means the color is fully opaque.
  private static func opacity(_ percent: Int?) -> Double {
    Double(min(max(percent ?? 100, 0), 100)) / 100
  }
}

/// A visual treatment applied to the card on top of its shape and colors.
///
/// The web has two more values we don't support - "desaturate-background" greys
/// the card's background layer rather than its image, and unknown values simply
/// do nothing.
public enum CardEffect {
  case none, desaturate

  public init(_ raw: String?) {
    switch raw {
    // Our desaturation only ever touches the image, so both spellings land here.
    case "desaturate", "desaturate-image": self = .desaturate
    default: self = .none
    }
  }
}

public enum CardBorderRadius: String {
  case none, subtle, curved

  public init(_ raw: String?) {
    self = raw.flatMap { CardBorderRadius(rawValue: $0.lowercased()) } ?? .none
  }
}

public extension MediaProperty {
  /// Resolves the card theme that applies to items in `section`.
  /// The Property defines a default theme, which a Page can override, which a
  /// Section can override. Empty ids count as unset.
  func resolveCardTheme(pageThemeId: String?, section: MediaPropertySection?) -> CardTheme? {
    let themeId =
      section?.display?.card_theme_id?.nilIfEmpty()
      ?? pageThemeId?.nilIfEmpty()
      ?? card_theme_id?.nilIfEmpty()
    guard let themeId else { return nil }
    return styling?.card_themes?[themeId]
  }
}
