//
//  PersistentDataCache.swift
//  EluvioWalletTVOS
//
//  Enhanced caching system with disk persistence and auth state handling
//

import Foundation
import OSLog

/// Disk cache under `Caches/EluvioDataCache/v{cacheVersion}/`.
/// On init, all other files and folders inside `EluvioDataCache/` are deleted,
/// so bumping `cacheVersion` automatically invalidates old data.
@MainActor
public class PersistentDataCache: ObservableObject {

  private let logger = Logger(subsystem: "com.eluvio.wallet", category: "DataCache")
  private let cacheDirectory: URL

  public static let cacheVersion = 1

  private enum CacheKey: String, CaseIterable {
    case propertyViewModelsCache = "property_viewmodels_cache"
    case sectionsCache = "sections_cache"
    case discoverRowsCache = "discover_rows_cache"

    func filename(network: String, environment: String) -> String {
      let envLabel = environment.isEmpty ? "prod" : environment
      return "\(network)_\(envLabel)_\(self.rawValue).json"
    }
  }

  // Cache metadata
  private struct CacheMetadata: Codable {
    let timestamp: Date
    let network: String
  }

  // Cached data wrapper
  private struct CachedData<T: Codable>: Codable {
    let data: T
    let metadata: CacheMetadata

    var isExpired: Bool {
      // Date().timeIntervalSince(metadata.timestamp) > 300  // 5 minutes
      false  // Don't expire cache for now
    }
  }

  public init() {
    let documentsPath = FileManager.default.urls(
      for: .cachesDirectory,
      in: .userDomainMask
    ).first!
    let baseDirectory = documentsPath.appendingPathComponent("EluvioDataCache")
    cacheDirectory = baseDirectory.appendingPathComponent("v\(PersistentDataCache.cacheVersion)")

    do {
      try FileManager.default.createDirectory(
        at: cacheDirectory,
        withIntermediateDirectories: true)
    } catch {
      logger.error("Failed to create cache directory: \(error.localizedDescription)")
    }

    removeOldVersionCaches(baseDirectory: baseDirectory)
  }

  private func removeOldVersionCaches(baseDirectory: URL) {
    let currentFolder = "v\(PersistentDataCache.cacheVersion)"
    do {
      let contents = try FileManager.default.contentsOfDirectory(
        at: baseDirectory,
        includingPropertiesForKeys: nil)
      for fileURL in contents {
        if fileURL.lastPathComponent != currentFolder {
          try FileManager.default.removeItem(at: fileURL)
          logger.info("Removed old cache: \(fileURL.lastPathComponent)")
        }
      }
    } catch {
      logger.error("Failed to clean old cache: \(error.localizedDescription)")
    }
  }

  // MARK: - Generic Cache Operations

  private func cacheFilePath(for key: CacheKey, network: String, environment: String) -> URL {
    return cacheDirectory.appendingPathComponent(
      key.filename(network: network, environment: environment))
  }

  private func saveToCache<T: Codable>(
    _ data: T,
    key: CacheKey,
    network: String,
    environment: String,
  ) {
    let metadata = CacheMetadata(
      timestamp: Date(),
      network: network)
    let cachedData = CachedData(data: data, metadata: metadata)

    do {
      let jsonData = try JSONEncoder().encode(cachedData)
      let filePath = cacheFilePath(for: key, network: network, environment: environment)
      try jsonData.write(to: filePath)
      logger.info(
        "Cached \(key.rawValue) for network \(network), env: \(environment)")
    } catch {
      logger.error("Failed to cache \(key.rawValue): \(error.localizedDescription)")
    }
  }

