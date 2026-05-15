class PropertySearchStore {
  static let shared = PropertySearchStore()

  private init() {}

  func search(property: MediaProperty, searchRequest: SearchRequest) async throws
    -> [MediaPropertySection]
  {
    do {
      let response: PagedContent<MediaPropertySection> = try await NetworkManager.shared.request(
        "mw/properties/\(property.id)/search?limit=30", method: .post, body: searchRequest)

      PermissionResolver.resolvePermissions(
        response.contents,
        parentPermissions: property.resolvedSearchPermissions,
        permissionStates: property.permission_auth_state ?? [:]
      )

      return response.contents
    } catch {
      throw FabricError.unexpectedResponse(error.localizedDescription)
    }
  }

  func getFilters(propertyId: String) async throws -> GetFiltersResponse {
    let response: GetFiltersResponse = try await NetworkManager.shared.request(
      "mw/properties/\(propertyId)/filters")
    return response
  }
}

struct SearchRequest: Codable {
  var search_term: String? = nil
  var tags: [String]? = nil
  var attributes: [String: [String]]? = nil
}

struct GetFiltersResponse: Codable {
  // Property top-level tags and attributes.
  let tags: [String]?
  let attributes: [String: SearchFilterAttribute]?

  let primary_filter: String?
  let secondary_filter: String?
  var filter_options: [PrimaryFilterOptions]?
}

struct SearchFilterAttribute: Codable {
  let id: String
  let title: String?
  let tags: [String]?
}

struct PrimaryFilterOptions: Codable {
  let primary_filter_value: String
  let primary_filter_image: ImageLink?

  let secondary_filter_attribute: String?
  let secondary_filter_options: [SecondaryFilterOptions]?

  let secondary_filter_style: String?
}

struct SecondaryFilterOptions: Codable {
  let secondary_filter_image_tv: ImageLink?
  let secondary_filter_value: String
}
