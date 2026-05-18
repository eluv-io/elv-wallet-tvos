import AVKit
import EluvioCore
import SwiftUI

/// Full-screen video player. Resolves the playout URL via the shared fabric,
/// hands it to SwiftUI's VideoPlayer (AVPlayerViewController), auto-plays.
/// Pushed onto the navigation stack as a destination — swipe from the left
/// edge to go back (iOS-native gesture).
struct MobileVideoPlayerView: View {
  let property: MediaProperty
  let mediaItem: MediaPropertySectionMediaItem

  @State private var player: AVPlayer?
  @State private var loadingError: String?

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if let player {
        VideoPlayer(player: player)
          .ignoresSafeArea()
          .onAppear { player.play() }
          .onDisappear { player.pause() }
      } else if let loadingError {
        VStack(spacing: 12) {
          Image(systemName: "exclamationmark.triangle")
            .font(.largeTitle)
            .foregroundStyle(.yellow)
          Text(loadingError)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
      } else {
        ProgressView()
          .progressViewStyle(.circular)
          .tint(.white)
      }
    }
    // Hide both navigation bar and tab bar for true full-screen. The
    // EdgeSwipeBackEnabler keeps iOS's edge-pan-to-pop gesture alive even
    // though the back chevron is gone (the two are tied together in stock
    // SwiftUI; this UIKit shim decouples them).
    .toolbar(.hidden, for: .navigationBar, .tabBar)
    .background(EdgeSwipeBackEnabler().allowsHitTesting(false))
    .task { await load() }
  }

  private func load() async {
    configureAudioSessionForPlayback()

    let fabric = await EluvioAPI.shared.fabric
    do {
      let optionsJson = try await fabric.getMediaPlayoutOptions(
        propertyId: property.id, mediaId: mediaItem.id
      )
      let item = try await MakePlayerItemFromMediaOptionsJson(
        fabric: fabric,
        optionsJson: optionsJson,
        title: mediaItem.title ?? "",
        description: mediaItem.description ?? "",
        imageThumb: mediaItem.thumbnail()
      )
      player = AVPlayer(playerItem: item)
    } catch {
      print("Video playout failed:", error)
      loadingError = "Couldn't load video."
    }
  }

  /// Tell iOS this app produces audible playback content. Without this,
  /// AVPlayer is muted when the device's silent switch is on.
  private func configureAudioSessionForPlayback() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Audio session config failed:", error)
    }
  }
}

/// Invisible shim that keeps `UINavigationController.interactivePopGestureRecognizer`
/// enabled even when its host view hides the back button. SwiftUI ties the
/// edge-swipe-back gesture to the back chevron's visibility; this lets us go
/// full-screen without losing the gesture.
private struct EdgeSwipeBackEnabler: UIViewControllerRepresentable {
  func makeUIViewController(context _: Context) -> UIViewController { Enabler() }
  func updateUIViewController(_: UIViewController, context _: Context) {}

  private class Enabler: UIViewController, UIGestureRecognizerDelegate {
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      let pop = navigationController?.interactivePopGestureRecognizer
      pop?.delegate = self
      pop?.isEnabled = true
    }

    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
      (navigationController?.viewControllers.count ?? 0) > 1
    }
  }
}
