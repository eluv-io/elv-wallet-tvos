import CoreGraphics
import Foundation

/// The shape of a media card. Backed by the server's `aspect_ratio` strings
/// ("square", "portrait", "landscape") and also drives card sizing.
public enum AspectRatio: String, Codable {
  case square, portrait, landscape

  public init?(_ rawValue: String?) {
    guard let rawValue = rawValue?.lowercased().nilIfEmpty() else { return nil }
    self.init(rawValue: rawValue)
  }

  /// Width-to-height ratio of the card.
  public var value: CGFloat {
    switch self {
    case .square: 1 / 1
    case .portrait: 2 / 3
    case .landscape: 16 / 9
    }
  }
}

/// Picks the best thumbnail and its aspect ratio, mirroring Android's
/// `DisplaySettings.thumbnailUrlAndRatio`: with no forced ratio, the first
/// available image wins (square, landscape, portrait). When a ratio is forced,
/// the matching image is preferred, but the forced ratio is kept even if only
/// a mismatched image exists.
public func resolveThumbnail(
  square: String, portrait: String, landscape: String, forced: AspectRatio?
) -> (thumbnail: String, ratio: AspectRatio) {
  var thumbnail = ""
  var ratio = AspectRatio.square
  if !square.isEmpty {
    thumbnail = square
    ratio = .square
  } else if !landscape.isEmpty {
    thumbnail = landscape
    ratio = .landscape
  } else if !portrait.isEmpty {
    thumbnail = portrait
    ratio = .portrait
  }

  if let forced = forced {
    let matching =
      switch forced {
      case .square: square
      case .portrait: portrait
      case .landscape: landscape
      }
    return (matching.isEmpty ? thumbnail : matching, forced)
  }

  return (thumbnail, ratio)
}

public extension MediaPropertySectionItem {
  /// Card image and shape for this item. The section's `aspect_ratio` wins when
  /// it forces one, then the item's own; otherwise the available thumbnails
  /// decide. Item-level thumbnails override the media's.
  func thumbnailAndRatio(sectionRatio: AspectRatio? = nil) -> (
    thumbnail: String, ratio: AspectRatio
  ) {
    resolveThumbnail(
      square: display?.thumbnail_image_square?.url ?? media?.thumbnail_image_square?.url ?? "",
      portrait: display?.thumbnail_image_portrait?.url ?? media?.thumbnail_image_portrait?.url ?? "",
      landscape: display?.thumbnail_image_landscape?.url
        ?? media?.thumbnail_image_landscape?.url ?? "",
      forced: sectionRatio ?? AspectRatio(display?.aspect_ratio))
  }
}
