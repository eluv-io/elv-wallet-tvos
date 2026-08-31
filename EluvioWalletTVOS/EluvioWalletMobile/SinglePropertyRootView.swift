import EluvioCore
import SwiftUI

/// Root for whitelabel builds, which ship pinned to one property via
/// `allowed_properties` in configuration.json. There's no Discover step: the
/// app loads that one property and gates it behind a full-screen welcome until
/// the user signs in.
struct SinglePropertyRootView: View {
  /// The property this build is pinned to. Nil until the first fetch lands.
  @State private var property: MediaProperty?
  @State private var selectedTab: AppTab = .home

  init() {
    let initial = Self.propertyId.flatMap { PropertyStore.shared.getProperty(id: $0) }
    _property = State(initialValue: initial)
  }

  /// Whitelabel builds set exactly one entry; the tvOS custom-app root reads
  /// `.first` the same way.
  static var propertyId: String? {
    APP_CONFIG.allowed_properties?.first
  }

  private var isSignedIn: Bool {
    guard let property, let account = AccountStore.shared.account else { return false }
    return property.accountType == account.type
  }

  var body: some View {
    Group {
      if let property {
        if isSignedIn {
          // The property page is the Home tab's root rather than a pushed
          // destination, so the bar stays up across the property detail and
          // everything pushed from it. No My Items tab here: a whitelabel
          // build has no wallet items to show, and the tab set is fixed for
          // the life of the install rather than appearing mid-session.
          TabView(selection: $selectedTab) {
            NavigationStack {
              PropertyView(property: property)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)

            ProfileView()
              .tabItem { Label("Profile", systemImage: "person") }
              .tag(AppTab.profile)
          }
        } else {
          WelcomeView(property: property) {
            // Sections resolve differently once we have a fabric token, so
            // re-fetch rather than reusing the anonymous copy.
            Task { await reload() }
          }
        }
      } else {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    // Sign-out drops back to the welcome gate; make sure the next sign-in
    // starts on Home rather than wherever the user left off.
    .onChange(of: AccountStore.shared.account?.id) { _, newId in
      if newId == nil { selectedTab = .home }
    }
    .task {
      guard property == nil else { return }
      await reload()
    }
  }

  private func reload() async {
    guard let id = Self.propertyId else {
      print("SinglePropertyRootView: no allowed_properties entry configured")
      return
    }
    await PropertyStore.shared.fetchProperty(id: id)
    property = PropertyStore.shared.getProperty(id: id)
  }
}
