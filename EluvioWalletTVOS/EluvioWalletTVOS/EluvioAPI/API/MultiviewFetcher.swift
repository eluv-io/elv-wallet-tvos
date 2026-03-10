class MultiviewFetcher {
  static let shared = MultiviewFetcher()
  private init() {}

  func getPropertyMultiview(propertyId: String) async -> [MediaPropertySectionMediaItem] {
    do {
      let response: PagedContent<MediaPropertySectionMediaItem> = try await NetworkManager.shared
        .request("mw/properties/\(propertyId)/sidebar/live")
      return response.contents
    } catch {
      debugPrint("Failed to fetch multiview options, returning empty array.")
      return []
    }
  }
}
