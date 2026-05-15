import EluvioCore
import SwiftUI

@main
struct EluvioWalletMobileApp: App {
  @State private var bootstrapped = false

  var body: some Scene {
    WindowGroup {
      Group {
        if bootstrapped {
          ContentView()
        } else {
          ProgressView()
        }
      }
      .task {
        await FabricConfigStore.shared.bootstrap()
        bootstrapped = true
      }
    }
  }
}
