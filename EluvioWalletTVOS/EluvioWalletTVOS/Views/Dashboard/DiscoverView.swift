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
      if properties.isEmpty {
        ProgressView()
          .edgesIgnoringSafeArea(.all)
          .accessibilityIdentifier("loading_indicator")
      } else if eluvio.isCustomApp() {
        CustomAppDiscoverView(
          property: properties.first,
          selected: $selected,
          namespace: DiscoverViewNamespace
        )
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
      debugPrint("Fetching all properties")
      await PropertyStore.shared.fetchProperties()
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

  var property: MediaProperty?
  @Binding var selected: MediaProperty?
  var namespace: Namespace.ID

  var body: some View {
    VStack(alignment: .center, spacing: 40) {
      Spacer()
      if let property = property {
        ScaledWebImage(url: property.startScreenImage, width: 900)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 900, alignment: .leading)
          .padding(.bottom, 30)

        MediaPropertyView(property: property, selected: $selected, isSimple: true)
          .prefersDefaultFocus(in: namespace)
      }
      Spacer()
    }
  }
}
