public class PropertySearchStore {
  public static let shared = PropertySearchStore()

  private init() {}

  public func search(property: MediaProperty, searchRequest: SearchRequest) async throws
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

  public func getFilters(propertyId: String) async throws -> GetFiltersResponse {
    let response: GetFiltersResponse = try await NetworkManager.shared.request(
      "mw/properties/\(propertyId)/filters")
    return response
  }
}

public struct SearchRequest: Codable {
  public var search_term: String? = nil
  public var tags: [String]? = nil
  public var attributes: [String: [String]]? = nil

  public init(
    search_term: String? = nil,
    tags: [String]? = nil,
    attributes: [String: [String]]? = nil
  ) {
    self.search_term = search_term
    self.tags = tags
    self.attributes = attributes
  }
}

public struct GetFiltersResponse: Codable {
  // Property top-level tags and attributes.
  public let tags: [String]?
  public let attributes: [String: SearchFilterAttribute]?

  public let primary_filter: String?
  public let secondary_filter: String?
  public var filter_options: [PrimaryFilterOptions]?
}

public struct SearchFilterAttribute: Codable {
  public let id: String
  public let title: String?
  public let tags: [String]?
}

public struct PrimaryFilterOptions: Codable {
  public let primary_filter_value: String
  public let primary_filter_image: ImageLink?

  public let secondary_filter_attribute: String?
  public let secondary_filter_options: [SecondaryFilterOptions]?

  public let secondary_filter_style: String?
}

public struct SecondaryFilterOptions: Codable {
  public let secondary_filter_image_tv: ImageLink?
  public let secondary_filter_value: String
}
