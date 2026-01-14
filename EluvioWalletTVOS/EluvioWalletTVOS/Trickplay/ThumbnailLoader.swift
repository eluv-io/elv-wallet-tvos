//
//  ThumbnailLoader.swift
//  EluvioWalletTVOS
//
//  Loads and parses WebVTT thumbnail sprite sheets
//

import Foundation
import UIKit

/// Error types for thumbnail loading
enum ThumbnailLoaderError: Error, LocalizedError {
    case invalidUrl
    case networkError(String)
    case parseError(String)
    case imageLoadError(String)

    var errorDescription: String? {
        switch self {
        case .invalidUrl: return "Invalid URL"
        case .networkError(let msg): return "Network error: \(msg)"
        case .parseError(let msg): return "Parse error: \(msg)"
        case .imageLoadError(let msg): return "Image load error: \(msg)"
        }
    }
}

/// Loads WebVTT thumbnail sprite sheets and their associated images
class ThumbnailLoader {

    private let session: URLSession
    private var authToken: String?

    init(session: URLSession = .shared, authToken: String? = nil) {
        self.session = session
        self.authToken = authToken
    }

    /// Set the authorization token for authenticated requests
    func setAuthToken(_ token: String?) {
        debugPrint("ThumbnailLoader: setAuthToken - hasToken=\(token != nil)")
        self.authToken = token
    }

    /// Load thumbnails from a WebVTT URL
    /// - Parameter webVttUrl: The URL of the WebVTT file
    /// - Returns: A ThumbnailSprite with loaded cues and images
    func loadThumbnails(webVttUrl: String) async throws -> ThumbnailSprite {
        debugPrint("ThumbnailLoader: loadThumbnails - starting fetch from \(webVttUrl)")

        // Fetch WebVTT content
        let vttContent = try await fetchWebVtt(url: webVttUrl)
        debugPrint("ThumbnailLoader: Fetched WebVTT content, length=\(vttContent.count) chars")
        debugPrint("ThumbnailLoader: WebVTT preview: \(String(vttContent.prefix(500)))")

        // Parse WebVTT - use the WebVTT URL's directory as base
        let baseUrl: String
        if let lastSlash = webVttUrl.lastIndex(of: "/") {
            baseUrl = String(webVttUrl[..<lastSlash])
        } else {
            baseUrl = webVttUrl
        }
        debugPrint("ThumbnailLoader: Using baseUrl=\(baseUrl)")

        let cues = ThumbnailWebVttParser.parse(vttContent: vttContent, baseUrl: baseUrl)
        debugPrint("ThumbnailLoader: Parsed \(cues.count) cues from WebVTT")

        if cues.isEmpty {
            debugPrint("ThumbnailLoader: No cues found in WebVTT")
            return ThumbnailSprite(cues: [])
        }

        // Log first few cues for debugging
        for (i, cue) in cues.prefix(3).enumerated() {
            debugPrint("ThumbnailLoader: Cue[\(i)] start=\(cue.startTimeMs)ms end=\(cue.endTimeMs)ms url=\(cue.imageUrl) rect=\(cue.rect)")
        }

        // Create sprite and load images
        let sprite = ThumbnailSprite(cues: cues)

        // Load all unique sprite images
        let uniqueUrls = sprite.uniqueImageUrls
        debugPrint("ThumbnailLoader: Loading \(uniqueUrls.count) sprite image(s)")

        for imageUrl in uniqueUrls {
            debugPrint("ThumbnailLoader: Loading sprite image from \(imageUrl)")
            do {
                let image = try await loadImage(url: imageUrl)
                sprite.setBitmap(image, forUrl: imageUrl)
                debugPrint("ThumbnailLoader: Loaded sprite image size=\(image.size)")
            } catch {
                debugPrint("ThumbnailLoader: Failed to load sprite image from \(imageUrl): \(error)")
            }
        }

        debugPrint("ThumbnailLoader: Finished loading, hasBitmaps=\(sprite.hasBitmaps)")
        return sprite
    }

    /// Fetch WebVTT file content
    private func fetchWebVtt(url: String) async throws -> String {
        guard let requestUrl = URL(string: url) else {
            debugPrint("ThumbnailLoader: fetchWebVtt - invalid URL: \(url)")
            throw ThumbnailLoaderError.invalidUrl
        }

        debugPrint("ThumbnailLoader: fetchWebVtt - fetching \(requestUrl)")

        var request = URLRequest(url: requestUrl)
        // Only add auth header if URL doesn't already have authorization query param
        let hasAuthQueryParam = url.contains("authorization=")
        if let token = authToken, !hasAuthQueryParam {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            debugPrint("ThumbnailLoader: fetchWebVtt - added Authorization header")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                debugPrint("ThumbnailLoader: fetchWebVtt - invalid response type")
                throw ThumbnailLoaderError.networkError("Invalid response")
            }

            debugPrint("ThumbnailLoader: fetchWebVtt - HTTP \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                debugPrint("ThumbnailLoader: fetchWebVtt - error body: \(body.prefix(200))")
                throw ThumbnailLoaderError.networkError("HTTP \(httpResponse.statusCode)")
            }

            guard let content = String(data: data, encoding: .utf8) else {
                throw ThumbnailLoaderError.parseError("Failed to decode WebVTT content")
            }

            return content
        } catch let error as ThumbnailLoaderError {
            throw error
        } catch {
            debugPrint("ThumbnailLoader: fetchWebVtt - network error: \(error)")
            throw ThumbnailLoaderError.networkError(error.localizedDescription)
        }
    }

    /// Load a sprite image from URL
    private func loadImage(url: String) async throws -> UIImage {
        guard let requestUrl = URL(string: url) else {
            debugPrint("ThumbnailLoader: loadImage - invalid URL: \(url)")
            throw ThumbnailLoaderError.invalidUrl
        }

        debugPrint("ThumbnailLoader: loadImage - loading \(requestUrl)")

        var request = URLRequest(url: requestUrl)
        // Only add auth header if URL doesn't already have authorization query param
        let hasAuthQueryParam = url.contains("authorization=")
        if let token = authToken, !hasAuthQueryParam {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ThumbnailLoaderError.networkError("Invalid response")
            }

            debugPrint("ThumbnailLoader: loadImage - HTTP \(httpResponse.statusCode), dataSize=\(data.count)")

            guard httpResponse.statusCode == 200 else {
                throw ThumbnailLoaderError.networkError("HTTP \(httpResponse.statusCode)")
            }

            guard let image = UIImage(data: data) else {
                throw ThumbnailLoaderError.imageLoadError("Failed to decode image data")
            }

            return image
        } catch let error as ThumbnailLoaderError {
            throw error
        } catch {
            debugPrint("ThumbnailLoader: loadImage - network error: \(error)")
            throw ThumbnailLoaderError.networkError(error.localizedDescription)
        }
    }
}
