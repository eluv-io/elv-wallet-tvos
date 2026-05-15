import SDWebImage

public enum WebImageSetup {
  /// Configures `SDWebImage`'s shared manager + downloader with the cache-key
  /// and URL-rewrite rules every Eluvio app needs. Call once at app launch.
  ///
  /// - Strips `authorization` query params from the cache key so the same
  ///   image hits cache regardless of token changes.
  /// - Normalizes `*.contentfabric.io` hosts so different fabric nodes share
  ///   cache entries.
  /// - Replaces the fabric-url placeholder host with the real fabric base URL.
  public static func configure() {
    SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter { url in
      guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return url.absoluteString
      }
      components.queryItems = components.queryItems?.filter { $0.name != "authorization" }
      if components.queryItems?.isEmpty == true {
        components.queryItems = nil
      }
      if let host = components.host, host.hasSuffix(".contentfabric.io") {
        components.host = "contentfabric.io"
      }
      return components.url?.absoluteString ?? url.absoluteString
    }

    SDWebImageDownloader.shared.requestModifier = SDWebImageDownloaderRequestModifier { request in
      var modified = request
      modified.url = request.url!.replaceFabricUrlPlaceholder()
      return modified
    }
  }
}
