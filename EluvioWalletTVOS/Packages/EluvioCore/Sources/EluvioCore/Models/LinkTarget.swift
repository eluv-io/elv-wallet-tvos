import Foundation
import SwiftyJSON

/// Where a hero action or header link navigates to. Both carry the same set of link fields
/// (`behavior`, `media_id`, `page_id`, `property`, `subproperty`, `url`, ...).
public struct LinkTarget: Hashable {
  /// Hero actions also define "sign_in", "show_purchase" and "video" behaviors,
  /// which we don't support (and therefore don't parse) yet.
  public static let supportedBehaviors: Set<String> = [
    "media_link", "page_link", "link", "property_link", "subproperty_link",
  ]

  public var behavior: String
  /// Defined for "media_link" links.
  public var mediaId: String?
  /// Defined for "page_link" links, where it's a page within the current
  /// property, and optionally for "property_link"/"subproperty_link" links,
  /// where it's a page within the linked property.
  public var pageId: String?
  /// Defined for "property_link" links (where the server sends a slug, which
  /// the property endpoint accepts in place of an id) and "subproperty_link" links.
  public var propertyId: String?
  /// Defined for "link" links.
  public var url: String?

  /// Returns nil for unsupported behaviors and for links with no target.
  public static func parse(_ json: JSON) -> LinkTarget? {
    let behavior = json["behavior"].stringValue
    guard supportedBehaviors.contains(behavior) else { return nil }

    // The server doesn't clear the link fields that don't apply to the current
    // behavior, so only read the one that does.
    var target = LinkTarget(behavior: behavior)
    switch behavior {
    case "media_link": target.mediaId = json["media_id"].string?.nilIfEmpty()
    case "page_link": target.pageId = json["page_id"].string?.nilIfEmpty()
    case "link": target.url = json["url"].string?.nilIfEmpty()
    case "property_link":
      target.propertyId = json["property"].string?.nilIfEmpty()
      // A page alone has nothing to navigate to.
      if target.propertyId != nil { target.pageId = json["property_page"].string?.nilIfEmpty() }
    case "subproperty_link":
      target.propertyId = json["subproperty"].string?.nilIfEmpty()
      if target.propertyId != nil { target.pageId = json["subproperty_page"].string?.nilIfEmpty() }
    default: break
    }
    if target.mediaId == nil && target.pageId == nil && target.propertyId == nil
      && target.url == nil
    {
      return nil
    }
    return target
  }
}
