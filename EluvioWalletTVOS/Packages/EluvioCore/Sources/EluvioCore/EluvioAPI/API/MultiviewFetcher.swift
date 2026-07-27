public class MultiviewFetcher {
  public static let shared = MultiviewFetcher()
  private init() {}

  public func getPropertyMultiview(propertyId: String) async -> [MediaPropertySectionMediaItem] {
    do {
      let response: PagedContent<MediaPropertySectionMediaItem> = try await NetworkManager.shared
        .request("mw/properties/\(propertyId)/sidebar/live", method: .post)
      return response.contents
    } catch {
      debugPrint("Failed to fetch multiview options, returning empty array.")
      return []
    }
  }
}
