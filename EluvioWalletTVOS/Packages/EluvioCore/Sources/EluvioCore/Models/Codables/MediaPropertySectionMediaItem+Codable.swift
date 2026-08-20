import Foundation
import SwiftyJSON

extension MediaPropertySectionMediaItem: Decodable {
  public enum CodingKeys: String, CodingKey {
    case id, catalog_title, description, description_rich_text, controls
    case viewed_settings, tags, end_time, offerings, start_time, stream_start_time
    case label, live_video, gallery, headers, media, media_lists, media_catalog_id
    case media_file, media_link, media_type, poster_image
    case thumbnail_image_square, thumbnail_image_portrait, thumbnail_image_landscape
    case countdown_background_desktop
    case title, subtitle, type, icons
    case `public`, permissions
    case additional_views, additional_views_label, resolvedPermissions
  }

  public convenience init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    additional_views = try container.decodeIfPresent([MediaItemAdditionView].self, forKey: .additional_views)
    additional_views_label = try container.decodeIfPresent(String.self, forKey: .additional_views_label)
    catalog_title = try container.decodeIfPresent(String.self, forKey: .catalog_title)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    description_rich_text = try container.decodeIfPresent(String.self, forKey: .description_rich_text)
    controls = try container.decodeIfPresent(String.self, forKey: .controls)
    viewed_settings = try container.decodeIfPresent(JSON.self, forKey: .viewed_settings)
    tags = try container.decodeIfPresent([JSON].self, forKey: .tags)
    end_time = try container.decodeIfPresent(String.self, forKey: .end_time)
    offerings = try container.decodeIfPresent([String].self, forKey: .offerings)
    start_time = try container.decodeIfPresent(String.self, forKey: .start_time)
    stream_start_time = try container.decodeIfPresent(String.self, forKey: .stream_start_time)
    label = try container.decodeIfPresent(String.self, forKey: .label)
    live_video = try container.decodeIfPresent(Bool.self, forKey: .live_video)
    gallery = try container.decodeIfPresent([GalleryItem].self, forKey: .gallery)
    headers = try container.decodeIfPresent([String].self, forKey: .headers)
    media = try container.decodeIfPresent([String].self, forKey: .media)
    media_lists = try container.decodeIfPresent([String].self, forKey: .media_lists)
    media_catalog_id = try container.decodeIfPresent(String.self, forKey: .media_catalog_id)
    media_file = try container.decodeIfPresent(ImageLink.self, forKey: .media_file)
    media_link = try container.decodeIfPresent(JSON.self, forKey: .media_link)
    media_type = try container.decodeIfPresent(String.self, forKey: .media_type)
    poster_image = try container.decodeIfPresent(ImageLink.self, forKey: .poster_image)
    thumbnail_image_square = try container.decodeIfPresent(ImageLink.self, forKey: .thumbnail_image_square)
    thumbnail_image_portrait = try container.decodeIfPresent(ImageLink.self, forKey: .thumbnail_image_portrait)
    thumbnail_image_landscape = try container.decodeIfPresent(ImageLink.self, forKey: .thumbnail_image_landscape)
    countdown_background_desktop = try container.decodeIfPresent(ImageLink.self, forKey: .countdown_background_desktop)
    title = try container.decodeIfPresent(String.self, forKey: .title)
    subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
    type = try container.decodeIfPresent(String.self, forKey: .type)
    icons = try container.decodeIfPresent([IconItem].self, forKey: .icons)
    self.public = try container.decodeIfPresent(Bool.self, forKey: .public)


    // Keep the original JSON for legacy Fabric.swift code
    legacy_permissions = try container.decodeIfPresent(JSON.self, forKey: .permissions)

    // Normalize media permissions from [{permission_item_id: "..."}] to PermissionsDto.
    // The server uses a different format for media items than for other entities.
    let rawPermissions = try container.decodeIfPresent([RawMediaPermission].self, forKey: .permissions)
    if self.public != true, let rawPerms = rawPermissions {
      let ids = rawPerms.compactMap { $0.permission_item_id }
      // Add a dummy empty-string permission ID so private items are unauthorized by default.
      // Having any real authorized ID still grants access (calcAuthorized uses `contains`).
      permissions = PermissionsDto(permission_item_ids: ids + [""])
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(id, forKey: .id)
    try container.encodeIfPresent(additional_views, forKey: .additional_views)
    try container.encodeIfPresent(additional_views_label, forKey: .additional_views_label)
    try container.encodeIfPresent(catalog_title, forKey: .catalog_title)
    try container.encodeIfPresent(description, forKey: .description)
    try container.encodeIfPresent(description_rich_text, forKey: .description_rich_text)
    try container.encodeIfPresent(controls, forKey: .controls)
    try container.encodeIfPresent(viewed_settings, forKey: .viewed_settings)
    try container.encodeIfPresent(tags, forKey: .tags)
    try container.encodeIfPresent(end_time, forKey: .end_time)
    try container.encodeIfPresent(offerings, forKey: .offerings)
    try container.encodeIfPresent(start_time, forKey: .start_time)
    try container.encodeIfPresent(stream_start_time, forKey: .stream_start_time)
    try container.encodeIfPresent(label, forKey: .label)
    try container.encodeIfPresent(live_video, forKey: .live_video)
    try container.encodeIfPresent(gallery, forKey: .gallery)
    try container.encodeIfPresent(headers, forKey: .headers)
    try container.encodeIfPresent(media, forKey: .media)
    try container.encodeIfPresent(media_lists, forKey: .media_lists)
    try container.encodeIfPresent(media_catalog_id, forKey: .media_catalog_id)
    try container.encodeIfPresent(media_file, forKey: .media_file)
    try container.encodeIfPresent(media_link, forKey: .media_link)
    try container.encodeIfPresent(media_type, forKey: .media_type)
    try container.encodeIfPresent(poster_image, forKey: .poster_image)
    try container.encodeIfPresent(thumbnail_image_square, forKey: .thumbnail_image_square)
    try container.encodeIfPresent(thumbnail_image_portrait, forKey: .thumbnail_image_portrait)
    try container.encodeIfPresent(thumbnail_image_landscape, forKey: .thumbnail_image_landscape)
    try container.encodeIfPresent(countdown_background_desktop, forKey: .countdown_background_desktop)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(subtitle, forKey: .subtitle)
    try container.encodeIfPresent(type, forKey: .type)
    try container.encodeIfPresent(icons, forKey: .icons)
    try container.encodeIfPresent(self.public, forKey: .public)
    // Encode permissions as the legacy JSON to preserve the original server format
    try container.encodeIfPresent(legacy_permissions, forKey: .permissions)
  }
}

/// Raw server format for media item permissions.
private struct RawMediaPermission: Codable {
  public var permission_item_id: String?
}
