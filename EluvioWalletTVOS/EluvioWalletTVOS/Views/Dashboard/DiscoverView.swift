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
private let logoHeight: CGFloat = 180

/// Widest a logo may render. Only bites on wide wordmarks - a normal-proportioned logo is
/// bound by `logoHeight` first. Fixed rather than derived from the available width, so a
/// logo renders at the same size signed in (behind the nav rail) as signed out.
private let logoMaxWidth: CGFloat = 1000

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

  /// Whether a promo video is on screen over the background image. Set by `HeroVideo` when it
  /// fades in, and cleared only once it has finished fading out, so it stays true across a
  /// focus change that swaps the image underneath.
  @State private var heroVideoVisible = false

  private var rows: [DiscoverStore.PropertyRow] { DiscoverStore.shared.propertyRows }

  /// Drives the hero and the logo/text: whatever card holds focus, or the first one before
  /// anything does.
  private var displayedProperty: MediaProperty? {
    selected ?? rows.first?.properties.first
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
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
          .padding(.top, 160)
          .padding(.bottom, 22)
          .animation(heroTextAnimation, value: displayedProperty)
          // The rows are inset by the card focus margin, so their titles still line up
          // with the logo above them.
          DiscoverRowsView(rows: rows, selected: $selected)
            .padding(.leading, leadingInset - 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
    }
    // Keyed on refreshId so switching environment in Profile reloads the page. Tabs stay
    // mounted, so a plain `.task` would only ever run once per launch.
    .task(id: eluvio.refreshId) {
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
          HeroVideo(item: heroVideo, visible: $heroVideoVisible)
            .id("hero video \(heroVideo.hashValue)")
            .transition(.opacity)
        }
      }
    )
    // With a video on top the image is fully covered, so swap it instantly: an animated
    // swap would still be fading when the video dissolves away above it, and the video's
    // fade would uncover the outgoing Property's image as a flash.
    .animation(heroVideoVisible ? nil : bgImageAnimation, value: backgroundImageURL)
  }

  /// Resolves the focused Property's promo video to something playable.
  ///
  /// Fetching waits out a focus dwell, so scrubbing through cards doesn't fire a playout
  /// request per Property - `task(id:)` cancels this when focus moves on. Until it resolves
  /// (or if it fails) there is no video, and the background image stands on its own.
  private func loadHeroVideo() async {
    // Fade the outgoing Property's video out right away, rather than keeping it around
    // until the new one is ready. The background image is already behind it, so the fade
    // lands on the image instead of on a gap.
    withAnimation(heroVideoAnimation) {
      heroVideo = nil
    }
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
private let heroVideoAnimation = Animation.easeInOut(duration: 0.8)
private let heroTextAnimation = Animation.linear(duration: 0.3)
private let heroBaseColor = Color(red: 0.031, green: 0.035, blue: 0.047)

/// The focused Property's promo video, over the background image.
///
/// The player is only faded in once its item can actually play: an `AVPlayerViewController`
/// renders black until it has frames, so fading it in from the moment it's mounted would
/// cross the background image through black on its way to the video.
private struct HeroVideo: View {
  var item: AVPlayerItem
  /// Raised as this fades in, and lowered by `onDisappear` - which lands after the removal
  /// transition, so the flag outlives the fade out rather than dropping as it starts.
  @Binding var visible: Bool
  @State private var ready = false

  var body: some View {
    LoopingVideoPlayer([item], endAction: .loop)
      .edgesIgnoringSafeArea(.all)
      .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
      .opacity(ready ? 1 : 0)
      .animation(heroVideoAnimation, value: ready)
      .onDisappear { visible = false }
      .task {
        // Poll rather than observe: `status` is KVO-observable, but it changes exactly once
        // here, and Combine's `publisher(for:).values` drops a change that lands while its
        // async iterator has no outstanding demand - which held the player at opacity 0
        // forever. Cancelled with the view when focus moves on.
        while item.status == .unknown {
          if Task.isCancelled { return }
          try? await Task.sleep(for: .milliseconds(100))
        }
        // A failed item never gets frames, so leave it hidden and let the image stand.
        if item.status == .readyToPlay {
          ready = true
          visible = true
        }
      }
  }
}

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
    ZStack(alignment: .leading) {
      if let logo = (property?.tv_header_logo ?? property?.header_logo)?.url?.nilIfEmpty() {
        ScaledWebImage(url: logo, height: logoHeight)
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else if let property {
        Text(property.displayName)
          .font(.system(size: 48, weight: .bold))
          .foregroundColor(Color(white: 0.96))
      }
    }
    .frame(maxWidth: logoMaxWidth, maxHeight: .infinity, alignment: .leading)
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: logoHeight)
    .id(property?.id ?? "")
    .transition(.opacity)
  }
}

/// The focused Property's Discover-page description. Always reserves its full height, whether
/// or not the Property defines one, so the rows below never move as focus changes.
private struct PropertyText: View {
  var property: MediaProperty?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // An empty string gets no line box, so `reservesSpace` would reserve nothing and the
      // rows below would move. A space keeps the block the same height for every Property.
      Text(property?.main_page_description?.nilIfEmpty() ?? " ")
        .font(.propertyDescription)
        .lineLimit(3, reservesSpace: true)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: 800, alignment: .topLeading)
    .padding(.top, 55)
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
