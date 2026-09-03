//
//  MediaView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-18.
//

import AVKit
import EluvioCore
import Foundation
import SwiftUI
import SwiftyJSON

/// Card size for a section row, set on `section.display.card_size` and applied
/// to every card in that row. The actual dimensions are resolved by
/// `MediaCard.sizes()` from this plus the card's aspect ratio. Defaults to `.medium`.
enum CardSize: String {
  case extraSmall = "extra_small"
  case small, medium, large
  case extraLarge = "extra_large"

  init(_ raw: String?) {
    self = raw.flatMap { CardSize(rawValue: $0.lowercased()) } ?? .medium
  }
}

enum MediaFlagPosition {
  case bottomRight
  case bottomCenter
}

// TODO: Make this generic
struct RedeemFlag: View {
  @State var redeemable: RedeemableViewModel
  @State var position: MediaFlagPosition = .bottomCenter

  private var padding: CGFloat {
    return 20
  }

  private var text: String {
    if let addr = AccountStore.shared.account?.getAccountAddress() {
      return redeemable.displayLabel(currentUserAddress: addr)
    }

    return ""
  }

  private var textColor: Color {
    return Color.black
  }

  private var bgColor: Color {
    return Color(red: 255 / 255, green: 215 / 255, blue: 0 / 255)
  }

  var body: some View {
    VStack {
      Spacer()
      if position == .bottomCenter {
        Text(text)
          .font(.custom("HelveticaNeue", size: 21))
          .multilineTextAlignment(.center)
          .foregroundColor(textColor)
          .padding(3)
          .padding(.leading, 7)
          .padding(.trailing, 7)
          .background(RoundedRectangle(cornerRadius: 5).fill(bgColor))
      } else {
        HStack {
          Spacer()
          Text(text)
            .font(.custom("Helvetica Neue", size: 21))
            .multilineTextAlignment(.center)
            .foregroundColor(textColor)
            .padding(3)
            .padding(.leading, 7)
            .padding(.trailing, 7)
            .background(RoundedRectangle(cornerRadius: 5).fill(bgColor))
        }
      }
    }
    // .frame(maxWidth:.infinity, maxHeight: .infinity)
    .padding(padding)
  }
}

struct RedeemableCardView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  var redeemable: RedeemableViewModel
  @FocusState var isFocused
  var aspectRatio: AspectRatio = .square
  @State var showOfferView: Bool = false
  @State var playerItem: AVPlayerItem?
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Button(action: {
        self.showOfferView = true
      }) {
        ZStack {
          MediaCard(
            aspectRatio: aspectRatio,
            image: aspectRatio == .portrait ? redeemable.posterUrl : redeemable.imageUrl,
            playerItem: playerItem,
            isFocused: isFocused,
            title: redeemable.name,
            centerFocusedText: true)
          RedeemFlag(redeemable: redeemable)
        }
      }
      .buttonStyle(TitleButtonStyle(focused: isFocused))
      .focused($isFocused)
    }
    .onAppear {
      debugPrint("REDEEMABLE ONAPPEAR", redeemable.id)
      Task {
        do {
          if aspectRatio == .square {
            playerItem = try await MakePlayerItemFromLink(
              fabric: eluvio.fabric, link: redeemable.animationLink)
          }
        } catch {
          print("Error creating player item", error)
        }
      }
    }
    .fullScreenCover(isPresented: $showOfferView) {
      OfferView(redeemable: redeemable)
    }
  }
}

struct MediaCard: View {
  var aspectRatio: AspectRatio = .square
  var image: String = ""
  var playerItem: AVPlayerItem? = nil
  var isFocused: Bool = false
  var isUpcoming: Bool = false
  var startTimeString: String = ""
  var title: String = ""
  var subtitle: String = ""
  var timeString: String = ""
  var titleAlignment: Alignment = .leading
  var isLive: Bool = false
  var centerFocusedText: Bool = false
  var showFocusedTitle = true
  var showBottomTitle = true
  var image_ratio: String? = nil  // Square, Wide, Tall or nil
  var progressValue: Double = 0.0

