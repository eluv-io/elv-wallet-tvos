//
//  NFTView.swift
//  NFTView
//
//  Created by Wayne Tran on 2021-08-11.

import SwiftUI

struct NFTView: View {
  @EnvironmentObject var router: Router
  var nft: NFTModel = .init()
  var isForsale = false
  @State private var buttonFocus: Bool = false
  @FocusState var isFocused
  var display: MediaDisplay = .feature
  var shadowRadius: CGFloat {
    if isFocused {
      return 10
    } else {
      return 3
    }
  }

  var titleColor: Color {
    if isFocused {
      return Color.black
    } else {
      return Color.white
    }
  }

  var subTitleColor: Color {
    if isFocused {
      return Color.black.opacity(0.5)
    } else {
      return Color.gray
    }
  }

  var image: String {
    nft.meta.image ?? ""
  }

  var title: String {
    nft.meta.displayName ?? ""
  }

  var subtitle: String {
    nft.meta.editionName ?? ""
  }

  var propertyLogo: String {
    nft.property?.logo ?? ""
  }

  var propertyName: String {
    nft.property?.title ?? ""
  }

  var tokenId: String {
    "#" + (nft.token_id_str ?? "")
  }

  var tokenDisplay: String {
    if tokenId.isEmpty {
      return ""
    }

    if tokenId.hasPrefix("#") {
      return tokenId
    }

    return "#\(tokenId)"
  }

  var scale: CGFloat = 1.0
  var width: CGFloat {
    return 480 * scale
  }

  var height: CGFloat {
    return 660 * scale
  }

  var logoBrightness: CGFloat {
    if isFocused {
      return -0.5
    } else {
      return 0
    }
  }

  var body: some View {
    Button(action: {
      router.path.append(.nft(nft))
    }) {
      ZStack {
        Image("dark-item-top-radial").resizable()
          .overlay {
            if isFocused {
              Image("item-highlight").resizable()
            }
          }
        VStack {
          HStack(alignment: .center, spacing: 10) {
            if propertyLogo.hasPrefix("http") {
              ScaledWebImage(url: propertyLogo, height: 40)
                .resizable()
                .indicator(.activity)  // Activity Indicator
                .transition(.fade(duration: 0.5))
                .scaledToFill()
                .cornerRadius(3)
                .frame(width: 40, height: 40, alignment: .center)
                .clipped()
                .brightness(logoBrightness)
            } else if propertyLogo != "" {
              Image(propertyLogo)
                .resizable()
                .scaledToFill()
                .cornerRadius(3)
                .frame(width: 40, height: 40, alignment: .center)
                .clipped()
                .brightness(logoBrightness)
            }

            Text(propertyName).foregroundColor(subTitleColor).font(.itemSubtitle)
            Spacer()
            Text(tokenDisplay).foregroundColor(subTitleColor).font(.itemSubtitle)
          }
          .padding(.bottom)
          if image.hasPrefix("http") {
            ScaledWebImage(url: propertyLogo, height: 420)
              .resizable()
              .indicator(.activity)  // Activity Indicator
              .transition(.fade(duration: 0.5))
              .scaledToFill()
              .cornerRadius(3)
              .frame(width: 420, height: 420, alignment: .center)
              .clipped()
          } else {
            Image(image)
              .resizable()
              .scaledToFill()
              .cornerRadius(3)
              .frame(width: 420, height: 420, alignment: .center)
              .clipped()
          }

          VStack(alignment: .center, spacing: 7) {
            Spacer()
            Text(title)
              .foregroundColor(titleColor)
              .font(.itemTitle)
            Text(subtitle)
              .foregroundColor(subTitleColor)
              .font(.itemSubtitle)
              .textCase(.uppercase)

            Spacer()
          }

          if isFocused {}
        }
        .padding(30)
      }
      .shadow(radius: shadowRadius)
    }
    .scaleEffect(scale)
    .frame(width: width, height: height)
    .buttonStyle(TitleButtonStyle(focused: isFocused))
    .focused($isFocused)
  }
}

// MARK: - SwiftUI Previews

#Preview("NFT View") {
  NFTView(nft: NFTModel())
    .environmentObject(EluvioAPI())
    .padding()
    .background(Color.black)
}

#Preview("NFT View - Scaled") {
  NFTView(nft: NFTModel(), scale: 0.7)
    .environmentObject(EluvioAPI())
    .padding()
    .background(Color.black)
}
