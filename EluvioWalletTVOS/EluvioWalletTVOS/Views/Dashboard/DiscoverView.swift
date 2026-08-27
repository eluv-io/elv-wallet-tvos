//
//  DiscoverView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.

import AVKit
import Combine
import EluvioCore
import SwiftUI
import SwiftyJSON

/// Fixed box for the logo, so the text below it doesn't jump as focus moves between
/// Properties with differently shaped logos.
private let logoHeight: CGFloat = 160

struct DiscoverView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  @Namespace private var DiscoverViewNamespace

  /// Left margin for the logo, the text and the rows. Discover draws full-bleed and insets its
  /// own content, so the host passes the room the nav rail needs. Signed out there is no rail
  /// and no Dashboard at all - Discover is the root view - so it keeps the plain screen margin.
  var leadingInset: CGFloat = 80

  @State var backgroundImageURL = ""

  @State private var selected: MediaProperty? = nil

  /// The focused Property's promo video, once it resolves to something playable. Stays nil
  /// while it's being fetched, and for the (currently: every) Property that has no video.
  @State private var heroVideo: AVPlayerItem? = nil

  private var rows: [DiscoverStore.PropertyRow] { DiscoverStore.shared.propertyRows }

  /// Drives the hero and the logo/text: whatever card holds focus, or the first one before
  /// anything does.
  private var displayedProperty: MediaProperty? {
    selected ?? rows.first?.properties.first
  }

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      if eluvio.isCustomApp() {
        // fetchProperty(id:) caches into ownedProperties, not the discover list,
        // so resolve by the configured slug instead of properties.first
        let slug = APP_CONFIG.allowed_properties?.first
        CustomAppDiscoverView(
          property: slug.flatMap { PropertyStore.shared.getProperty(id: $0) },
          selected: $selected,
          namespace: DiscoverViewNamespace
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if rows.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .edgesIgnoringSafeArea(.all)
          .accessibilityIdentifier("loading_indicator")
      } else {
        HeroScrims()

        VStack(alignment: .leading, spacing: 0) {
          VStack(alignment: .leading, spacing: 0) {
            PropertyLogo(property: displayedProperty)
            PropertyText(property: displayedProperty)
          }
          .padding(.leading, leadingInset)
          .padding(.bottom, 22)
          .animation(heroTextAnimation, value: displayedProperty)
          // The rows are inset by the card focus margin, so their titles still line up
          // with the logo above them.
          DiscoverRowsView(rows: rows, selected: $selected)
            .padding(.leading, leadingInset - 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
      }
    }
    .task {
      if eluvio.isCustomApp(), let slug = APP_CONFIG.allowed_properties?.first {
        debugPrint("Fetching single allowed property: \(slug)")
        await PropertyStore.shared.fetchProperty(id: slug)
      } else {
        debugPrint("Fetching discover rows")
        await DiscoverStore.shared.load()
      }
    }
    .accessibilityIdentifier("discover_view")
    .onAnyChange(of: PropertyStore.shared.properties) { _, properties in
      if properties.isEmpty {
        // Prevent bg image from old Properties from sticking around
        selected = nil
      }
    }
    .task(id: displayedProperty?.id) {
      await loadHeroVideo()
    }
    .onAnyChange(of: displayedProperty) { _, newValue in
      // Fade the actual View in and out when swapping bg images
      if eluvio.isCustomApp() {
        backgroundImageURL = newValue?.startScreenBackground ?? ""
      } else {
        backgroundImageURL = newValue?.backgroundImage ?? ""
      }
    }
    .background(
      ZStack {
        BackgroundImage(
          url: backgroundImageURL,
          fallbackAsset: eluvio.isCustomApp() ? "start-screen-background" : nil
        )
        .id(backgroundImageURL)
        if let heroVideo {
          LoopingVideoPlayer([heroVideo], endAction: .loop)
            .edgesIgnoringSafeArea(.all)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .id("hero video \(heroVideo.hashValue)")
        }
      }
    )
    .animation(bgImageAnimation, value: backgroundImageURL)
  }

  /// Resolves the focused Property's promo video to something playable.
  ///
  /// Fetching waits out a focus dwell, so scrubbing through cards doesn't fire a playout
  /// request per Property - `task(id:)` cancels this when focus moves on. Until it resolves
  /// (or if it fails) there is no video, and the background image stands on its own.
  private func loadHeroVideo() async {
    // Drop the outgoing Property's video right away, rather than keeping it around until
    // the new one is ready.
    heroVideo = nil
    guard !eluvio.isCustomApp(), let property = displayedProperty,
      let hash = heroVideoHash(property)
    else { return }

    do {
      try await Task.sleep(for: .milliseconds(1200))
    } catch {
      return
    }

    do {
      heroVideo = try await MakePlayerItemFromVersionHash(
        fabric: eluvio.fabric, versionHash: hash)
    } catch {
      debugPrint("Error fetching hero video for \(property.id): ", error)
    }
  }
}

