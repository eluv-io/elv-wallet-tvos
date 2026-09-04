import Foundation

extension MediaPropertySectionItem: Decodable {
  public enum CodingKeys: String, CodingKey {
    case id, banner_image, banner_image_mobile, media_id, media_type, type, media
    case description, disabled, display, label, expand, use_media_settings
    case subproperty_id, subproperty_page_id, permissions, page_id, url, resolvedPermissions
    case primary_filter, secondary_filter
  }

  public convenience init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    banner_image = try container.decodeIfPresent(ImageLink.self, forKey: .banner_image)
    banner_image_mobile = try container.decodeIfPresent(ImageLink.self, forKey: .banner_image_mobile)
    media_id = try container.decodeIfPresent(String.self, forKey: .media_id)
    media_type = try container.decodeIfPresent(String.self, forKey: .media_type)
    type = try container.decodeIfPresent(String.self, forKey: .type)
    media = try container.decodeIfPresent(MediaPropertySectionMediaItem.self, forKey: .media)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
    display = try container.decodeIfPresent(DisplaySettings.self, forKey: .display)
    label = try container.decodeIfPresent(String.self, forKey: .label)
    expand = try container.decodeIfPresent(Bool.self, forKey: .expand)
    use_media_settings = try container.decodeIfPresent(Bool.self, forKey: .use_media_settings)
    subproperty_id = try container.decodeIfPresent(String.self, forKey: .subproperty_id)
    subproperty_page_id = try container.decodeIfPresent(String.self, forKey: .subproperty_page_id)
    permissions = try container.decodeIfPresent(PermissionsDto.self, forKey: .permissions)
    page_id = try container.decodeIfPresent(String.self, forKey: .page_id)
    url = try container.decodeIfPresent(String.self, forKey: .url)
    primary_filter = try container.decodeIfPresent(String.self, forKey: .primary_filter)
    secondary_filter = try container.decodeIfPresent(String.self, forKey: .secondary_filter)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(id, forKey: .id)
    try container.encodeIfPresent(banner_image, forKey: .banner_image)
    try container.encodeIfPresent(banner_image_mobile, forKey: .banner_image_mobile)
    try container.encodeIfPresent(media_id, forKey: .media_id)
    try container.encodeIfPresent(media_type, forKey: .media_type)
    try container.encodeIfPresent(type, forKey: .type)
    try container.encodeIfPresent(media, forKey: .media)
    try container.encodeIfPresent(description, forKey: .description)
    try container.encodeIfPresent(disabled, forKey: .disabled)
    try container.encodeIfPresent(display, forKey: .display)
    try container.encodeIfPresent(label, forKey: .label)
    try container.encodeIfPresent(expand, forKey: .expand)
    try container.encodeIfPresent(use_media_settings, forKey: .use_media_settings)
    try container.encodeIfPresent(subproperty_id, forKey: .subproperty_id)
    try container.encodeIfPresent(subproperty_page_id, forKey: .subproperty_page_id)
    try container.encodeIfPresent(permissions, forKey: .permissions)
    try container.encodeIfPresent(page_id, forKey: .page_id)
    try container.encodeIfPresent(url, forKey: .url)
    try container.encodeIfPresent(primary_filter, forKey: .primary_filter)
    try container.encodeIfPresent(secondary_filter, forKey: .secondary_filter)
  }
}
