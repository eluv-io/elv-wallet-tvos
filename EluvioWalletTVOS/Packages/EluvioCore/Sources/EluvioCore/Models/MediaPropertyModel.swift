//
//  MediaPropertyModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-10.
//

import Foundation
import SwiftyJSON

public struct PagedContent<T: Codable>: Codable {
  public var contents: [T] = []
  public var paging: ResponsePaging = .init()
}

public struct ResponsePaging: Codable {
  public var start: Int = 0
  public var limit: Int = 0
  public var total: Int = 0
}

public typealias MediaPropertiesResponse = PagedContent<MediaProperty>
public typealias MediaPropertySectionsResponse = PagedContent<MediaPropertySection>
public typealias MediaPropertyItemsResponse = PagedContent<MediaPropertySectionMediaItem>

public class MediaProperty: Codable, Identifiable, Hashable, Permissionable {
  public var associated_marketplaces: [AssociatedMarketplaces]?
  public var tv_header_logo: ImageLink?
  public var header_logo: ImageLink?
  public var id: String = ""
  public var image: ImageLink?
  public var image_tv: ImageLink?
  public var start_screen_logo: ImageLink?
  public var start_screen_background: ImageLink?
  public var login: LoginInfo?
  public var name: String?
  public var title: String?
  public var page_title: String?
  public var parent_id: String?
  public var main_page: MediaPropertyPage?
  public var media_catalogs: [String]?
  public var permission_auth_state: PermissionStateMap?
  public var permission_sets: [String]?
  public var permissions: PermissionsDto?
  // Set on the client
  public var resolvedPermissions: ResolvedPermission?
  public var resolvedPropertyPermissions: ResolvedPermission?
  public var resolvedSearchPermissions: ResolvedPermission?
  public var permissionChildren: [any Permissionable] { [main_page].filterNotNil() }
  public var require_login: Bool?
  public var slug: String?
  public var sections: [String: MediaPropertySection]?
  public var purchase_settings: PurchaseSettings?
  public var subproperties: [String]?
  public var tenant: TenantDto?
  public var property_selection: [PropertySelection]?
  public var show_property_selection: Bool?
  public var domain: JSON?

  public static func == (lhs: MediaProperty, rhs: MediaProperty) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

/// Convenience methods
public extension MediaProperty {
  public var displayName: String {
    if let title = title, title != "" {
      return title
    } else {
      return name ?? ""
    }
  }

  public var startScreenImage: String { start_screen_logo?.url ?? "" }

  public var startScreenBackground: String { start_screen_background?.url ?? "" }

  public var backgroundImage: String { image_tv?.url ?? "" }

  public var purchaseImage: String { purchase_settings?.background_tv?.url ?? backgroundImage }

  public var accountType: AccountType {
    if login?.settings?.use_auth0 == true,
      let domain = login?.settings?.auth0_domain?.nilIfEmpty()
    {
      return AccountType.Auth0(domain: domain)
    } else {
      return .Ory
    }
  }
}

public struct PurchaseSettings: Codable {
  public var background_tv: ImageLink?
}

public struct PropertySelection: Codable {
  public var property_id: String
  public var title: String?
  public var icon: ImageLink?
  public var tile: ImageLink?
}

public enum PermissionBehavior: String, Codable, Hashable {
  case hide = "hide"
  case disable = "disable"
  case showPurchase = "show_purchase"
  case showIfUnauthorized = "show_if_unauthorized"
  case showAlternativePage = "show_alternate_page"
  // Server didn't return a response we recognized (usually "")
  case undefined

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self = PermissionBehavior(rawValue: value) ?? .undefined
  }
}
public struct PermissionsDto: Codable, Hashable {
  // Permission items required to access this object.
  public var permission_item_ids: [String]?

  // Content permissions, trickles down to children.
  public var behavior: PermissionBehavior?
  public var alternate_page_id: String?
  public var secondary_market_purchase_option: String?

  // Only applies to Pages
  public var page_permissions: [String]?
  public var page_permissions_behavior: PermissionBehavior?
  public var page_permissions_alternate_page_id: String?
  public var page_permissions_secondary_market_purchase_option: String?

  // Only applies to Properties
  public var property_permissions: [String]?
  public var property_permissions_behavior: PermissionBehavior?
  public var property_permissions_alternate_page_id: String?
  public var property_permissions_secondary_market_purchase_option: String?

  // Search results permission behavior
  public var search_permissions_behavior: PermissionBehavior?
  public var search_permissions_alternate_page_id: String?
  public var search_permissions_secondary_market_purchase_option: String?
}

public struct AssociatedMarketplaces: Codable {
  public var marketplace_id: String
  public var marketplace_slug: String
  public var tenant_slug: String
}

public final class MediaPropertyPage: Permissionable, Encodable, Equatable {
  public static func == (lhs: MediaPropertyPage, rhs: MediaPropertyPage) -> Bool {
    lhs.id == rhs.id
  }

  public var id: String = "main"
  public var layout: JSON?
  public var permissions: PermissionsDto?
  public var resolvedPermissions: ResolvedPermission?
  public var resolvedPagePermissions: ResolvedPermission?
  // Sections aren't directly connected to the object, so stop propagation here.
  public var permissionChildren: [any Permissionable] { [] }
  public var label: String?
  public var slug: String?
  public var sections: [String]?

  /// Section IDs from layout — this is where the server stores the page's section references.
  public var sectionIds: [String] {
    layout?["sections"].arrayValue.compactMap { $0.string } ?? []
  }
}