  var cardSize: CardSize = .medium
  var sizeFactor: CGFloat = 1
  var width: CGFloat {
    sizes().width
  }
  var height: CGFloat {
    sizes().height
  }
  var cornerRadius: CGFloat {
    sizes().cornerRadius
  }
  @State private var newItem: Bool = true
  var permission: ResolvedPermission? = nil
  /// Theme resolved for the section this card belongs to. Without one the card
  /// renders exactly as it did before themes existed.
  var cardTheme: CardTheme? = nil
  /// False for finished artwork that already shows its title below the card -
  /// focusing it lifts the dim, but draws nothing over the image.
  var respondToFocus: Bool = true

  /// The card's outline. A theme replaces the default rounded rectangle, and
  /// turns square cards into circles when it asks for it.
  private var cardShape: AnyShape {
    if cardTheme?.isCircular(aspectRatio: aspectRatio) == true {
      return AnyShape(Circle())
    }
    return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
  }

  /// A theme that draws its own border replaces the focus ring with it.
  private var hasThemeBorder: Bool { cardTheme?.hasBorder == true }

  /// True while focus is drawing the title over the card, which makes the copy
  /// underneath a duplicate.
  private var drawsFocusedTitle: Bool { isFocused && respondToFocus && showFocusedTitle }

  private var imageSaturation: Double { cardTheme?.imageSaturation(focused: isFocused) ?? 1 }

  private var hasImage: Bool { playerItem != nil || !image.isEmpty }

