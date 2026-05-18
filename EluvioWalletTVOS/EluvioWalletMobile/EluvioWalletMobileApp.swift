import EluvioCore
import SwiftUI

@main
struct EluvioWalletMobileApp: App {
  @State private var bootstrapped = false

  init() {
    WebImageSetup.configure()
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if bootstrapped {
          ContentView()
        } else {
          ProgressView()
        }
      }
      .preferredColorScheme(.dark)
      .task {
        await FabricConfigStore.shared.bootstrap()
        bootstrapped = true
      }
      // Universal Links: https://wallet.contentfabric.io/iq__...
      .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
        guard let url = activity.webpageURL else { return }
        DeepLinkRouter.shared.handle(url: url)
      }
      // Custom-scheme fallback if we ever add one (elvwallet://iq__...).
      .onOpenURL { url in
        DeepLinkRouter.shared.handle(url: url)
      }
    }
  }
}
