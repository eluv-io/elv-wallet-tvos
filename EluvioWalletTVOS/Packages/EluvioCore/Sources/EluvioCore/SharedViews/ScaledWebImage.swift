import SDWebImage
import SDWebImageSwiftUI
import SwiftUI

/// Returns a `WebImage` with a request modifier that appends `height=` to the URL.
public func ScaledWebImage(url: String, height: CGFloat) -> WebImage {
  scaledWebImage(url: url, dimension: "height", points: height)
}

/// Returns a `WebImage` with a request modifier that appends `width=` to the URL.
public func ScaledWebImage(url: String, width: CGFloat) -> WebImage {
  scaledWebImage(url: url, dimension: "width", points: width)
}

/// Convenience shorthand to scaled image to screen-height
public func ScaledWebImage(url: String, height: UIScreen) -> WebImage {
  ScaledWebImage(url: url, height: height.bounds.height)
}

/// Appends a single pixel `dimension` (`width` or `height`) query param to the image URL.
private func scaledWebImage(url: String, dimension: String, points: CGFloat) -> WebImage {
  let pixels = Int(points * UIScreen.main.scale)
  let modifier = SDWebImageDownloaderRequestModifier { request in
    guard let urlString = request.url?.absoluteString else { return request }
    let separator = urlString.contains("?") ? "&" : "?"
    var modified = request
    modified.url = URL(string: "\(urlString)\(separator)\(dimension)=\(pixels)")

    // Call global request modifier before returning
    return SDWebImageDownloader.shared.requestModifier?.modifiedRequest(with: modified)
  }
  return WebImage(url: URL(string: url), context: [.downloadRequestModifier: modifier])
}
