import Observation

@MainActor
@Observable
public class PropertyStore {
  public static let shared = PropertyStore()

  // Cache of "discoverable" Properties - those returned in the normal /properties call
  public private(set) var properties: [MediaProperty] = []

  // Properties that were fetched by the client, but not necessarily in the Discover page.
  // User either owns an NFT related to the Property, or fetched it manually somehow (deeplink, subproperties)
  public private(set) var ownedProperties: [String: MediaProperty] = [:]

  // Page cache keyed by "propertyId:pageId"
  private var pageCache: [String: MediaPropertyPage] = [:]

  // Section cache keyed by section ID
  private var sectionCache: [String: MediaPropertySection] = [:]

  private init() {
    let cache = PersistentDataCache()
    properties =
      cache.loadCachedPropertyViewModels(
        network: NetworkStore.shared.selectedNetwork.rawValue,
        environment: NetworkStore.shared.environment.rawValue
      ) ?? []
    sectionCache =
      cache.loadCachedSections(
        network: NetworkStore.shared.selectedNetwork.rawValue,
        environment: NetworkStore.shared.environment.rawValue
      ) ?? [:]
  }

  public func clear() {
    properties = []
    ownedProperties = [:]
    pageCache = [:]
    sectionCache = [:]
  }

  public func fetchProperties(includePublic: Bool = true, retries: Int = 3) async {
    for attempt in 1...retries {
      do {
        let response: MediaPropertiesResponse = try await NetworkManager.shared
          .request("mw/properties?include_public=\(includePublic)")

        let properties = response.contents
        resolvePermissions(properties: properties)

        if includePublic {
          self.properties = properties
          PersistentDataCache().cachePropertyViewModels(
            properties,
            network: NetworkStore.shared.selectedNetwork.rawValue,
            environment: NetworkStore.shared.environment.rawValue
          )
        } else {
          properties.forEach {
            ownedProperties[$0.id] = $0
          }
        }
        return
      } catch {
        print("Error loading properties (attempt \(attempt)/\(retries)): \(error)")
        if attempt < retries {
          try? await Task.sleep(for: .seconds(2 * attempt))
        }
      }
    }
  }

  private func resolvePermissions(properties: [MediaProperty]) {
    properties.forEach {
      PermissionResolver.resolvePermissions($0, permissionStates: $0.permission_auth_state ?? [:])
    }
  }

  public func fetchProperty(id: String) async {
    do {
      let property: MediaProperty = try await NetworkManager.shared.request("mw/properties/\(id)")
      debugPrint("Fetched single property: \(id)")
      resolvePermissions(properties: [property])

      if let index = properties.firstIndex(where: { $0.id == id }) {
        properties[index] = property
      } else {
        // Property doesn't exist in "Discover" page, cache separately
        ownedProperties[id] = property
      }
    } catch {
      print("Error loading property \(id)")
    }
  }

  public func getProperty(id: String) -> MediaProperty? {
    // Given the amount of Properties we are dealing with (sub 100), iterating like this should be
    // pretty fast and we don't need to bother with a hashmap for quick lookups by id
    return properties.first { $0.id == id } ?? ownedProperties[id]
  }

  // MARK: - Pages

  /// Returns page from cache if exists, otherwise from network
  fileprivate func getPage(
    property: MediaProperty,
    pageId: String
  ) async throws -> MediaPropertyPage {
    let cacheKey = "\(property.id):\(pageId)"
    if let cached = pageCache[cacheKey] {
      debugPrint("Page fetched from cache \(cacheKey)")
      return cached
    }
    debugPrint("Page cache miss, fetching \(cacheKey)")
    return try await fetchPage(property: property, pageId: pageId)
  }

  /// Fetches a page by ID, resolves its permissions, caches it, and returns it.
  public func fetchPage(
    property: MediaProperty,
    pageId: String
  ) async throws -> MediaPropertyPage {
    let cacheKey = "\(property.id):\(pageId)"

    let page: MediaPropertyPage = try await NetworkManager.shared
      .request("mw/properties/\(property.id)/pages/\(pageId)")
    PermissionResolver.resolvePermissions(
      page,
      parentPermissions: property.resolvedPermissions,
      permissionStates: property.permission_auth_state ?? [:])
    pageCache[cacheKey] = page
    return page
  }

  // MARK: - Sections

