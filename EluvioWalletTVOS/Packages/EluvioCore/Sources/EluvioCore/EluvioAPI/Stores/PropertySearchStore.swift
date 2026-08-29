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

      // The search endpoint reuses the same section/item ids across different
      // queries, so SwiftUI sees "equal" models and won't refresh the results.
      // Append the query to make ids unique per search.
      let suffix = querySuffix(for: searchRequest)
      if !suffix.isEmpty {
        for section in response.contents {
          section.id += suffix
          for item in section.content ?? [] {
            item.id = (item.id ?? "") + suffix
          }
        }
      }

      return response.contents
    } catch {
      throw FabricError.unexpectedResponse(error.localizedDescription)
    }
  }

  private func querySuffix(for request: SearchRequest) -> String {
    var parts: [String] = []
    if let term = request.search_term, !term.isEmpty {
      parts.append(term)
    }
    if let tags = request.tags, !tags.isEmpty {
      parts.append(tags.joined(separator: ","))
    }
    if let attributes = request.attributes {
      for key in attributes.keys.sorted() {
        parts.append("\(key)=\(attributes[key]?.joined(separator: ",") ?? "")")
      }
    }
    return parts.isEmpty ? "" : "#" + parts.joined(separator: "&")
  }

  public func getFilters(propertyId: String) async throws -> GetFiltersResponse {
    let response: GetFiltersResponse = try await NetworkManager.shared.request(
      "mw/properties/\(propertyId)/filters")
    return response
  }

  /// Flattens the filters endpoint into the primary chips a search screen shows,
  /// each carrying its own secondary chips.
  public func getPrimaryFilters(propertyId: String) async throws -> [PrimaryFilterViewModel] {
    let filterResult = try await getFilters(propertyId: propertyId)

    let attributes = filterResult.attributes ?? [:]
    let primaryFilterValue = filterResult.primary_filter ?? ""

    guard let primaryAttribute = attributes[primaryFilterValue] else { return [] }
    let options = filterResult.filter_options ?? []
    var newPrimaryFilters: [PrimaryFilterViewModel] = []

    let primaryTags = primaryAttribute.tags ?? []

    if !options.isEmpty {
      for option in options {
        let optionPrimaryFilterValue = option.primary_filter_value
        let image = option.primary_filter_image?.url ?? ""

        // Find secondary filters
        var secondary: [SecondaryFilterViewModel] = []
        let secondaryFilterOptions = option.secondary_filter_options ?? []

        for secondaryItem in secondaryFilterOptions {
          let secondaryImage = secondaryItem.secondary_filter_image_tv?.url ?? ""

          let secondaryValue = secondaryItem.secondary_filter_value

          let secondaryFilter = SecondaryFilterViewModel(
            id: secondaryValue,
            imageUrl: secondaryImage)
          secondary.append(secondaryFilter)
        }

        let secondaryAttribute = option.secondary_filter_attribute ?? ""
        if secondary.isEmpty {
          for secondaryTag in attributes[secondaryAttribute]?.tags ?? [] {
            secondary.append(SecondaryFilterViewModel(id: secondaryTag))
          }
        }

        let filterStyle = option.secondary_filter_style ?? ""
        let filter = PrimaryFilterViewModel(
          id: optionPrimaryFilterValue,
          imageUrl: image,
          secondaryFilters: secondary,
          attribute: primaryFilterValue,
          secondaryAttribute: secondaryAttribute,
          secondaryFilterStyle: PrimaryFilterViewModel.GetFilterStyle(style: filterStyle))

        newPrimaryFilters.append(filter)
      }
    } else if !primaryTags.isEmpty {
      for tag in primaryTags {
        let filter = PrimaryFilterViewModel(
          id: tag,
          imageUrl: "",
          secondaryFilters: [],
          attribute: primaryFilterValue,
          secondaryAttribute: "")

        newPrimaryFilters.append(filter)
      }
    }
    return newPrimaryFilters
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
