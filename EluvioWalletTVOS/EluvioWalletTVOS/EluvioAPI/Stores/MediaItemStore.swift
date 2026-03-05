import Observation

@MainActor
@Observable
class MediaItemStore {
  static let shared = MediaItemStore()

  private var cache: [String: MediaPropertySectionMediaItem] = [:]

  private init() {}

  func observeMediaItems(ids: [String]) -> [MediaPropertySectionMediaItem] {
    ids.compactMap { cache[$0] }
  }

  func cache(items: [MediaPropertySectionMediaItem]) {
    for item in items {
      cache[item.id] = item
    }
  }

  /// Fetches media items. Unauthorized items with "hide" permission behavior will be discarded and not cached.
  func fetchMediaItems(
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
