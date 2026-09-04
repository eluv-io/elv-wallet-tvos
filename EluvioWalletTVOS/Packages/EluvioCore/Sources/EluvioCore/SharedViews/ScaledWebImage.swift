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
  let imageUrl = URL(string: url)

  // The fabric's resizer can't decode SVG and answers 400 to any scaled
  // request, so vectors are fetched whole - like Android does - and rasterized
  // on device instead. Bounding only the dimension the caller asked for keeps
  // the fabric's semantics: the other one follows the image's aspect ratio,
  // rather than being squeezed into a square box.
  if imageUrl?.pathExtension.lowercased() == "svg" {
    let unbounded = CGFloat.greatestFiniteMagnitude
    let box =
      dimension == "height"
      ? CGSize(width: unbounded, height: CGFloat(pixels))
      : CGSize(width: CGFloat(pixels), height: unbounded)
    return WebImage(
      url: imageUrl,
      context: [
        .imageThumbnailPixelSize: NSValue(cgSize: box),
        .imagePreserveAspectRatio: true,
      ])
  }

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
