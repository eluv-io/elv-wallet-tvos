import SwiftUI

struct ContentView: View {
  var body: some View {
    TabView {
      DiscoverView()
        .tabItem { Label("Home", systemImage: "house") }

      MyItemsView()
        .tabItem { Label("My Items", systemImage: "rectangle.stack") }

      ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
    }
  }
}

#Preview {
  ContentView()
}
