//
//  DiscoverView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.

import Combine
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
                .frame(width: 801, height: 240, alignment: .leading)
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
      BackgroundImage(url: backgroundImageURL)
        .id(backgroundImageURL)
    )
    .animation(bgImageAnimation, value: backgroundImageURL)
    .scrollClipDisabled()
  }
}

private let bgImageAnimation = Animation.linear(duration: 0.5)

private struct BackgroundImage: View {
  var url: String
  @State var loaded = false

  var body: some View {
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
      Image("start-screen-logo")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 900, height: 400, alignment: .center)

      Button(action: signInTapped) {
        if pendingSignIn {
          ProgressView()
        } else {
          Text("Sign In")
        }
      }
      .focused($signInFocused)
      .onAppear { signInFocused = true }
      .prefersDefaultFocus(in: namespace)
      .disabled(pendingSignIn)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      Image("start-screen-background")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .edgesIgnoringSafeArea(.all)
    )
    .onChange(of: property) { _, newValue in
      if pendingSignIn, let newProperty = newValue {
        pendingSignIn = false
        router.push(to: .login(LoginParam(property: newProperty)))
      }
    }
  }

  private func signInTapped() {
    if let property = property {
      router.push(to: .login(LoginParam(property: property)))
    } else {
      pendingSignIn = true
    }
  }
}
