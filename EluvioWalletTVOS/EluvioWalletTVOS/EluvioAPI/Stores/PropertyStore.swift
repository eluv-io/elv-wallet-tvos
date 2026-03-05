import Observation

@MainActor
@Observable
class PropertyStore {
  static let shared = PropertyStore()

  // Cache of "discoverable" Properties - those returned in the normal /properties call
  private(set) var properties: [MediaProperty] = []

  // Properties that were fetched by the client, but not necessarily in the Discover page.
  // User either owns an NFT related to the Property, or fetched it manually somehow (deeplink, subproperties)
  private(set) var ownedProperties: [String: MediaProperty] = [:]

  // Page cache keyed by "propertyId:pageId"
  private var pageCache: [String: MediaPropertyPage] = [:]

  // Section cache keyed by section ID
  private var sectionCache: [String: MediaPropertySection] = [:]

  private init() {
    properties =
      PersistentDataCache().loadCachedPropertyViewModels(
        network: NetworkStore.shared.selectedNetwork.rawValue,
        environment: NetworkStore.shared.environment.rawValue
      ) ?? []
  }

  func clear() {
    properties = []
    ownedProperties = [:]
    pageCache = [:]
    sectionCache = [:]
  }

  func fetchProperties(includePublic: Bool = true) async {
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
    } catch {
      print("Error loading properties \(error)")
    }
  }

  private func resolvePermissions(properties: [MediaProperty]) {
    properties.forEach {
      PermissionResolver.resolvePermissions($0, permissionStates: $0.permission_auth_state ?? [:])
    }
  }

  func fetchProperty(id: String) async {
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

  func getProperty(id: String) -> MediaProperty? {
    // Given the amount of Properties we are dealing with (sub 100), iterating like this should be
    // pretty fast and we don't need to bother with a hashmap for quick lookups by id
    return properties.first { $0.id == id } ?? ownedProperties[id]
  }

  // MARK: - Pages

  /// Fetches a page by ID, resolves its permissions, caches it, and returns it.
  fileprivate func fetchPage(
    property: MediaProperty,
    pageId: String
  ) async throws -> MediaPropertyPage {
    let cacheKey = "\(property.id):\(pageId)"
    if let cached = pageCache[cacheKey] {
      return cached
    }
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

  /// Fetches missing sections into cache with permissions already resolved.
  func fetchSections(property: MediaProperty, page: MediaPropertyPage) async {
    let sectionIds = page.sectionIds
    let missingSectionIds = sectionIds.filter { sectionCache[$0] == nil }
    guard !missingSectionIds.isEmpty else { return }

    do {
      let response: MediaPropertySectionsResponse = try await NetworkManager.shared.request(
        "mw/properties/\(property.id)/sections?resolve_subsections=true",
        body: missingSectionIds
      )
      PermissionResolver.resolvePermissions(
        response.contents,
        parentPermissions: page.resolvedPermissions,
        permissionStates: property.permission_auth_state ?? [:]
      )
      for section in response.contents {
        sectionCache[section.id] = section
      }
    } catch {
      print("Error fetching sections: \(error)")
    }
  }

  /// Returns cached sections for the given page (permissions already resolved).
  func sections(for page: MediaPropertyPage) -> [MediaPropertySection] {
    return page.sectionIds.compactMap { sectionCache[$0] }
  }
}

extension PropertyStore {
  /// Finds the first page we are authorized to view, following redirects as needed.
  /// Throws `PageRedirectError` for purchase gates or circular redirects.
  func getFirstAuthorizedPage(
    property: MediaProperty,
    pageId: String? = nil
  ) async throws -> MediaPropertyPage {
    var startPage: MediaPropertyPage? = nil
    if let pageId, !pageId.isEmpty {
      startPage = try await fetchPage(property: property, pageId: pageId)
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
          let redirectPage = try await fetchPage(
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

    let pageId = page.id ?? ""

    // Check for purchase gate on page
    if page.resolvedPagePermissions?.purchaseGate == true {
      throw PageRedirectError.purchaseRequired(propertyId: property.id, pageId: pageId)
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
    if redirectPageId == pageId || visitedPageIds.contains(redirectPageId) {
      throw PageRedirectError.circularRedirect
    }

    visitedPageIds.insert(pageId)
    let redirectPage = try await fetchPage(property: property, pageId: redirectPageId)
    return try await resolveAuthorizedPage(
      property: property, currentPage: redirectPage, visitedPageIds: &visitedPageIds)
  }
}
