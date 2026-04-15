//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import FirebaseCore
import SDWebImage
import SwiftUI

@main
struct EluvioWalletTVOSApp: App {
  @StateObject var eluvio = EluvioAPI.shared
  @StateObject var router: Router = Router.shared

  #if DEBUG
    @State private var debugMenu = DebugMenuHandler()
  #endif

  init() {
    print("App Init")

    configureFirebase()
    initWebImageComponents()
  }

  private func configureFirebase() {
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
      return
    }

    // No real GoogleService-Info.plist bundled — leave Firebase un-configured
    // and silence its logger so subsequent analytics calls don't spew
    // "default app not configured" warnings on every event.
    print("GoogleService-Info.plist not in bundle — Firebase disabled, logs suppressed")
    FirebaseConfiguration.shared.setLoggerLevel(.error)
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        ContentView()
          .preferredColorScheme(.dark)
          .environmentObject(eluvio)
          .environmentObject(router)
      }
      #if DEBUG
        .onKeyPress(phases: .down) { debugMenu.handle($0, router: router) }
      #endif
      .edgesIgnoringSafeArea(.all)
    }
  }

  private func initWebImageComponents() {
    // Normalize SDWebImage cache keys:
    // 1. Strip "authorization" so the same image hits cache regardless of token changes
    // 2. Normalize contentfabric.io hosts so different host-x-x-x-x nodes share cache entries
    SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter { url in
      guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return url.absoluteString
      }
      components.queryItems = components.queryItems?.filter { $0.name != "authorization" }
      if components.queryItems?.isEmpty == true {
        components.queryItems = nil
      }
      if let host = components.host, host.hasSuffix(".contentfabric.io") {
        components.host = "contentfabric.io"
      }
      return components.url?.absoluteString ?? url.absoluteString
    }

    // Check and replace fabric url placeholder with real fabric base url
    SDWebImageDownloader.shared.requestModifier = SDWebImageDownloaderRequestModifier { request in
      #if DEBUG
        if isInPreviewMode {
          return fakeImageRequest(request)
        }
      #endif

      var modified = request
      modified.url = request.url!.replaceFabricUrlPlaceholder()
      #if DEBUG
        // Extremely verbose, but useful to check images are being requested at correct sizes
        //debugPrint("SDWebImage requesting:", modified.url?.absoluteString ?? "nil")
      #endif
      return modified
    }
  }
}

#if DEBUG
  private var isInPreviewMode: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }

  private func fakeImageRequest(_ request: URLRequest) -> URLRequest {
    var modified = request
    var width = 200
    var height = 200
    let path = request.url?.pathComponents ?? []
    if let index = path.firstIndex(of: "width") {
      width = Int(path[index + 1]) ?? width
    }
    if let index = path.firstIndex(of: "height") {
      height = Int(path[index + 1]) ?? height
    }
    modified.url = URL(string: "https://picsum.photos/\(width)/\(height)")
    return modified
  }

#endif
