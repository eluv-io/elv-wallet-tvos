//
//  MainView.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-08-10.
//

import Combine
import EluvioCore
import SwiftUI
import SwiftyJSON

struct HeaderView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  var logo = "e_logo"
  var logoUrl = ""
  var name = APP_CONFIG.app.name

  var body: some View {
    VStack {
      HStack(spacing: 20) {
        if !eluvio.viewState.isBranded {
          Image(logo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 60)
          Text(name)
            .foregroundColor(Color.white)
            .font(.headline)
        } else {
          Image(logo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 250, height: 60)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

enum MainTab { case Discover, Items, Profile }

struct MainView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI

  @State var selection: MainTab = .Discover
  @State var logOutTimer = Timer.publish(every: 24 * 60 * 60, on: .main, in: .common)
  @FocusState private var focusedTab: MainTab?
  @Namespace private var mainScope
  @Environment(\.resetFocus) private var resetFocus

  /// The rail expands while it holds focus, and scrims the content underneath it.
  private var railExpanded: Bool { focusedTab != nil }

  /// Drops rail focus - which also collapses it - and sends focus into the selected tab.
  /// Deferred a tick, because a freshly selected tab is still disabled in this update pass and
  /// would have no default for the focus reset to find.
  private func handOffToContent() {
    focusedTab = nil
    Task { @MainActor in resetFocus(in: mainScope) }
  }

  var body: some View {
    ZStack(alignment: .leading) {
      // Tabs stay mounted and are swapped by opacity, so each one's `.task` fires once rather
      // than on every switch.
      // Discover insets its own content: it's the only full-bleed screen, and padding it from
      // out here would drag its hero background off the screen edge with it.
      DiscoverView(leadingInset: NavRail.contentInset)
        .environmentObject(self.eluvio)
        .opacity(selection == .Discover ? 1.0 : 0.0)
        .prefersDefaultFocus(selection == .Discover, in: mainScope)
        // Hidden tabs stay mounted, so they have to be taken out of the focus engine
        // explicitly or focus walks into invisible controls.
        .disabled(selection != .Discover)

      MyItemsView()
        .environmentObject(self.eluvio)
        .modifier(TabSlot())
        .opacity(selection == .Items ? 1.0 : 0.0)
        .prefersDefaultFocus(selection == .Items, in: mainScope)
        .disabled(selection != .Items)

      ProfileView()
        .environmentObject(self.eluvio)
        .preferredColorScheme(.dark)
        .modifier(TabSlot())
        .opacity(selection == .Profile ? 1.0 : 0.0)
        .prefersDefaultFocus(selection == .Profile, in: mainScope)
        .disabled(selection != .Profile)

      // Darkens the content while the rail is open, so its labels read against artwork
      // instead of sitting straight on top of it.
      LinearGradient(
        stops: [
          .init(color: .black.opacity(0.85), location: 0),
          .init(color: .clear, location: 0.55),
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
      .opacity(railExpanded ? 1 : 0)
        .animation(NavRail.expandAnimation, value: railExpanded)
        .allowsHitTesting(false)
        .edgesIgnoringSafeArea(.all)

      NavRailView(
        selection: $selection,
        focusedTab: $focusedTab,
        onSelect: { tab in
          selection = tab
          handOffToContent()
        },
        onExit: handOffToContent
      )
    }
    .focusScope(mainScope)
    .preferredColorScheme(colorScheme)
    .edgesIgnoringSafeArea(.all)
    // Back from any other tab returns to Discover instead of leaving the app. Passing nil on
    // Discover itself leaves the default behaviour in place, rather than swallowing Back.
    .onExitCommand(perform: selection == .Discover ? nil : { selection = .Discover })
    .onAnyChange(of: AccountStore.shared.account) { _, newAccount in
      if newAccount == nil {
        self.selection = MainTab.Discover
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Header View") {
  HeaderView()
    .environmentObject(EluvioAPI())
    .padding()
    .background(Color.black)
}

#Preview("Main View") {
  MainView()
    .preferredColorScheme(.dark)
    .environmentObject(EluvioAPI())
}

/// The box the Dashboard hands a tab, inset past the nav rail.
///
/// A real box rather than padding: padding leaves the view full width and merely offsets it, so
/// anything sized against the window still overhangs. The clip is the guarantee — whatever a tab
/// draws, it cannot reach across the rail.
private struct TabSlot: ViewModifier {
  func body(content: Content) -> some View {
    HStack(spacing: 0) {
      Color.clear.frame(width: NavRail.contentInset)
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The Dashboard ignores the safe area so Discover can bleed to the edges, so the slot
        // has to put a title-safe margin back for the screens that sit inside it.
        .padding(.top, 60)
        .clipped()
    }
  }
}