/// The hash of a Property's promo video, from its fabric link: either the link's explicit
/// source, or the `hq__` segment of its path.
private func heroVideoHash(_ property: MediaProperty) -> String? {
  guard let link = property.main_page_background_video_tv else { return nil }
  if let source = link["."]["source"].string?.nilIfEmpty() {
    return source
  }
  return link["/"].string?
    .split(separator: "/")
    .first { $0.hasPrefix("hq__") }
    .map(String.init)
}

private let bgImageAnimation = Animation.linear(duration: 0.5)
private let heroTextAnimation = Animation.linear(duration: 0.3)
private let heroBaseColor = Color(red: 0.031, green: 0.035, blue: 0.047)

/// Scrims over the hero background, so the logo, text and rows stay readable.
private struct HeroScrims: View {
  var body: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: heroBaseColor.opacity(0.96), location: 0),
          .init(color: heroBaseColor.opacity(0.72), location: 0.26),
          .init(color: heroBaseColor.opacity(0.15), location: 0.52),
          .init(color: .clear, location: 0.72),
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
      LinearGradient(
        stops: [
          .init(color: .clear, location: 0.45),
          .init(color: heroBaseColor.opacity(0.55), location: 0.74),
          .init(color: heroBaseColor.opacity(0.98), location: 0.98),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .edgesIgnoringSafeArea(.all)
    .allowsHitTesting(false)
  }
}

/// The focused Property's logo, falling back to its name.
private struct PropertyLogo: View {
  var property: MediaProperty?

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      if let logo = (property?.tv_header_logo ?? property?.header_logo)?.url?.nilIfEmpty() {
        ScaledWebImage(url: logo, height: logoHeight)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 700, maxHeight: logoHeight, alignment: .bottomLeading)
      } else if let property {
        Text(property.displayName)
          .font(.system(size: 48, weight: .bold))
          .foregroundColor(Color(white: 0.96))
      }
    }
    .frame(height: logoHeight, alignment: .bottomLeading)
    .frame(maxWidth: .infinity, alignment: .leading)
    .id(property?.id ?? "")
    .transition(.opacity)
  }
}

/// The focused Property's Discover-page title and description. Most Properties define
/// neither, in which case this takes up no space at all.
private struct PropertyText: View {
  var property: MediaProperty?

  var body: some View {
    let title = property?.main_page_title?.nilIfEmpty()
    let description = property?.main_page_description?.nilIfEmpty()
    VStack(alignment: .leading, spacing: 8) {
      if let title {
        Text(title)
          .font(.system(size: 32))
          .foregroundColor(Color(white: 0.96))
          .lineLimit(1)
      }
      if let description {
        Text(description)
          .font(.system(size: 24))
          .foregroundColor(Color(red: 0.71, green: 0.71, blue: 0.74))
          .lineLimit(2)
      }
    }
    .frame(maxWidth: 800, alignment: .leading)
    .padding(.top, title == nil && description == nil ? 0 : 12)
    .id(property?.id ?? "")
    .transition(.opacity)
  }
}

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
