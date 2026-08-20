import Foundation
import SwiftyJSON

extension MediaPropertySection: Decodable {
  public enum CodingKeys: String, CodingKey {
    case id, content, description, authorized, display, label, permissions, type, hero_items, sections_resolved, resolvedPermissions
  }

  public convenience init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    content = try container.decodeIfPresent([MediaPropertySectionItem].self, forKey: .content) ?? []
    description = try container.decodeIfPresent(String.self, forKey: .description)
    authorized = try container.decodeIfPresent(Bool.self, forKey: .authorized)
    display = try container.decodeIfPresent(DisplaySettings.self, forKey: .display)
    label = try container.decodeIfPresent(String.self, forKey: .label)
    permissions = try container.decodeIfPresent(PermissionsDto.self, forKey: .permissions)
    type = try container.decodeIfPresent(String.self, forKey: .type)
    hero_items = try container.decodeIfPresent(JSON.self, forKey: .hero_items)
    sections_resolved = try container.decodeIfPresent([MediaPropertySection].self, forKey: .sections_resolved)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(id, forKey: .id)
    try container.encodeIfPresent(content, forKey: .content)
    try container.encodeIfPresent(description, forKey: .description)
    try container.encodeIfPresent(authorized, forKey: .authorized)
    try container.encodeIfPresent(display, forKey: .display)
    try container.encodeIfPresent(label, forKey: .label)
    try container.encodeIfPresent(permissions, forKey: .permissions)
    try container.encodeIfPresent(type, forKey: .type)
    try container.encodeIfPresent(hero_items, forKey: .hero_items)
    try container.encodeIfPresent(sections_resolved, forKey: .sections_resolved)
  }
}
