import SwiftUI

enum AppTab: Hashable {
  case home, myItems, profile
}

struct ContentView: View {
  // State is owned here so deep links can switch tabs and reset the Discover
  // nav stack independent of which view is currently rendering.
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
      selectedTab = .home
      discoverPath = NavigationPath()
    }
  }
}

#Preview {
  ContentView()
}
