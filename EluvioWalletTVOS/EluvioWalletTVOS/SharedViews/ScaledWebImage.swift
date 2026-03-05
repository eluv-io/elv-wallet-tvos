import SDWebImage
import SDWebImageSwiftUI
import SwiftUI

/// Returns a `WebImage` with a request modifier that appends `height=` to the URL.
func ScaledWebImage(url: String, height: CGFloat) -> WebImage {
  let pixelHeight = Int(height * UIScreen.main.scale)
  let modifier = SDWebImageDownloaderRequestModifier { request in
    guard let urlString = request.url?.absoluteString else { return request }
    let separator = urlString.contains("?") ? "&" : "?"
    var modified = request
    modified.url = URL(string: "\(urlString)\(separator)height=\(pixelHeight)")

    // Call global request modifier before returning
    return SDWebImageDownloader.shared.requestModifier?.modifiedRequest(with: modified)
  }
  return WebImage(url: URL(string: url), context: [.downloadRequestModifier: modifier])
}
