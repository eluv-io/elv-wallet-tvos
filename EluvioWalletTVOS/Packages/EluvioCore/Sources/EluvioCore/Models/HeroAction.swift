import Foundation
import SwiftUI
import SwiftyJSON

public enum SectionPosition {
  case Left, Right, Center
}

/// A CTA button defined on a hero item.
public struct HeroAction: Identifiable {
  /// The server also defines "sign_in", "show_purchase" and "video" behaviors,
  /// which we don't support (and therefore don't parse) yet.
  public static let supportedBehaviors: Set<String> = ["media_link", "page_link", "link"]

  public var id: String
  public var behavior: String
  /// Defined for "media_link" actions.
  public var mediaId: String?
  /// Defined for "page_link" actions. Always a page within the current property.
  public var pageId: String?
  /// Defined for "link" actions.
  public var url: String?

  public var text: String
  public var backgroundColor: Color
  public var textColor: Color
  public var borderColor: Color?
  public var cornerRadius: CGFloat

  public init(
    id: String,
    behavior: String,
    mediaId: String? = nil,
    pageId: String? = nil,
    url: String? = nil,
    text: String,
    backgroundColor: Color,
    textColor: Color,
    borderColor: Color? = nil,
    cornerRadius: CGFloat
  ) {
    self.id = id
    self.behavior = behavior
    self.mediaId = mediaId
    self.pageId = pageId
    self.url = url
    self.text = text
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.borderColor = borderColor
    self.cornerRadius = cornerRadius
  }

  /// Returns nil for actions we can't render or act on (unsupported behavior,
  /// no button text, or no link target) - those shouldn't show a button at all.
  /// Text and styling come exclusively from the action's "button" object - the
  /// top-level "text"/"label"/"colors"/"border_radius" fields are a legacy spec
  /// the server still emits with stale defaults, and "button_style" is ignored
  /// by agreement.
  public static func create(from json: JSON) -> HeroAction? {
    let behavior = json["behavior"].stringValue
    guard HeroAction.supportedBehaviors.contains(behavior) else { return nil }

    let button = json["button"]
    guard let text = button["text"].string?.nilIfEmpty() else { return nil }

    // Like section items, the server doesn't clear the link fields that don't
    // apply to the current behavior, so only read the one that does.
    var mediaId: String? = nil
    var pageId: String? = nil
    var url: String? = nil
    switch behavior {
    case "media_link": mediaId = json["media_id"].string?.nilIfEmpty()
    case "page_link": pageId = json["page_id"].string?.nilIfEmpty()
    case "link": url = json["url"].string?.nilIfEmpty()
    default: break
    }
    if mediaId == nil && pageId == nil && url == nil {
      debugPrint("Ignoring hero action with no click target: ", json)
      return nil
    }

    return HeroAction(
      id: json["id"].stringValue,
      behavior: behavior,
      mediaId: mediaId,
      pageId: pageId,
      url: url,
      text: text,
      backgroundColor: Color(hexString: button["background_color"].string) ?? .white,
      textColor: Color(hexString: button["text_color"].string) ?? .black,
      borderColor: Color(hexString: button["border_color"].string),
      cornerRadius: CGFloat(button["border_radius"].int ?? 5)
    )
  }
}
