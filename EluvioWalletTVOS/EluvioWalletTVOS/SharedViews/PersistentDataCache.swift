//
//  PersistentDataCache.swift
//  EluvioWalletTVOS
//
//  Enhanced caching system with disk persistence and auth state handling
//

import Foundation
import SwiftyJSON
import OSLog

@MainActor
class PersistentDataCache: ObservableObject {
    
    private let logger = Logger(subsystem: "com.eluvio.wallet", category: "DataCache")
    private let cacheDirectory: URL
    private let maxCacheAge: TimeInterval = 300 // 5 minutes
    
    // Cache keys for different auth states
    private enum CacheKey: String, CaseIterable {
        case propertiesAuth = "properties_auth"
        case propertiesNoAuth = "properties_noauth"
        case propertyViewModelsAuth = "property_viewmodels_auth"  // New: cache ViewModels
        case propertyViewModelsNoAuth = "property_viewmodels_noauth"  // New: cache ViewModels
        case sections = "sections"
        case mediaItems = "media_items"
        
        func filename(network: String) -> String {
            return "\(network)_\(self.rawValue).json"
        }
    }
    
    // Cache metadata
    private struct CacheMetadata: Codable {
        let timestamp: Date
        let network: String
        let authState: Bool
        let version: String = "1.0"
    }
    
    // Cached data wrapper
    private struct CachedData<T: Codable>: Codable {
        let data: T
        let metadata: CacheMetadata
        
        var isExpired: Bool {
            Date().timeIntervalSince(metadata.timestamp) > 300 // 5 minutes
        }
    }
    
    init() {
        // Create cache directory
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, 
                                                   in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("EluvioDataCache")
        
        do {
            try FileManager.default.createDirectory(at: cacheDirectory, 
                                                  withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create cache directory: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Generic Cache Operations
    
    private func cacheFilePath(for key: CacheKey, network: String) -> URL {
        return cacheDirectory.appendingPathComponent(key.filename(network: network))
    }
    
    private func saveToCache<T: Codable>(_ data: T, 
                                       key: CacheKey, 
                                       network: String, 
                                       authState: Bool) {
        let metadata = CacheMetadata(timestamp: Date(), 
                                   network: network, 
                                   authState: authState)
        let cachedData = CachedData(data: data, metadata: metadata)
        
        do {
            let jsonData = try JSONEncoder().encode(cachedData)
            let filePath = cacheFilePath(for: key, network: network)
            try jsonData.write(to: filePath)
            logger.info("Cached \(key.rawValue) for network \(network), auth: \(authState)")
        } catch {
            logger.error("Failed to cache \(key.rawValue): \(error.localizedDescription)")
        }
    }
    
    private func loadFromCache<T: Codable>(_ type: T.Type, 
                                        key: CacheKey, 
                                        network: String, 
                                        authState: Bool) -> T? {
        let filePath = cacheFilePath(for: key, network: network)
        
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return nil
        }
        
        do {
            let jsonData = try Data(contentsOf: filePath)
            let cachedData = try JSONDecoder().decode(CachedData<T>.self, from: jsonData)
            
            // Check if cache is valid
            guard !cachedData.isExpired,
                  cachedData.metadata.network == network,
                  cachedData.metadata.authState == authState else {
                logger.info("Cache expired or auth state mismatch for \(key.rawValue)")
                return nil
            }
            
            logger.info("Loaded \(key.rawValue) from cache for network \(network), auth: \(authState)")
            return cachedData.data
            
        } catch {
            logger.error("Failed to load \(key.rawValue) from cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Properties Cache
    
    func cacheProperties(_ properties: [MediaProperty], 
                        network: String, 
                        authState: Bool) {
        let key: CacheKey = authState ? .propertiesAuth : .propertiesNoAuth
        saveToCache(properties, key: key, network: network, authState: authState)
    }
    
    func loadCachedProperties(network: String, 
                             authState: Bool) -> [MediaProperty]? {
        let key: CacheKey = authState ? .propertiesAuth : .propertiesNoAuth
        return loadFromCache([MediaProperty].self, key: key, network: network, authState: authState)
    }
    
    // MARK: - Property ViewModels Cache (NEW - with resolved URLs)
    
    func cachePropertyViewModels(_ propertyViewModels: [MediaPropertyViewModel], 
                                network: String, 
                                authState: Bool) {
        let key: CacheKey = authState ? .propertyViewModelsAuth : .propertyViewModelsNoAuth
        saveToCache(propertyViewModels, key: key, network: network, authState: authState)
        logger.info("Cached \(propertyViewModels.count) PropertyViewModels with resolved URLs")
    }
    
    func loadCachedPropertyViewModels(network: String, 
                                     authState: Bool) -> [MediaPropertyViewModel]? {
        let key: CacheKey = authState ? .propertyViewModelsAuth : .propertyViewModelsNoAuth
        let viewModels = loadFromCache([MediaPropertyViewModel].self, key: key, network: network, authState: authState)
        
        if let viewModels = viewModels {
            logger.info("Loaded \(viewModels.count) PropertyViewModels from cache with resolved URLs")
        }
        
        return viewModels
    }
    
    // MARK: - Sections Cache
    
    func cacheSections(_ sections: [MediaPropertySection], 
                      propertyId: String, 
                      network: String, 
                      authState: Bool) {
        let cacheKey = "\(propertyId)_sections"
        let metadata = CacheMetadata(timestamp: Date(), 
                                   network: network, 
                                   authState: authState)
        let cachedData = CachedData(data: sections, metadata: metadata)
        
        do {
            let jsonData = try JSONEncoder().encode(cachedData)
            let filePath = cacheDirectory.appendingPathComponent("\(cacheKey).json")
            try jsonData.write(to: filePath)
            logger.info("Cached sections for property \(propertyId)")
        } catch {
            logger.error("Failed to cache sections: \(error.localizedDescription)")
        }
    }
    
    func loadCachedSections(propertyId: String, 
                           network: String, 
                           authState: Bool) -> [MediaPropertySection]? {
        let cacheKey = "\(propertyId)_sections"
        let filePath = cacheDirectory.appendingPathComponent("\(cacheKey).json")
        
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return nil
        }
        
        do {
            let jsonData = try Data(contentsOf: filePath)
            let cachedData = try JSONDecoder().decode(CachedData<[MediaPropertySection]>.self, from: jsonData)
            
            guard !cachedData.isExpired,
                  cachedData.metadata.network == network,
                  cachedData.metadata.authState == authState else {
                return nil
            }
            
            logger.info("Loaded cached sections for property \(propertyId)")
            return cachedData.data
            
        } catch {
            logger.error("Failed to load cached sections: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache(network: String? = nil) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory,
                                                                     includingPropertiesForKeys: nil)
            for fileURL in contents {
                if let network = network {
                    if fileURL.lastPathComponent.hasPrefix(network) {
                        try FileManager.default.removeItem(at: fileURL)
                        logger.info("Cleared cache file: \(fileURL.lastPathComponent)")
                    }
                } else {
                    try FileManager.default.removeItem(at: fileURL)
                    logger.info("Cleared cache file: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            logger.error("Failed to clear cache: \(error.localizedDescription)")
        }
    }
    
    func getCacheSize() -> Int64 {
        var size: Int64 = 0
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory,
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