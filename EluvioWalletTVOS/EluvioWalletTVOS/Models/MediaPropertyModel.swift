//
//  MediaPropertyModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-10.
//

import Foundation
import SwiftyJSON

struct PagedContent<T: Codable>: Codable {
  var contents: [T] = []
  var paging: ResponsePaging = .init()
}

struct ResponsePaging: Codable {
  var start: Int = 0
  var limit: Int = 0
  var total: Int = 0
}

typealias MediaPropertiesResponse = PagedContent<MediaProperty>
typealias MediaPropertySectionsResponse = PagedContent<MediaPropertySection>
typealias MediaPropertyItemsResponse = PagedContent<MediaPropertySectionMediaItem>
typealias MultiviewResponse = PagedContent<MediaPropertySectionMediaItem>

class MediaProperty: Codable, Identifiable, Hashable, Permissionable {
  var associated_marketplaces: [AssociatedMarketplaces]?
  var tv_header_logo: ImageLink?
  var header_logo: ImageLink?
  var id: String = ""
  var image: ImageLink?
  var image_tv: ImageLink?
  var start_screen_logo: ImageLink?
  var start_screen_background: ImageLink?
  var login: LoginInfo?
  var name: String?
  var title: String?
  var page_title: String?
  var parent_id: String?
  var main_page: MediaPropertyPage?
  var media_catalogs: [String]?
  var permission_auth_state: PermissionStateMap?
  var permission_sets: [String]?
  var permissions: PermissionsDto?
  // Set on the client
  var resolvedPermissions: ResolvedPermission?
  var resolvedPropertyPermissions: ResolvedPermission?
  var resolvedSearchPermissions: ResolvedPermission?
  var permissionChildren: [any Permissionable] { [main_page].filterNotNil() }
  var require_login: Bool?
  var slug: String?
  var sections: [String: MediaPropertySection]?
  var purchase_settings: PurchaseSettings?
  var subproperties: [String]?
  var tenant: TenantDto?
  var property_selection: [PropertySelection]?
  var show_property_selection: Bool?
  var domain: JSON?

  static func == (lhs: MediaProperty, rhs: MediaProperty) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

/// Convenience methods
extension MediaProperty {
  var displayName: String {
    if let title = title, title != "" {
      return title
    } else {
      return name ?? ""
    }
  }

  var startScreenImage: String { start_screen_logo?.url ?? "" }

  var startScreenBackground: String { start_screen_background?.url ?? "" }

  var backgroundImage: String { image_tv?.url ?? "" }

  var purchaseImage: String { purchase_settings?.background_tv?.url ?? backgroundImage }

  var accountType: AccountType {
    if login?.settings?.use_auth0 == true,
      let domain = login?.settings?.auth0_domain?.nilIfEmpty()
    {
      return AccountType.Auth0(domain: domain)
    } else {
      return .Ory
    }
  }
}

struct PurchaseSettings: Codable {
  var background_tv: ImageLink?
}

struct PropertySelection: Codable {
  var property_id: String
  var title: String?
  var icon: ImageLink?
  var tile: ImageLink?
}

enum PermissionBehavior: String, Codable, Hashable {
  case hide = "hide"
  case disable = "disable"
  case showPurchase = "show_purchase"
  case showIfUnauthorized = "show_if_unauthorized"
  case showAlternativePage = "show_alternate_page"
  // Server didn't return a response we recognized (usually "")
  case undefined

  init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self = PermissionBehavior(rawValue: value) ?? .undefined
  }
}
struct PermissionsDto: Codable, Hashable {
  // Permission items required to access this object.
  var permission_item_ids: [String]?

  // Content permissions, trickles down to children.
  var behavior: PermissionBehavior?
  var alternate_page_id: String?
  var secondary_market_purchase_option: String?

  // Only applies to Pages
  var page_permissions: [String]?
  var page_permissions_behavior: PermissionBehavior?
  var page_permissions_alternate_page_id: String?
  var page_permissions_secondary_market_purchase_option: String?

  // Only applies to Properties
  var property_permissions: [String]?
  var property_permissions_behavior: PermissionBehavior?
  var property_permissions_alternate_page_id: String?
  var property_permissions_secondary_market_purchase_option: String?

  // Search results permission behavior
  var search_permissions_behavior: PermissionBehavior?
  var search_permissions_alternate_page_id: String?
  var search_permissions_secondary_market_purchase_option: String?
}

struct AssociatedMarketplaces: Codable {
  var marketplace_id: String
  var marketplace_slug: String
  var tenant_slug: String
}

final class MediaPropertyPage: Permissionable, Encodable, Equatable {
  static func == (lhs: MediaPropertyPage, rhs: MediaPropertyPage) -> Bool {
    lhs.id == rhs.id
  }

  var id: String? = UUID().uuidString
  var layout: JSON?
  var permissions: PermissionsDto?
  var resolvedPermissions: ResolvedPermission?
  var resolvedPagePermissions: ResolvedPermission?
  // Sections aren't directly connected to the object, so stop propagation here.
  var permissionChildren: [any Permissionable] { [] }
  var label: String?
  var slug: String?
  var sections: [String]?

  /// Section IDs from layout — this is where the server stores the page's section references.
  var sectionIds: [String] {
    layout?["sections"].arrayValue.compactMap { $0.string } ?? []
  }
}

