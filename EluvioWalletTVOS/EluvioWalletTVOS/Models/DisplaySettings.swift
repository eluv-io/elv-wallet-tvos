struct DisplaySettings: Codable {
  var title_icon: ImageLink?
  var title: String?
  var subtitle: String?
  var description: String?

  var display_limit: Int?
  var display_format: String?  // can be an enum "carousel", "grid", "hero", "banner"
  var justification: String?  // can be an enum "left", "right", "center"

  var logo: ImageLink?
  var logo_text: String?

  var aspect_ratio: String?  // Can probably use ImageAspectRatio

  var inline_background_image: ImageLink?

  var full_bleed: Bool?

  var hide_on_tv: Bool?

  var thumbnail_image_landscape: ImageLink?
  var thumbnail_image_portrait: ImageLink?
  var thumbnail_image_square: ImageLink?

  var headers: [String]?
}
