import Foundation

/// Holds pending deep-link targets, observed by DiscoverView. The App receives
/// incoming URLs (Universal Links + custom scheme) and dumps them here;
/// DiscoverView picks them up once its property list is ready and pushes the
/// matching view onto the nav stack.
@MainActor
@Observable
final class DeepLinkRouter {
  static let shared = DeepLinkRouter()
  private init() {}

  /// Property ID the user wants to land on. Cleared once consumed.
  var pendingPropertyId: String?

  /// Parses an incoming URL. Returns true if the URL was a recognized link.
  ///
  /// Expected shape: `https://wallet.contentfabric.io/iq__<hash>` — the first
  /// path component beginning with `iq__` is the property ID.
  @discardableResult
  func handle(url: URL) -> Bool {
    let first = url.pathComponents.first(where: { $0.hasPrefix("iq__") })
    guard let propertyId = first else { return false }
    pendingPropertyId = propertyId
    return true
  }
}
