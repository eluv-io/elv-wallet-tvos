//
//  ThumbnailWebVttParser.swift
//  EluvioWalletTVOS
//
//  WebVTT parser for trickplay thumbnail sprites
//

import Foundation
import CoreGraphics

/// Represents a single thumbnail cue from WebVTT
struct ThumbnailCue {
    let startTimeMs: Int64
    let endTimeMs: Int64
    let imageUrl: String
    let rect: CGRect
}

/// Parser for WebVTT thumbnail sprite sheets
class ThumbnailWebVttParser {

    // Pattern to match timestamps like: 00:00:00.000 --> 00:00:05.000
    private static let timestampPattern = try! NSRegularExpression(
        pattern: #"(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})\.(\d{3})"#,
        options: []
    )

    // Pattern to match sprite coordinates like: #xywh=0,0,160,90
    private static let xywhPattern = try! NSRegularExpression(
        pattern: #"#xywh=(\d+),(\d+),(\d+),(\d+)"#,
        options: []
    )

    /// Parse WebVTT content and return list of thumbnail cues
    /// - Parameters:
    ///   - vttContent: The raw WebVTT file content
    ///   - baseUrl: The base URL for resolving relative image paths
    /// - Returns: Array of ThumbnailCue objects
    static func parse(vttContent: String, baseUrl: String) -> [ThumbnailCue] {
        var cues: [ThumbnailCue] = []
        let lines = vttContent.components(separatedBy: .newlines)

        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // Look for timestamp line
            if let timestampMatch = matchTimestamp(line) {
                let startTimeMs = timestampMatch.startTimeMs
                let endTimeMs = timestampMatch.endTimeMs

                // Move to next non-empty line (the image URL line)
                i += 1
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                    i += 1
                }

                if i < lines.count {
                    let imageLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if let cue = parseImageLine(imageLine, startTimeMs: startTimeMs, endTimeMs: endTimeMs, baseUrl: baseUrl) {
                        cues.append(cue)
                    }
                }
            }
            i += 1
        }

        return cues
    }

    /// Match timestamp line and extract start/end times
    private static func matchTimestamp(_ line: String) -> (startTimeMs: Int64, endTimeMs: Int64)? {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = timestampPattern.firstMatch(in: line, options: [], range: range) else {
            return nil
        }

        // Extract groups: hours, minutes, seconds, millis for start (1-4) and end (5-8)
        guard match.numberOfRanges >= 9 else { return nil }

        func extractInt(_ group: Int) -> Int64 {
            guard let range = Range(match.range(at: group), in: line) else { return 0 }
            return Int64(line[range]) ?? 0
        }

        let startHours = extractInt(1)
        let startMinutes = extractInt(2)
        let startSeconds = extractInt(3)
        let startMillis = extractInt(4)

        let endHours = extractInt(5)
        let endMinutes = extractInt(6)
        let endSeconds = extractInt(7)
        let endMillis = extractInt(8)

        let startTimeMs = startHours * 3600000 + startMinutes * 60000 + startSeconds * 1000 + startMillis
        let endTimeMs = endHours * 3600000 + endMinutes * 60000 + endSeconds * 1000 + endMillis

        return (startTimeMs, endTimeMs)
    }

    /// Parse the image URL line and extract sprite coordinates
    private static func parseImageLine(_ line: String, startTimeMs: Int64, endTimeMs: Int64, baseUrl: String) -> ThumbnailCue? {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let xywhMatch = xywhPattern.firstMatch(in: line, options: [], range: range) else {
            return nil
        }

        func extractInt(_ group: Int) -> Int {
            guard let matchRange = Range(xywhMatch.range(at: group), in: line) else { return 0 }
            return Int(line[matchRange]) ?? 0
        }

        let x = extractInt(1)
        let y = extractInt(2)
        let width = extractInt(3)
        let height = extractInt(4)

        // Extract image URL (everything before #xywh=)
        let imageUrlPart: String
        if let hashIndex = line.range(of: "#xywh=") {
            imageUrlPart = String(line[..<hashIndex.lowerBound]).trimmingCharacters(in: .whitespaces)
        } else {
            return nil
        }

        let imageUrl = resolveUrl(imageUrlPart, baseUrl: baseUrl)
        let rect = CGRect(x: x, y: y, width: width, height: height)

        return ThumbnailCue(
            startTimeMs: startTimeMs,
            endTimeMs: endTimeMs,
            imageUrl: imageUrl,
            rect: rect
        )
    }

    /// Resolve relative URLs against base URL
    private static func resolveUrl(_ url: String, baseUrl: String) -> String {
        // Already absolute URL
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        }

        // Absolute path
        if url.hasPrefix("/") {
            if let baseURL = URL(string: baseUrl),
               let scheme = baseURL.scheme,
               let host = baseURL.host {
                return "\(scheme)://\(host)\(url)"
            }
            return baseUrl + url
        }

        // Relative path
        let cleanBase = baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl
        return "\(cleanBase)/\(url)"
    }
}
