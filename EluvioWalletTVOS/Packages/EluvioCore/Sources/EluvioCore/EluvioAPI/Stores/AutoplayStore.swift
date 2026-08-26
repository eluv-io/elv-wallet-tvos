import Observation

/// Answers "the user just finished this item — what plays next?".
///
/// Backed by `POST /mw/properties/:propertyId/autoplay/next` (qluvio/elv-master#1417), which
/// returns the upcoming items of a sequential run in order, and an empty `contents` when the
/// current item is not part of one. The server owns the ordering and the eligibility rules but
/// says nothing about entitlement: the run is handed over "regardless of permission status", so
/// deciding which of those items to actually surface is this client's job — `firstPresentable`.
@MainActor
public class AutoplayStore {
  public static let shared = AutoplayStore()

  private init() {}

  /// The next item to play after `mediaId`, or nil when there is nothing worth offering.
  ///
  /// - Parameters:
  ///   - sectionId: the section being viewed, which resolves groups configured as
  ///     `<Current Section>`. Accepts an id or a slug.
  ///   - mediaListId: the media list being viewed, if the user came in through one. Id only.
  public func nextItem(
    propertyId: String,
    mediaId: String,
    sectionId: String = "",
    mediaListId: String = ""
  ) async -> MediaPropertySectionMediaItem? {
    let candidates = await fetchCandidates(
      propertyId: propertyId,
      mediaId: mediaId,
      sectionId: sectionId,
      mediaListId: mediaListId)
    return firstPresentable(candidates)
  }

  /// The first candidate worth putting in front of the viewer.
  ///
  /// Hidden items are content they are not meant to see, and disabled ones can be neither
  /// played nor bought, so both are passed over. An item behind a purchase gate is kept: the
  /// player has a gate to show for it, and the run should not silently skip a paid episode.
  private func firstPresentable(_ candidates: [MediaPropertySectionMediaItem])
    -> MediaPropertySectionMediaItem?
  {
    candidates.first { item in
      item.resolvedPermissions?.hide != true && item.resolvedPermissions?.disable != true
    }
  }

  /// Nothing to play arrives as a `200` with empty `contents` rather than an error, so an
  /// empty response and a failed one both come back as no candidates.
  private func fetchCandidates(
    propertyId: String,
    mediaId: String,
    sectionId: String,
    mediaListId: String
  ) async -> [MediaPropertySectionMediaItem] {
    do {
      let response: MediaPropertyItemsResponse = try await NetworkManager.shared.request(
        "mw/properties/\(propertyId)/autoplay/next",
        method: .post,
        body: AutoplayRequest(
          media_id: mediaId,
          section_id: sectionId.nilIfEmpty(),
          media_list_id: mediaListId.nilIfEmpty()))

      debugPrint("Autoplay returned \(response.contents.count) candidates after \(mediaId)")

      // Returned items carry their permissions unresolved, and firstPresentable reads them
      if let property = PropertyStore.shared.getProperty(id: propertyId) {
        PermissionResolver.resolvePermissions(
          response.contents,
          parentPermissions: property.resolvedPermissions,
          permissionStates: property.permission_auth_state ?? [:])
      }
      return response.contents
    } catch {
      debugPrint("AutoplayStore.nextItem failed:", error.localizedDescription)
      return []
    }
  }
}

private struct AutoplayRequest: Encodable {
  let media_id: String
  let section_id: String?
  let media_list_id: String?
}
