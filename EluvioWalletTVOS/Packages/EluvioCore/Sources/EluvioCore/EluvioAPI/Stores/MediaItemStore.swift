import Observation

@MainActor
@Observable
public class MediaItemStore {
  public static let shared = MediaItemStore()

  private var cache: [String: MediaPropertySectionMediaItem] = [:]

  private init() {}

  public func observeMediaItems(ids: [String]) -> [MediaPropertySectionMediaItem] {
    ids.compactMap { cache[$0] }
  }

  public func cache(items: [MediaPropertySectionMediaItem]) {
    for item in items {
      cache[item.id] = item
    }
  }

  public func clear() {
    cache = [:]
  }

  /// Fetches media items. Unauthorized items with "hide" permission behavior will be discarded and not cached.
  public func fetchMediaItems(
    propertyId: String,
    ids: [String],
    parentPermissions: ResolvedPermission?,
    permissionStates: PermissionStateMap
  ) async {
    guard !ids.isEmpty else { return }
    do {
      let response: MediaPropertyItemsResponse = try await NetworkManager.shared.request(
        "mw/properties/\(propertyId)/media_items", method: .post, body: ids)
      PermissionResolver.resolvePermissions(
        response.contents,
        parentPermissions: parentPermissions,
        permissionStates: permissionStates
      )
      let visible = response.contents.filter { $0.resolvedPermissions?.hide != true }
      cache(items: visible)
    } catch {
      debugPrint("MediaItemStore.fetchMediaItems failed:", error.localizedDescription)
    }
  }
}