final class MediaPropertySection: Identifiable, Hashable, Permissionable, Encodable {
  var id: String = UUID().uuidString
  var content: [MediaPropertySectionItem]? = []
  var description: String?
  var authorized: Bool?
  var display: DisplaySettings?
  var label: String?
  var permissions: PermissionsDto?
  var type: String?
  var hero_items: JSON?
  var sections_resolved: [MediaPropertySection]?
  var resolvedPermissions: ResolvedPermission?
  var permissionChildren: [any Permissionable] { content ?? [] }

  var displayLimit: Int {
    display?.display_limit ?? 0
  }

  var displayTitle: String {
    display?.title ?? ""
  }

  var displaySubtitle: String {
    display?.subtitle ?? ""
  }

  var displayJustification: String {
    display?.justification ?? ""
  }

  static func == (lhs: MediaPropertySection, rhs: MediaPropertySection) -> Bool {
    return lhs.id == rhs.id
      && lhs.displayTitle == rhs.displayTitle
      && lhs.displaySubtitle == rhs.displaySubtitle
      && lhs.content?.count == rhs.content?.count
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(displayTitle)
  }
}

final class MediaPropertySectionItem: Identifiable, Hashable, Permissionable, Encodable {
  var id: String? = UUID().uuidString
  var banner_image: ImageLink?
  var banner_image_mobile: ImageLink?
  var media_id: String? = UUID().uuidString
  var media_type: String?
  var type: String?
  var media: MediaPropertySectionMediaItem?
  var description: String?
  var disabled: Bool? = false
  var display: DisplaySettings?
  var label: String?
  var expand: Bool?
  var use_media_settings: Bool? = false
  var subproperty_id: String?
  var subproperty_page_id: String?
  var permissions: PermissionsDto?
  var page_id: String?
  var url: String?
  var resolvedPermissions: ResolvedPermission?
  var permissionChildren: [any Permissionable] { [media].filterNotNil() }

  func getBannerUrl() -> String {
    return banner_image?.url ?? ""
  }

  static func == (lhs: MediaPropertySectionItem, rhs: MediaPropertySectionItem) -> Bool {
    return lhs.id == rhs.id
      && lhs.media?.title == rhs.media?.title
      && lhs.media?.live_video == rhs.media?.live_video
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(media?.title)
  }
}

var debugTimeStatus = false
var debugStartDate = Date() + 4 * 60
var debugStreamStartDate = Date() + 3 * 60
var debugEndDate = Date() + 5 * 60

struct IconItem: Codable {
  var icon: ImageLink?
}

struct MediaItemAdditionView: Codable, Identifiable, Hashable {
  var id: String? = UUID().uuidString
  var image: ImageLink?
  var image_tv: ImageLink?
  var image_hash: String? = ""
  var label: String? = ""
  var media_link: JSON?
  var media_link_info: JSON?

  var effectiveImage: ImageLink? {
    if let image = image, image.url != nil {
      return image
    }
    if let image_tv = image_tv, image_tv.url != nil {
      return image_tv
    }
    return nil
  }

  static func == (lhs: MediaItemAdditionView, rhs: MediaItemAdditionView) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

final class MediaPropertySectionMediaItem: Identifiable, Hashable, Permissionable, Encodable {
  var id: String = UUID().uuidString
  var additional_views: [MediaItemAdditionView]?
  var additional_views_label: String? = ""
  var catalog_title: String? = ""
  var description: String? = ""
  var description_rich_text: String? = ""
  var controls: String? = ""
  var viewed_settings: JSON?
  var tags: [JSON]?
  var end_time: String? = ""
  var offerings: [String]? = []
  var start_time: String? = ""
  var stream_start_time: String? = ""
  var label: String? = ""
  var live_video: Bool? = false
  var gallery: [GalleryItem]? = nil
  var headers: [String]? = nil
  var media: [String]? = nil
  var media_lists: [String]?
  var media_catalog_id: String? = ""
  var media_file: ImageLink?
  var media_link: JSON?
  var media_type: String? = ""
  var poster_image: ImageLink?
  var thumbnail_image_square: ImageLink?
  var thumbnail_image_portrait: ImageLink?
  var thumbnail_image_landscape: ImageLink?
  var title: String? = ""
  var subtitle: String? = ""
  var type: String? = ""
  var icons: [IconItem]? = nil
  var `public`: Bool? = nil
  // Normalized at decode time from the server's [{permission_item_id: "..."}] format
  var permissions: PermissionsDto?
  // Original server JSON for permissions, used by legacy Fabric.swift code
  var legacy_permissions: JSON?
  var resolvedPermissions: ResolvedPermission?
  var permissionChildren: [any Permissionable] { [] }
}

struct TenantDto: Codable {
  var tenant_id: String
  var tenant_iten: String?
}

struct LoginInfo: Codable {
  var settings: LoginSettings?
  var styling: LoginStyling?
}

struct LoginSettings: Codable {
  var use_auth0: Bool?
  var disable_login: Bool?
  var auth0_domain: String?

  // Deprecated. This field should no longer be considered
  var provider: String?

  // Deprecated
  var auth0_native_client_id: String?
}

struct LoginStyling: Codable {
  var background_image_tv: ImageLink?
  var background_image_desktop: ImageLink?

  var logo_tv: ImageLink?
  var logo: ImageLink?
}
