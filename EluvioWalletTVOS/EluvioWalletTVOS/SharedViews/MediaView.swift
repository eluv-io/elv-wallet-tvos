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
  case small, medium, large

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

  var body: some View {
    VStack(alignment: .leading) {
      ZStack {
        if playerItem != nil {
          LoopingVideoPlayer([playerItem!], endAction: .loop)
            .frame(width: width, height: height, alignment: .center)
            .cornerRadius(cornerRadius)
        } else {
          if image.hasPrefix("http") {
            ScaledWebImage(url: image, height: height)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: width, height: height)
              .cornerRadius(cornerRadius)
              .clipped()
          } else if image != "" {
            Image(image)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: width, height: height)
              .cornerRadius(cornerRadius)
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
              .cornerRadius(cornerRadius)
              .background(Color.white.opacity(0.1))
              .scaleEffect(sizeFactor)
              .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                  .stroke(Color.gray, lineWidth: 2)
              )
            }
          }
        }

        if isFocused {
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
                  .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
              }
            }

            if showFocusedTitle {
              if !timeString.isEmpty {
                Text(timeString)
                  .font(.system(size: 15))
                  .foregroundColor(Color.gray)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }

              if !title.isEmpty {
                Text(title)
                  .font(.system(size: 22))
                  .foregroundColor(Color.white)
                  .lineLimit(1)
                  .bold()
                  .frame(maxWidth: .infinity, alignment: .leading)
              }

              if !subtitle.isEmpty {
                Text(subtitle)
                  .font(.system(size: 19))
                  .foregroundColor(Color.gray)
                  .lineLimit(1)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }

            if progressValue > 0.0 {
              ProgressView(value: progressValue)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 4)
                .padding(.top, 15)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(20)
          .scaleEffect(sizeFactor)
          .cornerRadius(cornerRadius)
          .background(Color.black.opacity(showFocusedTitle ? 0.8 : 0.1))
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(Color.highlight, lineWidth: 4)
          )
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
      }
      if showBottomTitle {
        Text(title).font(.system(size: 22 * sizeFactor)).lineLimit(1).frame(alignment: .leading)
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
      case .small: isPortrait ? 345 : 200
      case .medium: isPortrait ? 396 : 235
      case .large: isPortrait ? 480 : 280
      }
    height *= sizeFactor

    let cornerRadius: CGFloat = (isPortrait ? 3 : 16) * sizeFactor
    return (
      width: height * aspectRatio.value,
      height: height,
      cornerRadius: cornerRadius
    )
  }
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
