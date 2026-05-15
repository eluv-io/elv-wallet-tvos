//
//  CacheManager.swift
//  EluvioWalletTVOS
//
//  Cache management utilities for the Eluvio app
//

import Foundation
import OSLog

@MainActor
class CacheManager: ObservableObject {

  private let logger = Logger(subsystem: "com.eluvio.wallet", category: "CacheManager")
  private let persistentCache = PersistentDataCache()

  @Published var cacheSize: Int64 = 0
  @Published var isClearing: Bool = false

  init() {
    updateCacheSize()
  }

  func updateCacheSize() {
    cacheSize = persistentCache.getCacheSize()
  }

  func clearCache(network: String? = nil) async {
    isClearing = true
    defer { isClearing = false }

    persistentCache.clearCache(network: network)
    updateCacheSize()
    logger.info("Cache cleared successfully")
  }

  func clearCacheOnAuthChange(
    previousAuthState: Bool?, currentAuthState: Bool, network: String
  ) {
    if let prevAuth = previousAuthState, prevAuth != currentAuthState {
      Task {
        await clearCache(network: network)
        logger.info("Cache cleared due to auth state change")
      }
    }
  }

  var formattedCacheSize: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: cacheSize)
  }
}
