import Foundation
import SwiftyJSON

/// A link from a property's `header_links`, shown in the property page's header menu.
public struct HeaderLink: Identifiable, Hashable {
  public var id: String
  public var text: String
  public var iconUrl: String?
  public var target: LinkTarget

  public init(id: String, text: String, iconUrl: String? = nil, target: LinkTarget) {
    self.id = id
    self.text = text
    self.iconUrl = iconUrl
    self.target = target
  }

  /// Returns nil for links we can't show: no text, no supported target, kept off the TV apps
  /// by the property owner, or hidden for the current sign-in state.
  public static func create(from json: JSON) -> HeaderLink? {
    guard let text = json["text"].string?.nilIfEmpty(),
      !json["hide_on_tv"].boolValue,
      let target = LinkTarget.parse(json)
    else { return nil }

    switch json["visibility"].stringValue {
    case "authenticated" where AccountStore.shared.isLoggedOut: return nil
    case "unauthenticated" where !AccountStore.shared.isLoggedOut: return nil
    default: break
    }

    return HeaderLink(
      id: json["id"].stringValue,
      text: text,
      iconUrl: json["icon"].dictionary == nil
        ? nil : (try? JSONDecoder().decode(ImageLink.self, from: json["icon"].rawData()))?.url,
      target: target)
  }
}
