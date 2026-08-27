public struct DisplaySettings: Codable {
  public var title_icon: ImageLink?
  public var title: String?
  public var subtitle: String?
  public var description: String?

  public var display_limit: Int?
  public var display_format: String?  // can be an enum "carousel", "grid", "hero", "banner"
  public var card_size: String?  // can be an enum "extra_small", "small", "medium", "large", "extra_large"
  public var justification: String?  // can be an enum "left", "right", "center"
  public var text_justification: String?  // alignment of card titles: "left", "right", "center"

  public var logo: ImageLink?
  public var logo_text: String?

  public var aspect_ratio: String?  // Can probably use AspectRatio

  public var inline_background_image: ImageLink?

  public var full_bleed: Bool?

  public var hide_on_tv: Bool?

  public var hide_title: Bool?

  public var thumbnail_image_landscape: ImageLink?
  public var thumbnail_image_portrait: ImageLink?
  public var thumbnail_image_square: ImageLink?

  public var headers: [String]?

  /// Points to a theme in the Property's `styling.card_themes`. Only Sections define this.
  public var card_theme_id: String?

  /// Which text fields to show under the section's item cards: "all"/"titles"/"title"/"none".
  /// Only Sections define this.
  public var content_display_text: String?

  /// Whether the section's item cards show their title. The server also picks which other texts
  /// to show, but cards only ever show a title, so it all collapses to this.
  /// Nil when unset, which means "show".
  public var showItemTitles: Bool? {
    guard let value = content_display_text?.nilIfEmpty() else { return nil }
    return value != "none"
  }

  public init() {}
}
