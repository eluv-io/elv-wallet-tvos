import Foundation

public extension ImageLink {
  public static func test(width: Int = 200, height: Int = 200) -> ImageLink {
    ImageLink(dot: ImageLink.LinkContainer(container: "container", source: nil), slash: "fakePath/width/\(width)/height/\(height)/randomness_\(UUID().uuidString)")
  }
}
