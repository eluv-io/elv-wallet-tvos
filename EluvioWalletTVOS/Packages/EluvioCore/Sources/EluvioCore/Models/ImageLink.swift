import Foundation

public struct ImageLink: Codable {
  public var dot: LinkContainer
  public var slash: String

  // Only used in legacy NFTs
  public var sources: Sources?

  public enum CodingKeys: String, CodingKey {
    case dot = "."
    case slash = "/"
    case sources
  }

  public struct LinkContainer: Codable {
    var container: String
    var source: String?
  }

  public class Sources: Codable {
    var `default`: ImageLink?
  }
}

public extension ImageLink {
  /// To prevent SwiftUI from re-rendering every time a fabric config refresh occurs -
  ///  we use a dummy base url that will be swapped out by the global SDWebImageDownloader.shared.requestModifier
  public static let fabricUrlPlaceholder = "https://fabric-baseurl-placeholder.io/"

  public var url: String? {
    var path = self.slash

    if path.isEmpty {
      debugPrint("searching sources.default for link path")
      path = self.sources?.default?.slash ?? ""
    }

    if path.isEmpty {
      return nil
    }

    let hash: String
    if path.hasPrefix("/qfab") {
      hash = ""
      path = path.replaceFirst(of: "/qfab", with: "")
    } else {
      hash = self.hash ?? ""
    }

    path = NSString.path(withComponents: ["q", hash, path])

    let urlString = ImageLink.fabricUrlPlaceholder
    guard let url = URL(string: urlString) else {
      return nil
    }

    var pathComponents = url.pathComponents
    pathComponents.append(path)
    path = NSString.path(withComponents: pathComponents)

    var components = URLComponents()
    components.scheme = url.scheme
    components.host = url.host
    components.path = path

    var queryItems: [URLQueryItem] = []
    let auth = AccountStore.shared.bestToken
    queryItems.append(URLQueryItem(name: "authorization", value: auth))

    components.queryItems = queryItems

    guard let newUrl = components.url else {
      return nil
    }

    return newUrl.standardized.absoluteString
  }

  private var hash: String? {
    var hash = self.dot.source ?? ""

    if hash.isEmpty {
      hash = self.dot.container
    }

    if hash.isEmpty {
      hash = self.sources?.default?.dot.container ?? ""
    }

    if hash.isEmpty {
      return nil
    }
    return hash
  }
}