  /// Focus lights the card up along its top edge, and darkens the bottom of it,
  /// which is where the focused overlay puts its text. Both cross-fade with the
  /// dim, and draw under the overlay so its text sits on top.
  private var focusTreatment: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: .white.opacity(0.45), location: 0),
          .init(color: .white.opacity(0.16), location: 0.16),
          .init(color: .clear, location: 0.42),
        ],
        startPoint: .top, endPoint: .bottom)

      VStack(spacing: 0) {
        Spacer()
        LinearGradient(
          stops: [
            .init(color: .clear, location: 0),
            .init(color: .black.opacity(0.6), location: 0.62),
            .init(color: .black.opacity(0.92), location: 1),
          ],
          startPoint: .top, endPoint: .bottom)
          .frame(height: height * 0.64)
      }
    }
    .frame(width: width, height: height)
    .clipShape(cardShape)
  }

  /// The theme's background, cross-faded between its unfocused and focused
  /// states so the two don't pop as focus moves along a row.
  @ViewBuilder private var themeBackground: some View {
    let size = CGSize(width: width, height: height)
    ZStack {
      cardTheme?.background(focused: false, size: size)
      cardTheme?.background(focused: true, size: size)
        .opacity(isFocused ? 1 : 0)
    }
    .frame(width: width, height: height)
    .clipShape(cardShape)
    .animation(.easeInOut(duration: MediaCard.themeAnimation), value: isFocused)
  }

  var body: some View {
    VStack(alignment: .leading) {
      ZStack {
        if cardTheme != nil {
          themeBackground
        }
        if playerItem != nil {
          LoopingVideoPlayer([playerItem!], endAction: .loop)
            .frame(width: width, height: height, alignment: .center)
            .clipShape(cardShape)
        } else {
          if image.hasPrefix("http") {
            ScaledWebImage(url: image, height: height)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: width, height: height)
              .clipShape(cardShape)
              .clipped()
              .saturation(imageSaturation)
              .animation(.easeInOut(duration: MediaCard.themeAnimation), value: imageSaturation)
          } else if image != "" {
            Image(image)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: width, height: height)
              .clipShape(cardShape)
              .saturation(imageSaturation)
              .animation(.easeInOut(duration: MediaCard.themeAnimation), value: imageSaturation)
          } else {
            // No image, display like the focused state with a lighter background
            if !isFocused {
              VStack(alignment: .center, spacing: 7) {
                if !centerFocusedText {
                  Spacer()
                }
                if showFocusedTitle {
                  Text(title)
                    .foregroundColor(Color.white)
                    .font(.subheadline)
                    .lineLimit(2)
                }
                Text(subtitle)
                  .font(.small)
                  .foregroundColor(Color.white)
                  .lineLimit(3)
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .padding(20)
              .padding(.bottom, 50)
              .clipShape(cardShape)
              .background(Color.white.opacity(0.1))
              .scaleEffect(sizeFactor)
              .overlay(
                cardShape
                  .stroke(Color.gray, lineWidth: 2)
              )
            }
          }
        }

        if hasImage {
          // Cards sit slightly dimmed until focused, so focus reads as the card
          // lighting up - matching the web's 85% inactive brightness.
          Color.black
            .opacity(isFocused ? 0 : 0.2)
            .frame(width: width, height: height)
            .clipShape(cardShape)
            .animation(.easeInOut(duration: MediaCard.themeAnimation), value: isFocused)
        }

        focusTreatment
          .opacity(isFocused && respondToFocus ? 1 : 0)
          .animation(.easeInOut(duration: MediaCard.themeAnimation), value: isFocused)

        if isFocused && respondToFocus {
          VStack(alignment: .leading, spacing: 7) {
            if !centerFocusedText {
              Spacer()
            }

            if let perm = permission {
              if perm.showAlternatePage || perm.purchaseGate {
                Text("VIEW PURCHASE OPTIONS")
                  .font(.system(size: aspectRatio == .square ? 20 : 26))
                  .foregroundColor(Color.white)
                  .lineLimit(aspectRatio == .square ? 2 : 1)
                  .bold()
                  .frame(maxWidth: .infinity, alignment: titleAlignment)
                Spacer()
              }
            }

            if showFocusedTitle {
              if !timeString.isEmpty {
                Text(timeString)
                  .font(.system(size: 15))
                  .foregroundColor(Color.gray)
                  .frame(maxWidth: .infinity, alignment: titleAlignment)
              }

              if !title.isEmpty {
                Text(title)
                  .font(.system(size: 22))
                  .foregroundColor(Color.white)
                  .lineLimit(1)
                  .bold()
                  .frame(maxWidth: .infinity, alignment: titleAlignment)
              }

              if !subtitle.isEmpty {
                Text(subtitle)
                  .font(.system(size: 19))
                  .foregroundColor(Color.gray)
                  .lineLimit(1)
                  .frame(maxWidth: .infinity, alignment: titleAlignment)
              }
            }

            if progressValue > 0.0 {
              ProgressView(value: progressValue)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: titleAlignment)
                .frame(height: 4)
                .padding(.top, 15)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(20)
          .scaleEffect(sizeFactor)
        }

        if isUpcoming && !isFocused {
          VStack(alignment: .trailing, spacing: 7) {
            Spacer()
            VStack {
              Text("UPCOMING")
                .font(.custom("Helvetica Neue", size: 21))
                .foregroundColor(Color.white)
              Text(startTimeString)
                .font(.custom("Helvetica Neue", size: 21))
                .foregroundColor(Color.white)
            }
            .padding(3)
            .padding(.leading, 7)
            .padding(.trailing, 7)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.6)))
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
          .padding(20)
          .scaleEffect(sizeFactor, anchor: .bottomTrailing)
        } else if isLive && aspectRatio != .portrait {
          VStack {
            Spacer()
            HStack {
              Spacer()
              Text("LIVE")
                .font(.custom("Helvetica Neue", size: 21))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(3)
                .padding(.leading, 7)
                .padding(.trailing, 7)
                .background(RoundedRectangle(cornerRadius: 5).fill(.red))
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(20)
          .scaleEffect(sizeFactor, anchor: .bottomTrailing)
        }

        if isFocused && !hasThemeBorder {
          // Same geometry the ring had when it was an overlay on the focused
          // texts, so it keeps sitting exactly where it always has.
          Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
            .scaleEffect(sizeFactor)
            .overlay(
              cardShape
                .stroke(Color.highlight, lineWidth: 4)
            )
        }

        if let cardTheme, cardTheme.hasBorder {
          cardShape
            .stroke(
              cardTheme.borderColor(focused: isFocused),
              lineWidth: CGFloat(cardTheme.borderWidth) * sizeFactor
            )
            .frame(width: width, height: height)
            .animation(.easeInOut(duration: MediaCard.themeAnimation), value: isFocused)
        }
      }
      if showBottomTitle {
        Text(title)
          .font(.system(size: 22 * sizeFactor))
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: titleAlignment)
          .opacity(drawsFocusedTitle ? 0 : 1)
          .animation(.easeInOut(duration: MediaCard.themeAnimation), value: drawsFocusedTitle)
      }
    }
    .frame(width: width, height: height)
  }

  private func sizes() -> (width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
    // Card height per size; portrait cards get a taller height. From this:
    // square is height×height, landscape widens to 16:9, portrait narrows to 2:3.
    let isPortrait = aspectRatio == .portrait
    var height: CGFloat =
      switch cardSize {
      case .extraSmall: isPortrait ? 296 : 170
      case .small: isPortrait ? 345 : 200
      case .medium: isPortrait ? 396 : 235
      case .large: isPortrait ? 480 : 280
      case .extraLarge: isPortrait ? 578 : 334
      }
    height *= sizeFactor

    let cornerRadius: CGFloat =
      (cardTheme?.borderRadius.cornerRadius ?? (isPortrait ? 3 : 16)) * sizeFactor
    return (
      width: height * aspectRatio.value,
      height: height,
      cornerRadius: cornerRadius
    )
  }

  /// The web cross-fades focus over 0.5s, which drags when moving focus quickly
  /// along a row.
  private static let themeAnimation: TimeInterval = 0.3
}

