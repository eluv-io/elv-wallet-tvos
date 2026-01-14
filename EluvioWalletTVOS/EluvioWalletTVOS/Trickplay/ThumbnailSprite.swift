//
//  ThumbnailSprite.swift
//  EluvioWalletTVOS
//
//  Data model for trickplay thumbnail sprites
//

import Foundation
import UIKit
import CoreGraphics

/// Represents a loaded thumbnail sprite sheet with its cues
class ThumbnailSprite {
    let cues: [ThumbnailCue]
    private var bitmaps: [String: UIImage] = [:]

    init(cues: [ThumbnailCue]) {
        self.cues = cues
    }

    /// Set the loaded bitmap for a specific URL
    func setBitmap(_ bitmap: UIImage, forUrl url: String) {
        bitmaps[url] = bitmap
    }

    /// Get the bitmap for a specific URL
    func getBitmap(forUrl url: String) -> UIImage? {
        return bitmaps[url]
    }

    /// Check if any bitmaps are loaded
    var hasBitmaps: Bool {
        return !bitmaps.isEmpty
    }

    /// Get all unique image URLs from cues
    var uniqueImageUrls: [String] {
        return Array(Set(cues.map { $0.imageUrl }))
    }

    /// Find the cue for a given position using binary search
    /// - Parameter positionMs: Position in milliseconds
    /// - Returns: The matching ThumbnailCue, or nil if none found
    func getCue(forPosition positionMs: Int64) -> ThumbnailCue? {
        guard !cues.isEmpty else { return nil }

        var low = 0
        var high = cues.count - 1

        while low <= high {
            let mid = (low + high) / 2
            let cue = cues[mid]

            if positionMs < cue.startTimeMs {
                high = mid - 1
            } else if positionMs >= cue.endTimeMs {
                low = mid + 1
            } else {
                return cue
            }
        }

        // If position is outside all cues, return closest edge
        if positionMs < cues.first!.startTimeMs {
            return cues.first
        }
        if positionMs >= cues.last!.endTimeMs {
            return cues.last
        }

        return nil
    }

    /// Get the source rect for a given position
    /// - Parameter positionMs: Position in milliseconds
    /// - Returns: The CGRect defining the sprite region, or nil if none found
    func getSourceRect(forPosition positionMs: Int64) -> CGRect? {
        return getCue(forPosition: positionMs)?.rect
    }

    /// Get a cropped thumbnail image for a given position
    /// - Parameter positionMs: Position in milliseconds
    /// - Returns: The cropped UIImage, or nil if not available
    func getThumbnail(forPosition positionMs: Int64) -> UIImage? {
        guard let cue = getCue(forPosition: positionMs),
              let bitmap = getBitmap(forUrl: cue.imageUrl) else {
            return nil
        }

        // Crop the sprite sheet to the correct region
        let scale = bitmap.scale
        let cropRect = CGRect(
            x: cue.rect.origin.x * scale,
            y: cue.rect.origin.y * scale,
            width: cue.rect.width * scale,
            height: cue.rect.height * scale
        )

        guard let cgImage = bitmap.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: bitmap.imageOrientation)
    }

    /// Get the aspect ratio of thumbnails (width/height)
    var aspectRatio: CGFloat {
        guard let firstCue = cues.first else { return 16.0 / 9.0 }
        return firstCue.rect.width / firstCue.rect.height
    }

    /// Get the size of individual thumbnails
    var thumbnailSize: CGSize {
        guard let firstCue = cues.first else { return CGSize(width: 160, height: 90) }
        return CGSize(width: firstCue.rect.width, height: firstCue.rect.height)
    }
}
