public struct DisplaySettings: Codable {
  public var title_icon: ImageLink?
  public var title: String?
  public var subtitle: String?
  public var description: String?

  public var display_limit: Int?
  public var display_format: String?  // can be an enum "carousel", "grid", "hero", "banner"
  public var justification: String?  // can be an enum "left", "right", "center"

  public var logo: ImageLink?
  public var logo_text: String?

  public var aspect_ratio: String?  // Can probably use ImageAspectRatio

  public var inline_background_image: ImageLink?

  public var full_bleed: Bool?

  public var hide_on_tv: Bool?

  public var thumbnail_image_landscape: ImageLink?
  public var thumbnail_image_portrait: ImageLink?
  public var thumbnail_image_square: ImageLink?

  public var headers: [String]?

  public init() {}
}
