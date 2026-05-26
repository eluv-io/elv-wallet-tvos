import EluvioCore
import SwiftUI

enum AppTab: Hashable {
  case home, myItems, profile
}

struct ContentView: View {
  // State is owned here so deep links and sign-out can switch tabs and
  // reset the Discover nav stack independent of which view is rendering.
  @State private var selectedTab: AppTab = .home
  @State private var discoverPath = NavigationPath()

  var body: some View {
    TabView(selection: $selectedTab) {
      DiscoverView(path: $discoverPath)
        .tabItem { Label("Home", systemImage: "house") }
        .tag(AppTab.home)

      MyItemsView()
        .tabItem { Label("My Items", systemImage: "rectangle.stack") }
        .tag(AppTab.myItems)

      ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
        .tag(AppTab.profile)
    }
    // When a deep link queues a property, jump back to Home + clear the
    // Discover stack before DiscoverView picks up the queued id and pushes.
    .onChange(of: DeepLinkRouter.shared.pendingPropertyId) { _, newValue in
      guard newValue != nil else { return }
      resetToDiscover()
    }
    // On sign-out, reset the app to a fresh Discover state. SwiftUI's
    // @Observable tracking on AccountStore.account drives this — when
    // SignOutHandler.signOut() flips account to nil, we land here.
    .onChange(of: AccountStore.shared.account?.id) { _, newId in
      if newId == nil { resetToDiscover() }
    }
  }

  private func resetToDiscover() {
    selectedTab = .home
    discoverPath = NavigationPath()
  }
}

#Preview {
  ContentView()
}
