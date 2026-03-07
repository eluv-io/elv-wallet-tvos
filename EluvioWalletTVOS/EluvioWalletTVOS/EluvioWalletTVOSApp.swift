//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SDWebImageSwiftUI
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

    initWebImageComponents()
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
      .task {
        eluvio.router = router
        try? await eluvio.fabric.connect()
      }
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
      var realUrl = request.url

      if var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false),
        components.url?.absoluteString.contains(ImageLink.fabricUrlPlaceholder) == true
      {
        components.scheme = nil
        components.host = nil
        let base = FabricConfigStore.shared.fabricBaseUrl
        let rest = components.url!.absoluteString.trimmingPrefix("/")
        realUrl = URL(string: base + rest)
      }

      var modified = request
      modified.url = realUrl
      #if DEBUG
        // Extremely verbose, but useful to check images are being requested at correct sizes
        //debugPrint("SDWebImage requesting:", modified.url?.absoluteString ?? "nil")
      #endif
      return modified
    }
  }
}
