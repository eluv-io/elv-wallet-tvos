//
//  CacheManager.swift
//  EluvioWalletTVOS
//
//  Cache management utilities for the Eluvio app
//

import Foundation
import OSLog

@MainActor
public class CacheManager: ObservableObject {

  private let logger = Logger(subsystem: "com.eluvio.wallet", category: "CacheManager")
  private let persistentCache = PersistentDataCache()

  @Published public var cacheSize: Int64 = 0
  @Published public var isClearing: Bool = false

  public init() {
    updateCacheSize()
  }

  public func updateCacheSize() {
    cacheSize = persistentCache.getCacheSize()
  }

  public func clearCache(network: String? = nil) async {
    isClearing = true
    defer { isClearing = false }

    persistentCache.clearCache(network: network)
    updateCacheSize()
    logger.info("Cache cleared successfully")
  }

  /// Drops every cache holding account-specific data. Call on any sign-in or sign-out.
  ///
  /// Resolved permissions are baked into the persisted section cache, so carrying it
  /// across accounts shows one account's entitlements to another. Clearing only the
  /// disk cache is not enough: `PropertyStore` reads it into memory once at init, and
  /// `MediaItemStore` holds resolved items too. `URLCache` also has to go — the
  /// property response carries `permission_auth_state` and the server sends it with no
  /// cache headers, so it would otherwise be replayed for the new account.
  ///
  /// Unconditional by design. This runs on genuine sign-in/sign-out only — never on a
  /// token refresh — and a refetch always follows, so there is nothing to be gained by
  /// trying to detect whether the identity "really" changed.
  public func clearAccountScopedCaches() async {
    await clearCache()
    PropertyStore.shared.clear()
    DiscoverStore.shared.clear()
    MediaItemStore.shared.clear()
    URLCache.shared.removeAllCachedResponses()
    logger.info("Account-scoped caches cleared")
  }

  public var formattedCacheSize: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: cacheSize)
  }
}
