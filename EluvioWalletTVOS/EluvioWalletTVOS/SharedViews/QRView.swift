//
//  QRView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import SwiftUI
import SwiftyJSON

/// QR Code display view - shows a QR code with title and description
/// Can be initialized with all state (for previews) or with EluvioAPI (for runtime)
struct QRView: View {
  @EnvironmentObject var router: Router

  // Primary data - can be passed directly for previews
  var url: String
  var backgroundImage: String = ""
  @State var shortenedUrl: String = ""
  @State var title: String = ""
  @State var description: String = ""

  /// Optional callback for custom back action (useful for previews)
  var onBack: (() -> Void)?

  var cleanUrl: String {
    return shortenedUrl.replaceFirst(of: "https://", with: "")
      .replaceFirst(of: "http://", with: "")
  }

  /// Initializer with all parameters - useful for previews
  init(
    url: String,
    backgroundImage: String = "",
    shortenedUrl: String = "",
    title: String = "",
    description: String = "",
    onBack: (() -> Void)? = nil
  ) {
    self.url = url
    self.backgroundImage = backgroundImage
    _shortenedUrl = State(initialValue: shortenedUrl)
    _title = State(initialValue: title)
    _description = State(initialValue: description)
    self.onBack = onBack
  }

  var body: some View {
    ZStack {
      if !backgroundImage.isEmpty {
        ScaledWebImage(url: backgroundImage, height: UIScreen.main)
          .resizable()
          .scaledToFill()
          .edgesIgnoringSafeArea(.all)
      }

      VStack(alignment: .center, spacing: 20) {
        Text(title).font(.title)
          .multilineTextAlignment(.center)
          .padding()
          .frame(minWidth: 1000)
          .frame(maxWidth: 1600)
        if !description.isEmpty {
          Text(description).font(.description)
            .multilineTextAlignment(.center)
            .padding()
            .frame(minWidth: 1000)
            .frame(maxWidth: 1600)
        }

        HStack {
          if !shortenedUrl.isEmpty {
            VStack(alignment: .center, spacing: 40) {
              Text("or visit \(cleanUrl)").font(.description)
              Image(uiImage: GenerateQRCode(from: shortenedUrl))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 400)
            }
          } else {
            Rectangle()
              .foregroundColor(.clear)
              .frame(width: 400, height: 400)
          }
        }
        .padding(.bottom, 40)

        Button(
          action: {
            if let customBack = onBack {
              customBack()
            } else {
              router.navigateBack()
            }
          },
          label: {
            Text("Back")
          })
      }
      .frame(minWidth: 1000)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .edgesIgnoringSafeArea(.all)
    .background(
      .thinMaterial
    )
    .onAppear {
      debugPrint("QRView URL \(url)")
      if title.isEmpty {
        title = "Point your camera to the QR Code below for content"
      }
      // Only fetch shortened URL if not already set (allows preview to work)
      if shortenedUrl.isEmpty {
        Task {
          self.shortenedUrl = await UrlShortener.shortenUrl(url)
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("QR View - Basic") {
  QRView(
    url: "https://example.com/sample-content",
    shortenedUrl: "https://elv.io/abc123",
    title: "Scan QR Code",
    description: "Access exclusive content",
    onBack: {}
  )
  .environmentObject(EluvioAPI())
}

#Preview("QR View - With Background") {
  QRView(
    url: "https://example.com/sample-content",
    backgroundImage: "https://picsum.photos/1920/1080",
    shortenedUrl: "https://elv.io/abc123",
    title: "Point your camera to the QR Code below",
    description: "Complete your purchase on your mobile device",
    onBack: {}
  )
  .environmentObject(EluvioAPI())
}
