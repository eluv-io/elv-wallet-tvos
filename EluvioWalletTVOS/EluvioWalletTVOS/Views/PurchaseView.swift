//
//  PurchaseView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-11-19.
//

import SwiftUI

struct PurchaseView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router
  @State var customDomain: String = "Eluvio Media Wallet"
  @State var shortenedUrl: String = ""

  var url: String = ""
  var backgroundImage: String = ""
  var propertyId: String = ""

  var body: some View {
    ZStack {
      if !backgroundImage.isEmpty {
        ScaledWebImage(url: backgroundImage, height: UIScreen.main)
          .resizable()
          .scaledToFill()
          .edgesIgnoringSafeArea(.all)
          .overlay(Color.black.opacity(0.5))
      }

      VStack(alignment: .center, spacing: 20) {
        Text("Subscribe to Watch").font(.title)
          .padding()
          .padding(.bottom, 20)

        Text(
          "To watch this content, please visit the\nLA Kings All Access site by scanning the QR code below"
        ).font(.description)
          .multilineTextAlignment(.center)
          .padding()
          .padding(.bottom, 20)

        if !shortenedUrl.isEmpty {
          Image(uiImage: GenerateQRCode(from: shortenedUrl))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 400, height: 400)
            .padding(.bottom, 20)
        }

        Button(
          action: {
            eluvio.needsRefresh()
            router.navigateBack()
          },
          label: {
            Text("Back")
          })
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .edgesIgnoringSafeArea(.all)
    .background(.thinMaterial)
    .onAppear {
      Task {
        if let property = try await eluvio.fabric.getProperty(property: propertyId) {
          debugPrint("Domain: \(property.domain)")
          if let domain = property.domain?["custom_domain"].stringValue {
            debugPrint("custom domain: \(domain)")
            if !domain.isEmpty {
              self.customDomain = domain
            }
          }
        }
      }
      if !url.isEmpty {
        Task {
          self.shortenedUrl = await UrlShortener.shortenUrl(url)
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

private struct PurchaseViewPreview: View {
  var body: some View {
    ZStack {
      Color.black.edgesIgnoringSafeArea(.all)

      VStack(alignment: .center, spacing: 20) {
        Text("Sign In On Browser to Purchase").font(.title)
          .padding()
          .padding(.bottom, 20)

        Text(
          "To watch this content, visit the Eluvio Media Wallet\nwebsite on your mobile device or computer to\nadd the corresponding access pass."
        ).font(.system(size: 40))
          .multilineTextAlignment(.center)
          .padding()
          .padding(.bottom, 20)

        Button(
          action: {},
          label: {
            Text("Back")
          })
      }
      .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}

#Preview("Purchase View") {
  PurchaseViewPreview()
}