public final class MediaPropertySection: Identifiable, Hashable, Permissionable, Encodable {
  public var id: String = UUID().uuidString
  public var content: [MediaPropertySectionItem]? = []
  public var description: String?
  public var authorized: Bool?
  public var display: DisplaySettings?
  public var label: String?
  public var permissions: PermissionsDto?
  public var type: String?
  public var hero_items: JSON?
  public var sections_resolved: [MediaPropertySection]?
  public var resolvedPermissions: ResolvedPermission?
  public var permissionChildren: [any Permissionable] {
    (content ?? []) + (sections_resolved ?? [])
  }

  public var displayLimit: Int {
    display?.display_limit ?? 0
  }

  public var displayTitle: String {
    display?.title ?? ""
  }

  public var displaySubtitle: String {
    display?.subtitle ?? ""
  }

  public var displayJustification: String {
    display?.justification ?? ""
  }

  public var showViewAll: Bool {
    let content = content ?? []
    return content.count > 5 || (content.count > displayLimit && displayLimit > 0)
  }

  public static func == (lhs: MediaPropertySection, rhs: MediaPropertySection) -> Bool {
    return lhs.id == rhs.id
      && lhs.displayTitle == rhs.displayTitle
      && lhs.displaySubtitle == rhs.displaySubtitle
      && lhs.content?.count == rhs.content?.count
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(displayTitle)
  }
}

public final class MediaPropertySectionItem: Identifiable, Hashable, Permissionable, Encodable {
  public var id: String? = UUID().uuidString
  public var banner_image: ImageLink?
  public var banner_image_mobile: ImageLink?
  public var media_id: String? = UUID().uuidString
  public var media_type: String?
  public var type: String?
  public var media: MediaPropertySectionMediaItem?
  public var description: String?
  public var disabled: Bool? = false
  public var display: DisplaySettings?
  public var label: String?
  public var expand: Bool?
  public var use_media_settings: Bool? = false
  public var subproperty_id: String?
  public var subproperty_page_id: String?
  public var permissions: PermissionsDto?
  public var page_id: String?
  public var url: String?
  public var resolvedPermissions: ResolvedPermission?
  public var permissionChildren: [any Permissionable] { [media].filterNotNil() }

  public func getBannerUrl() -> String {
    return banner_image?.url ?? ""
  }

  public static func == (lhs: MediaPropertySectionItem, rhs: MediaPropertySectionItem) -> Bool {
    return lhs.id == rhs.id
      && lhs.media?.title == rhs.media?.title
      && lhs.media?.live_video == rhs.media?.live_video
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(media?.title)
  }
}

public var debugTimeStatus = false
public var debugStartDate = Date() + 4 * 60
public var debugStreamStartDate = Date() + 3 * 60
public var debugEndDate = Date() + 5 * 60

public struct IconItem: Codable {
  public var icon: ImageLink?
}

public struct MediaItemAdditionView: Codable, Identifiable, Hashable {
  public var id: String? = UUID().uuidString
  public var image: ImageLink?
  public var image_tv: ImageLink?
  public var image_hash: String? = ""
  public var label: String? = ""
  public var media_link: JSON?
  public var media_link_info: JSON?

  public var effectiveImage: ImageLink? {
    image_tv ?? image
  }

  public static func == (lhs: MediaItemAdditionView, rhs: MediaItemAdditionView) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

public final class MediaPropertySectionMediaItem: Identifiable, Hashable, Permissionable, Encodable {
  public var id: String = UUID().uuidString
  public var additional_views: [MediaItemAdditionView]?
  public var additional_views_label: String? = ""
  public var catalog_title: String? = ""
  public var description: String? = ""
  public var description_rich_text: String? = ""
  public var controls: String? = ""
  public var viewed_settings: JSON?
  public var tags: [JSON]?
  public var end_time: String? = ""
  public var offerings: [String]? = []
  public var start_time: String? = ""
  public var stream_start_time: String? = ""
  public var label: String? = ""
  public var live_video: Bool? = false
  public var gallery: [GalleryItem]? = nil
  public var headers: [String]? = nil
  public var media: [String]? = nil
  public var media_lists: [String]?
  public var media_catalog_id: String? = ""
  public var media_file: ImageLink?
  public var media_link: JSON?
  public var media_type: String? = ""
  public var poster_image: ImageLink?
  public var thumbnail_image_square: ImageLink?
  public var thumbnail_image_portrait: ImageLink?
  public var thumbnail_image_landscape: ImageLink?
  public var title: String? = ""
  public var subtitle: String? = ""
  public var type: String? = ""
  public var icons: [IconItem]? = nil
  public var `public`: Bool? = nil
  // Normalized at decode time from the server's [{permission_item_id: "..."}] format
  public var permissions: PermissionsDto?
  // Original server JSON for permissions, used by legacy Fabric.swift code
  public var legacy_permissions: JSON?
  public var resolvedPermissions: ResolvedPermission?
  public var permissionChildren: [any Permissionable] { [] }
}

public struct TenantDto: Codable {
  public var tenant_id: String
  public var tenant_iten: String?
}

public struct LoginInfo: Codable {
  public var settings: LoginSettings?
  public var styling: LoginStyling?
}

public struct LoginSettings: Codable {
  public var use_auth0: Bool?
  public var disable_login: Bool?
  public var auth0_domain: String?

  // Deprecated. This field should no longer be considered
  public var provider: String?

  // Deprecated
  public var auth0_native_client_id: String?
}

public struct LoginStyling: Codable {
  public var background_image_tv: ImageLink?
  public var background_image_desktop: ImageLink?

  public var logo_tv: ImageLink?
  public var logo: ImageLink?
}
