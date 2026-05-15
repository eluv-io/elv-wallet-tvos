import Foundation
import SwiftyJSON

extension MediaPropertyPage: Decodable {
  public enum CodingKeys: String, CodingKey {
    case id, label, layout, permissions, slug, sections, resolvedPermissions, resolvedPagePermissions
  }

  public convenience init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    layout = try container.decodeIfPresent(JSON.self, forKey: .layout)
    permissions = try container.decodeIfPresent(PermissionsDto.self, forKey: .permissions)
    label = try container.decodeIfPresent(String.self, forKey: .label)
    sections = try container.decodeIfPresent([String].self, forKey: .sections)
    resolvedPermissions = try container.decodeIfPresent(ResolvedPermission.self, forKey: .resolvedPermissions)
    resolvedPagePermissions = try container.decodeIfPresent(ResolvedPermission.self, forKey: .resolvedPagePermissions)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(id, forKey: .id)
    try container.encodeIfPresent(label, forKey: .label)
    try container.encodeIfPresent(layout, forKey: .layout)
    try container.encodeIfPresent(permissions, forKey: .permissions)
    try container.encodeIfPresent(slug, forKey: .slug)
    try container.encodeIfPresent(sections, forKey: .sections)
    try container.encodeIfPresent(resolvedPermissions, forKey: .resolvedPermissions)
    try container.encodeIfPresent(resolvedPagePermissions, forKey: .resolvedPagePermissions)
  }
}