  /// Fetches all sections into cache with permissions already resolved.
  /// Unauthorized sections with "hide" permission behavior, or sections with only hidden items - will be dropped and not cached.
  public func fetchSections(property: MediaProperty, page: MediaPropertyPage) async {
    do {
      let response: MediaPropertySectionsResponse = try await NetworkManager.shared.request(
        "mw/properties/\(property.id)/sections?resolve_subsections=true",
        body: page.sectionIds
      )
      PermissionResolver.resolvePermissions(
        response.contents,
        parentPermissions: page.resolvedPermissions,
        permissionStates: property.permission_auth_state ?? [:]
      )
      for section in response.contents {
        if section.shouldHide {
          debugPrint("Dropping hidden section \(section.id)")
        } else {
          sectionCache[section.id] = section
        }
      }
      PersistentDataCache().cacheSections(
        sectionCache,
        network: NetworkStore.shared.selectedNetwork.rawValue,
        environment: NetworkStore.shared.environment.rawValue
      )
    } catch {
      print("Error fetching sections: \(error)")
    }
  }

  /// Returns cached sections for the given page (permissions already resolved).
  public func sections(for page: MediaPropertyPage) -> [MediaPropertySection] {
    return page.sectionIds.compactMap { sectionCache[$0] }
  }

}

public extension MediaPropertySection {
  fileprivate var shouldHide: Bool {
    if resolvedPermissions?.hide == true || display?.hide_on_tv == true {
      true
    } else if type?.lowercased() == "hero" {
      false
    } else if type?.lowercased() == "container" {
      sections_resolved?.allSatisfy { $0.shouldHide } == true
    } else {
      content?.allSatisfy { $0.resolvedPermissions?.hide == true } == true
    }
  }

  public var shouldHideInContainer: Bool {
    if resolvedPermissions?.hide == true || display?.hide_on_tv == true {
      return true
    }
    if type?.lowercased() == "hero" {
      return false
    }
    let items = content ?? []
    if items.isEmpty { return true }
    return items.allSatisfy { $0.resolvedPermissions?.hide == true }
  }
}

public extension PropertyStore {
  /// Finds the first page we are authorized to view, following redirects as needed.
  /// Throws `PageRedirectError` for purchase gates or circular redirects.
  public func getFirstAuthorizedPage(
    property: MediaProperty,
    pageId: String? = nil
  ) async throws -> MediaPropertyPage {
    var startPage: MediaPropertyPage? = nil
    if let pageId, !pageId.isEmpty {
      startPage = try await getPage(property: property, pageId: pageId)
    } else {
      startPage = property.main_page
    }
    var visitedPageIds: Set<String> = []
    return try await resolveAuthorizedPage(
      property: property, currentPage: startPage, visitedPageIds: &visitedPageIds)
  }

  private func resolveAuthorizedPage(
    property: MediaProperty,
    currentPage: MediaPropertyPage?,
    visitedPageIds: inout Set<String>
  ) async throws -> MediaPropertyPage {
    guard let page = currentPage else {
      // No page yet — check property-level permissions first
      if let propPerms = property.resolvedPropertyPermissions {
        if propPerms.showAlternatePage, !propPerms.alternatePageId.isEmpty {
          let redirectPage = try await getPage(
            property: property, pageId: propPerms.alternatePageId)
          return try await resolveAuthorizedPage(
            property: property, currentPage: redirectPage, visitedPageIds: &visitedPageIds)
        }
        if propPerms.purchaseGate {
          throw PageRedirectError.purchaseRequired(propertyId: property.id, pageId: nil)
        }
      }
      // Authorized at property level — use the embedded main page (already has sections, etc.)
      return try await resolveAuthorizedPage(
        property: property, currentPage: property.main_page, visitedPageIds: &visitedPageIds)
    }

    // Check for purchase gate on page
    if page.resolvedPagePermissions?.purchaseGate == true {
      throw PageRedirectError.purchaseRequired(propertyId: property.id, pageId: page.id)
    }

    // Check for alternate page redirect
    guard let pagePerms = page.resolvedPagePermissions,
      pagePerms.showAlternatePage,
      !pagePerms.alternatePageId.isEmpty
    else {
      // No redirect needed — authorized to view this page
      return page
    }

    let redirectPageId = pagePerms.alternatePageId

    // Circular redirect detection
    if redirectPageId == page.id || visitedPageIds.contains(redirectPageId) {
      throw PageRedirectError.circularRedirect
    }

    visitedPageIds.insert(page.id)
    let redirectPage = try await getPage(property: property, pageId: redirectPageId)
    return try await resolveAuthorizedPage(
      property: property, currentPage: redirectPage, visitedPageIds: &visitedPageIds)
  }
}