  private func loadFromCache<T: Codable>(
    _ type: T.Type,
    key: CacheKey,
    network: String,
    environment: String
  ) -> T? {
    let filePath = cacheFilePath(for: key, network: network, environment: environment)

    guard FileManager.default.fileExists(atPath: filePath.path) else {
      return nil
    }

    do {
      let jsonData = try Data(contentsOf: filePath)
      let cachedData = try JSONDecoder().decode(CachedData<T>.self, from: jsonData)

      guard !cachedData.isExpired, cachedData.metadata.network == network
      else {
        logger.info("Cache expired or network mismatch for \(key.rawValue)")
        return nil
      }

      logger.info(
        "Loaded \(key.rawValue) from cache for network \(network), env: \(environment)"
      )
      return cachedData.data

    } catch {
      logger.error("Failed to load \(key.rawValue) from cache: \(error.localizedDescription)")
      return nil
    }
  }

  // MARK: - Property ViewModels Cache

  public func cachePropertyViewModels(
    _ propertyViewModels: [MediaProperty],
    network: String,
    environment: String,
  ) {
    let key: CacheKey = .propertyViewModelsCache
    saveToCache(
      propertyViewModels, key: key, network: network, environment: environment
    )
    logger.info("Cached \(propertyViewModels.count) PropertyViewModels with resolved URLs")
  }

  public func loadCachedPropertyViewModels(
    network: String,
    environment: String,
  ) -> [MediaProperty]? {
    let key: CacheKey = .propertyViewModelsCache
    let viewModels = loadFromCache(
      [MediaProperty].self, key: key, network: network, environment: environment)

    if let viewModels = viewModels {
      logger.info("Loaded \(viewModels.count) PropertyViewModels from cache with resolved URLs")
    }

    return viewModels
  }

  // MARK: - Sections Cache

  public func cacheSections(
    _ sections: [String: MediaPropertySection],
    network: String,
    environment: String,
  ) {
    saveToCache(sections, key: .sectionsCache, network: network, environment: environment)
    logger.info("Cached \(sections.count) sections")
  }

  public func loadCachedSections(
    network: String,
    environment: String,
  ) -> [String: MediaPropertySection]? {
    let sections = loadFromCache(
      [String: MediaPropertySection].self,
      key: .sectionsCache,
      network: network,
      environment: environment)

    if let sections = sections {
      logger.info("Loaded \(sections.count) sections from cache")
    }

    return sections
  }

  // MARK: - Discover Rows Cache

  public func cacheDiscoverRows(
    _ rows: [DiscoverStore.Row],
    network: String,
    environment: String,
  ) {
    saveToCache(rows, key: .discoverRowsCache, network: network, environment: environment)
    logger.info("Cached \(rows.count) discover rows")
  }

  public func loadCachedDiscoverRows(
    network: String,
    environment: String,
  ) -> [DiscoverStore.Row]? {
    let rows = loadFromCache(
      [DiscoverStore.Row].self,
      key: .discoverRowsCache,
      network: network,
      environment: environment)

    if let rows = rows {
      logger.info("Loaded \(rows.count) discover rows from cache")
    }

    return rows
  }

  // MARK: - Cache Management

  public func clearCache(network: String? = nil) {
    do {
      let contents = try FileManager.default.contentsOfDirectory(
        at: cacheDirectory,
        includingPropertiesForKeys: nil)
      for fileURL in contents {
        if let network = network {
          if fileURL.lastPathComponent.hasPrefix(network) {
            try FileManager.default.removeItem(at: fileURL)
          }
        } else {
          try FileManager.default.removeItem(at: fileURL)
        }
      }
    } catch {
      logger.error("Failed to clear cache: \(error.localizedDescription)")
    }
  }

  public func getCacheSize() -> Int64 {
    var size: Int64 = 0
    do {
      let contents = try FileManager.default.contentsOfDirectory(
        at: cacheDirectory,
        includingPropertiesForKeys: [.fileSizeKey])
      for fileURL in contents {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let fileSize = fileAttributes[.size] as? Int64 {
          size += fileSize
        }
      }
    } catch {
      logger.error("Failed to calculate cache size: \(error.localizedDescription)")
    }
    return size
  }
}