// MARK: - SwiftUI Previews

#Preview("Video Card") {
  MediaCard(
    aspectRatio: .landscape,
    image: "https://picsum.photos/400/225",
    isFocused: false,
    title: "Sample Video Title",
    subtitle: "Episode 1 - Season 1"
  )
}

#Preview("Video Card Focused") {
  MediaCard(
    aspectRatio: .landscape,
    image: "https://picsum.photos/400/225",
    isFocused: true,
    title: "Sample Video Title",
    subtitle: "Episode 1 - Season 1"
  )
}

#Preview("Square Card") {
  MediaCard(
    aspectRatio: .square,
    image: "https://picsum.photos/300/300",
    isFocused: false,
    title: "Square Content"
  )
}

#Preview("Feature Card") {
  MediaCard(
    aspectRatio: .portrait,
    image: "https://picsum.photos/248/372",
    isFocused: false,
    title: "Feature Film",
    subtitle: "2h 15min"
  )
}

#Preview("Live Badge") {
  MediaCard(
    aspectRatio: .landscape,
    image: "https://picsum.photos/400/225",
    isFocused: false,
    title: "Live Event",
    isLive: true
  )
}

#Preview("Upcoming Badge") {
  MediaCard(
    aspectRatio: .landscape,
    image: "https://picsum.photos/400/225",
    isFocused: false,
    isUpcoming: true,
    startTimeString: "Jan 30, 8:00 PM",
    title: "Upcoming Event"
  )
}

#Preview("With Progress") {
  MediaCard(
    aspectRatio: .landscape,
    image: "https://picsum.photos/400/225",
    isFocused: true,
    title: "Sample Video",
    progressValue: 0.65
  )
}

#Preview("All Card Types") {
  ScrollView(.horizontal) {
    HStack(spacing: 20) {
      VStack {
        MediaCard(aspectRatio: .square, image: "https://picsum.photos/235/235", title: "Square")
        Text("Square")
      }
      VStack {
        MediaCard(aspectRatio: .landscape, image: "https://picsum.photos/400/225", title: "Video")
        Text("Video")
      }
      VStack {
        MediaCard(aspectRatio: .portrait, image: "https://picsum.photos/248/372", title: "Feature")
        Text("Feature")
      }
    }
    .padding()
  }
}
