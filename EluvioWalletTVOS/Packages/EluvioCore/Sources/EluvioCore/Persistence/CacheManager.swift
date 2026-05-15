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

  public func clearCacheOnAuthChange(
    previousAuthState: Bool?, currentAuthState: Bool, network: String
  ) {
    if let prevAuth = previousAuthState, prevAuth != currentAuthState {
      Task {
        await clearCache(network: network)
        logger.info("Cache cleared due to auth state change")
      }
    }
  }

  public var formattedCacheSize: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: cacheSize)
  }
}
