import Foundation
import SwiftUI
import SwiftyJSON

public enum SectionPosition {
  case Left, Right, Center
}

/// A CTA button defined on a hero item.
public struct HeroAction: Identifiable {
  public var id: String
  public var behavior: String
  /// Defined for "media_link" actions.
  public var mediaId: String?
  /// Defined for "page_link" actions, where it's a page within the current
  /// property, and optionally for "property_link"/"subproperty_link" actions,
  /// where it's a page within the linked property.
  public var pageId: String?
  /// Defined for "property_link" actions (where the server sends a slug, which
  /// the property endpoint accepts in place of an id) and "subproperty_link" actions.
  public var propertyId: String?
  /// Defined for "link" actions.
  public var url: String?
  /// Set by the property owner to keep this button off the TV apps.
  public var hideOnTv: Bool

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
    propertyId: String? = nil,
    url: String? = nil,
    hideOnTv: Bool = false,
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
    self.propertyId = propertyId
    self.url = url
    self.hideOnTv = hideOnTv
    self.text = text
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.borderColor = borderColor
    self.cornerRadius = cornerRadius
  }

  public var target: LinkTarget {
    LinkTarget(
      behavior: behavior, mediaId: mediaId, pageId: pageId, propertyId: propertyId, url: url)
  }

  /// Returns nil for actions we can't render or act on (unsupported behavior,
  /// no button text, or no link target) - those shouldn't show a button at all.
  /// Text and styling come exclusively from the action's "button" object - the
  /// top-level "text"/"label"/"colors"/"border_radius" fields are a legacy spec
  /// the server still emits with stale defaults, and "button_style" is ignored
  /// by agreement.
  public static func create(from json: JSON) -> HeroAction? {
    guard LinkTarget.supportedBehaviors.contains(json["behavior"].stringValue) else { return nil }

    let button = json["button"]
    guard let text = button["text"].string?.nilIfEmpty() else { return nil }

    guard let target = LinkTarget.parse(json) else {
      debugPrint("Ignoring hero action with no click target: ", json)
      return nil
    }

    return HeroAction(
      id: json["id"].stringValue,
      behavior: target.behavior,
      mediaId: target.mediaId,
      pageId: target.pageId,
      propertyId: target.propertyId,
      url: target.url,
      hideOnTv: json["hide_on_tv"].boolValue,
      text: text,
      backgroundColor: Color(hexString: button["background_color"].string) ?? .white,
      textColor: Color(hexString: button["text_color"].string) ?? .black,
      borderColor: Color(hexString: button["border_color"].string),
      cornerRadius: CGFloat(button["border_radius"].int ?? 5)
    )
  }
}
