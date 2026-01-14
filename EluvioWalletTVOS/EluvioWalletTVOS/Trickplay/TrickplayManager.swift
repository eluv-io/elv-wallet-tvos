//
//  TrickplayManager.swift
//  EluvioWalletTVOS
//
//  Manages trickplay thumbnail loading and URL construction
//

import Foundation
import SwiftyJSON
import UIKit

/// Manages trickplay thumbnails for video playback
class TrickplayManager {

    private var thumbnailSprite: ThumbnailSprite?
    private var thumbnailLoader: ThumbnailLoader
    private var isLoading = false

    init() {
        self.thumbnailLoader = ThumbnailLoader()
    }

    /// Set the authorization token for authenticated requests
    func setAuthToken(_ token: String?) {
        thumbnailLoader.setAuthToken(token)
    }

    /// Extract thumbnails WebVTT URL from playout options
    /// - Parameters:
    ///   - optionsJson: The playout options JSON
    ///   - basePlayoutUrl: The base playout URL for the video
    /// - Returns: The full WebVTT URL, or nil if not available
    static func extractThumbnailsWebVttUrl(optionsJson: JSON?, basePlayoutUrl: String) -> String? {
        guard let options = optionsJson else { return nil }

        // Try different DRM options for thumbnails_webvtt_uri
        let drmTypes = ["hls-clear", "hls-aes128", "hls-fairplay", "hls-sample-aes"]

        for drm in drmTypes {
            if let thumbnailsUri = options[drm]["properties"]["thumbnails_webvtt_uri"].string,
               !thumbnailsUri.isEmpty {
                // Construct full URL from base playout URL and thumbnails URI
                return constructThumbnailsUrl(basePlayoutUrl: basePlayoutUrl, thumbnailsUri: thumbnailsUri)
            }
        }

        return nil
    }

    /// Construct full thumbnails URL from base playout URL and thumbnails URI
    private static func constructThumbnailsUrl(basePlayoutUrl: String, thumbnailsUri: String) -> String {
        // The thumbnailsUri format is typically: "offering_name/rest/of/path"
        // We need to replace the offering part in the base URL

        // Extract base URL up to the offering
        // Base URL format: https://host/q/hash/rep/playout/offering/uri
        guard let baseUrl = URL(string: basePlayoutUrl) else {
            return thumbnailsUri
        }

        // Find the playout path and replace offering with thumbnails path
        let pathComponents = baseUrl.pathComponents

        // Look for "playout" in path components
        if let playoutIndex = pathComponents.firstIndex(of: "playout"),
           playoutIndex + 1 < pathComponents.count {
            // Get path up to and including "playout"
            var newPathComponents = Array(pathComponents[0...playoutIndex])

            // Append the thumbnails URI (which includes its own offering/path)
            let thumbnailParts = thumbnailsUri.split(separator: "/").map(String.init)
            newPathComponents.append(contentsOf: thumbnailParts)

            // Reconstruct URL
            var components = URLComponents()
            components.scheme = baseUrl.scheme
            components.host = baseUrl.host
            components.path = newPathComponents.joined(separator: "/")

            // Preserve authorization query parameter if present
            if let query = baseUrl.query {
                components.query = query
            }

            return components.url?.absoluteString ?? thumbnailsUri
        }

        return thumbnailsUri
    }

    /// Load thumbnails from WebVTT URL
    /// - Parameter webVttUrl: The WebVTT URL
    func loadThumbnails(webVttUrl: String) async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            debugPrint("TrickplayManager: Loading thumbnails from \(webVttUrl)")
            thumbnailSprite = try await thumbnailLoader.loadThumbnails(webVttUrl: webVttUrl)
            debugPrint("TrickplayManager: Loaded \(thumbnailSprite?.cues.count ?? 0) thumbnail cues")
        } catch {
            debugPrint("TrickplayManager: Failed to load thumbnails: \(error)")
            thumbnailSprite = nil
        }
    }

    /// Get thumbnail for a specific position
    /// - Parameter positionMs: Position in milliseconds
    /// - Returns: The thumbnail image, or nil if not available
    func getThumbnail(forPosition positionMs: Int64) -> UIImage? {
        return thumbnailSprite?.getThumbnail(forPosition: positionMs)
    }

    /// Check if thumbnails are available
    var hasThumbnails: Bool {
        guard let sprite = thumbnailSprite else { return false }
        return !sprite.cues.isEmpty && sprite.hasBitmaps
    }

    /// Get the aspect ratio of thumbnails
    var thumbnailAspectRatio: CGFloat {
        return thumbnailSprite?.aspectRatio ?? (16.0 / 9.0)
    }

    /// Clear loaded thumbnails
    func clear() {
        thumbnailSprite = nil
    }
}
