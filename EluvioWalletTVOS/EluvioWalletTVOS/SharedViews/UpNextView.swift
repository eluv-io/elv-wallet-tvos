//
//  UpNextView.swift
//  EluvioWalletTVOS
//

import EluvioCore
import SwiftUI

/// AVKit gives no access to the player's own buffering spinner, so this matches it by
/// using the same UIKit component at the system's large size, rather than scaling a
/// SwiftUI ProgressView by a number that would drift across devices and OS versions.
struct PlayerLoadingIndicator: UIViewRepresentable {
  func makeUIView(context: Context) -> UIActivityIndicatorView {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.color = .white
    indicator.startAnimating()
    return indicator
  }

  func updateUIView(_ indicator: UIActivityIndicatorView, context: Context) {}
}

/// Takes the card's place while the next item's playout resolves. Focusable so the Back
/// press lands on onExitCommand instead of being at AVKit's discretion.
struct UpNextLoadingView: View {
  var onCancel: () -> Void

  var body: some View {
    ZStack {
      Color.black
      PlayerLoadingIndicator()
    }
    .ignoresSafeArea()
    .focusable()
    .onExitCommand(perform: onCancel)
  }
}

/// Card shown over the player when an item finishes, counting down to the next one.
struct UpNextView: View {
  private enum Field: Hashable {
    case cancel, play
  }

  var item: MediaPropertySectionMediaItem
  var countdownS: Int
  var onCancel: () -> Void
  var onPlay: () -> Void

  @State private var remainingS: Int
  @FocusState private var focused: Field?

  init(
    item: MediaPropertySectionMediaItem, countdownS: Int = 10,
    onCancel: @escaping () -> Void, onPlay: @escaping () -> Void
  ) {
    self.item = item
    self.countdownS = countdownS
    self.onCancel = onCancel
    self.onPlay = onPlay
    _remainingS = State(initialValue: countdownS)
  }

  private var thumbnail: String {
    item.thumbnail_image_landscape?.url ?? item.thumbnail()
  }

  private var title: String {
    item.title ?? ""
  }

  private var subtitle: String {
    if let subtitle = item.subtitle?.nilIfEmpty() {
      return subtitle
    }
    return item.headers?.joined(separator: "   ") ?? ""
  }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      Color.black.opacity(0.4)
        .ignoresSafeArea()

      // Flush against the safe area, which on tvOS already is Apple's overscan margin
      // (60pt top and bottom, 90pt left and right) — the tightest corner it can hug
      // without risking a cut-off on any TV. Only the dim reaches the screen edges.
      card
    }
    .repeatTask {
      try await Task.sleep(for: .seconds(1))
      remainingS -= 1
      if remainingS <= 0 {
        debugPrint("Up next countdown finished")
        onPlay()
        throw "stop loop"
      }
    }
  }

  private var card: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Up Next in \(remainingS)")
        .font(.itemSubtitle)
        .foregroundColor(.white.opacity(0.7))

      HStack(alignment: .center, spacing: 32) {
        ScaledWebImage(url: thumbnail, height: 220)
          .resizable()
          .aspectRatio(16 / 9, contentMode: .fill)
          .frame(width: 390, height: 220)
          .clipShape(RoundedRectangle(cornerRadius: 10))

        VStack(alignment: .leading, spacing: 8) {
          Text(title)
            .font(.itemTitle)
            .foregroundColor(.white)
            .lineLimit(2)

          if !subtitle.isEmpty {
            Text(subtitle)
              .font(.itemSubtitle)
              .foregroundColor(.white.opacity(0.7))
              .lineLimit(1)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      HStack(spacing: 20) {
        Spacer()

        Button(action: onCancel) {
          Text("Cancel")
            .font(.itemSubtitle)
        }
        .buttonStyle(TextButtonStyle(focused: focused == .cancel))
        .focused($focused, equals: .cancel)

        Button(action: onPlay) {
          Text("Play now")
            .font(.itemSubtitle)
        }
        .buttonStyle(
          HeroActionButtonStyle(
            focused: focused == .play,
            // Dimmed while Cancel holds focus, so only the focused button is
            // solid white
            backgroundColor: focused == .play ? .white : .white.opacity(0.25),
            textColor: focused == .play ? .black : .white,
            cornerRadius: 10)
        )
        .focused($focused, equals: .play)
      }
    }
    .padding(40)
    .frame(width: 1000)
    .background(.black.opacity(0.8))
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .defaultFocus($focused, .play)
  }
}
