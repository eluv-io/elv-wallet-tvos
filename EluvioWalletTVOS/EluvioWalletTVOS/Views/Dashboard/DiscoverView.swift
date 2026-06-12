//
//  DiscoverView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.

import Combine
import EluvioCore
import SwiftUI
import SwiftyJSON

struct DiscoverView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  @Namespace private var DiscoverViewNamespace
  private var properties: [MediaProperty] = PropertyStore.shared.properties

  @State var backgroundImageURL = ""

  @State private var selected: MediaProperty? = nil

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if eluvio.isCustomApp() {
        // fetchProperty(id:) caches into ownedProperties, not the discover list,
        // so resolve by the configured slug instead of properties.first
        let slug = APP_CONFIG.allowed_properties?.first
        CustomAppDiscoverView(
          property: slug.flatMap { PropertyStore.shared.getProperty(id: $0) },
          selected: $selected,
          namespace: DiscoverViewNamespace
        )
      } else if properties.isEmpty {
        ProgressView()
          .edgesIgnoringSafeArea(.all)
          .accessibilityIdentifier("loading_indicator")
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            HStack {
              Image("start-screen-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 800, alignment: .leading)
              Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
            .padding(.bottom, 40)

            MediaPropertiesView(properties: properties, selected: $selected)
              .transition(.opacity)
          }
        }
      }
    }
    .task {
      if eluvio.isCustomApp(), let slug = APP_CONFIG.allowed_properties?.first {
        debugPrint("Fetching single allowed property: \(slug)")
        await PropertyStore.shared.fetchProperty(id: slug)
      } else {
        debugPrint("Fetching all properties")
        await PropertyStore.shared.fetchProperties()
      }
    }
    .accessibilityIdentifier("discover_view")
    .onAnyChange(of: properties) { _, properties in
      if properties.isEmpty {
        // Prevent bg image from old Properties from sticking around
        selected = nil
      }
    }
    .onAnyChange(of: selected) { _, newValue in
      // Fade the actual View in and out when swapping bg images
      if eluvio.isCustomApp() {
        backgroundImageURL = newValue?.startScreenBackground ?? ""
      } else {
        backgroundImageURL = newValue?.backgroundImage ?? ""
      }
    }
    .background(
      BackgroundImage(
        url: backgroundImageURL,
        fallbackAsset: eluvio.isCustomApp() ? "start-screen-background" : nil
      )
      .id(backgroundImageURL)
    )
    .animation(bgImageAnimation, value: backgroundImageURL)
    .scrollClipDisabled()
  }
}

private let bgImageAnimation = Animation.linear(duration: 0.5)

private struct BackgroundImage: View {
  var url: String
  var fallbackAsset: String? = nil
  @State var loaded = false

  var body: some View {
    ZStack {
      // Bundled background shows immediately and stays behind the web image,
      // so a server-provided background fades in on top with no blank gap.
      if let fallbackAsset {
        Image(fallbackAsset)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .edgesIgnoringSafeArea(.all)
          .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
      }
      if !url.isEmpty {
        ScaledWebImage(url: url, height: UIScreen.main)
          .onSuccess { _, _, _ in
            loaded = true
          }
          .resizable()
          .aspectRatio(contentMode: .fill)
          // Technically the transition works well even without this .opacity, but I'm not sure why..
          // I think it has something to do with WebImage internal state changing, and that conincides with setting loaded=true.
          // Either way, leaving .opacity here doesn't have a negative effect and it makes more sense, so I'm keeping it.
          .opacity(loaded ? 1 : 0)
          .animation(bgImageAnimation, value: loaded)
          .edgesIgnoringSafeArea(.all)
          .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
      }
    }
  }
}

struct CustomAppDiscoverView: View {
  @EnvironmentObject private var eluvio: EluvioAPI
  @EnvironmentObject private var router: Router

  var property: MediaProperty?
  @Binding var selected: MediaProperty?
  var namespace: Namespace.ID

  @State private var pendingSignIn = false
  @FocusState private var signInFocused: Bool

  var body: some View {
    VStack(alignment: .center, spacing: 40) {
      Spacer()
      // Show the bundled logo immediately; if the server provides an updated
      // start_screen_logo it loads behind the placeholder and swaps in silently.
      ScaledWebImage(url: property?.startScreenImage ?? "", width: 900)
        .placeholder {
          Image("start-screen-logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 900, alignment: .leading)
        .padding(.bottom, 30)

      // A single stable button the whole time — tapping before the property
      // loads shows a spinner, then routes once it arrives. Swapping in a
      // separate view on load would flicker and steal focus.
      Button(action: signInTapped) {
        if pendingSignIn {
          ProgressView()
        } else {
          Text(AccountStore.shared.isLoggedOut ? "Sign In" : "Welcome Back")
        }
      }
      .focused($signInFocused)
      .onAppear { signInFocused = true }
      .prefersDefaultFocus(in: namespace)
      .disabled(pendingSignIn)

      Spacer()
    }
    .onChange(of: property) { _, newValue in
      guard let newProperty = newValue else { return }
      selected = newProperty
      if pendingSignIn {
        pendingSignIn = false
        route(to: newProperty)
      }
    }
    .onAppear {
      if let property = property { selected = property }
    }
  }

  private func signInTapped() {
    if let property = property {
      route(to: property)
    } else {
      pendingSignIn = true
    }
  }

  private func route(to property: MediaProperty) {
    let loggedInWithSameProvider =
      property.accountType == AccountStore.shared.account?.type
    let skipLogin = property.login?.settings?.disable_login == true
    if skipLogin || loggedInWithSameProvider {
      router.path.append(.property(PropertyParam(propertyId: property.id)))
    } else {
      router.push(to: .login(LoginParam(property: property)))
    }
  }
}
