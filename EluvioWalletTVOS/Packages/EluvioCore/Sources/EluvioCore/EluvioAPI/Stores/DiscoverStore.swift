import Observation

/// The categorized rows of Properties that make up the Discover page.
///
/// The rows only hold Property ids - the Properties themselves are handed to `PropertyStore`,
/// which is where every other screen looks them up.
@MainActor
@Observable
public class DiscoverStore {
  public static let shared = DiscoverStore()

  /// A row as it comes off the server (and out of the cache).
  public struct Row: Codable, Hashable {
    public var title: String
    public var featured: Bool
    public var propertyIds: [String]
  }

  /// A row resolved against `PropertyStore`, ready to render.
  public struct PropertyRow: Identifiable {
    public let id: String
    public let title: String
    public let properties: [MediaProperty]
  }

  public private(set) var rows: [Row] = []

  private init() {
    rows =
      PersistentDataCache().loadCachedDiscoverRows(
        network: NetworkStore.shared.selectedNetwork.rawValue,
        environment: NetworkStore.shared.environment.rawValue
      ) ?? []
  }

  public func clear() {
    rows = []
  }

  /// Rows with their Properties filled in from `PropertyStore`.
  ///
  /// A row can reference a Property we don't have, so those references are skipped, and a
  /// row that ends up empty is dropped. If nothing survives - no rows yet, `mw/discover`
  /// failed, or it only named Properties we never got - everything `PropertyStore` knows
  /// about is rendered as a single untitled row, so the page is never blank.
  public var propertyRows: [PropertyRow] {
    let resolved = rows.enumerated().compactMap { index, row -> PropertyRow? in
      let properties = row.propertyIds.compactMap { PropertyStore.shared.getProperty(id: $0) }
      if properties.isEmpty { return nil }
      return PropertyRow(id: "\(index):\(row.title)", title: row.title, properties: properties)
    }
    if !resolved.isEmpty {
      return resolved
    }
    let all = PropertyStore.shared.properties
    return all.isEmpty ? [] : [PropertyRow(id: "all", title: "", properties: all)]
  }

  /// Loads the Discover page, falling back to the flat `mw/properties` list.
  public func load() async {
    let fetched = await fetchDiscoverRows()
    // Even when cached rows are still renderable, a failed fetch has to fall through: it's
    // the only call that would have refreshed the Properties those rows point at.
    if !fetched || propertyRows.isEmpty {
      print("Discover: no usable rows from mw/discover, falling back to mw/properties")
      await PropertyStore.shared.fetchProperties()
    }
  }

  /// Fetches the rows and hands their Properties to `PropertyStore`. Returns whether the
  /// rows were replaced - on failure the cached ones are left alone.
  ///
  /// Deliberately a single attempt, unlike `fetchProperties`: `mw/discover` is new enough
  /// that it may not exist in the environment at all, and retrying with backoff would just
  /// delay the fallback (which retries on its own) by several seconds on every launch.
  private func fetchDiscoverRows() async -> Bool {
    do {
      let response: DiscoverResponse = try await NetworkManager.shared.request("mw/discover")

      // Properties are fetched (and cached) elsewhere too, so merge into the list instead
      // of replacing it.
      PropertyStore.shared.merge(properties: Array((response.properties ?? [:]).values))

      rows = (response.contents ?? [])
        .filter { $0.type == DiscoverRowDto.typeProperties }
        .map { dto in
          // Featured rows are drawn without a title.
          let featured = dto.featured == true
          return Row(
            title: featured ? "" : (dto.title ?? ""),
            featured: featured,
            propertyIds: dto.property_ids ?? [])
        }
      PersistentDataCache().cacheDiscoverRows(
        rows,
        network: NetworkStore.shared.selectedNetwork.rawValue,
        environment: NetworkStore.shared.environment.rawValue
      )
      print("Discover: loaded \(rows.count) rows from mw/discover")
      return true
    } catch {
      print("Error loading discover rows: \(error)")
      return false
    }
  }
}

struct DiscoverResponse: Codable {
  var contents: [DiscoverRowDto]?
  var properties: [String: MediaProperty]?
}

struct DiscoverRowDto: Codable {
  /// Currently the only supported value is `typeProperties`.
  static let typeProperties = "properties"

  var type: String?
  var title: String?
  var featured: Bool?
  var property_ids: [String]?
}
