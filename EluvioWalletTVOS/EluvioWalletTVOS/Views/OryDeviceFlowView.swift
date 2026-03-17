//
//  OryDeviceFlowView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-24.
//

import Alamofire
import AuthenticationServices
import Combine
import CoreImage.CIFilterBuiltins
import SwiftUI
import SwiftyJSON

struct OryDeviceFlowView: View {
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var router: Router
  @State var url = ""
  @State var statusUrl: String = ""
  @State var timer = Timer.publish(every: 1, on: .main, in: .common)
  @State var timerCancellable: Cancellable? = nil
  @State private var response: ActivationCodeResponse? = nil

  @State var isChecking = false
  var property: MediaProperty

  var logo: String {
    return property.login?.styling?.logo_tv?.url ?? ""
  }

  var backgroundImage: String {
    return property.login?.styling?.background_image_tv?.url
      ?? property.login?.styling?.background_image_desktop?.url
      ?? ""
  }

  var body: some View {
    ZStack {
      Color.mainBackground.edgesIgnoringSafeArea(.all)
      ScaledWebImage(url: backgroundImage, height: UIScreen.main)
        .resizable()
        .scaledToFill()
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .center, spacing: 30) {
        VStack(alignment: .center, spacing: 20) {
          Text("Sign In")
            .font(.title)
            .fontWeight(.semibold)
            .padding()

          Text(response?.id ?? "")
            .font(.custom("Helvetica Neue", size: 50))
            .fontWeight(.semibold)
          if url != "" {
            Image(uiImage: GenerateQRCode(from: url))
              .interpolation(.none)
              .resizable()
              .scaledToFit()
              .frame(width: 400, height: 400)
          } else {
            Rectangle()
              .fill(.clear)
              .frame(width: 400, height: 450)
          }
        }
        .frame(width: 700)

        Spacer()
          .frame(height: 10.0)

        HStack(alignment: .center, spacing: 40) {
          Button(action: {
            Task {
              await self.regenerateCode()
            }
          }) {
            Text("Request New Code")
          }
          Button(action: {
            self.presentationMode.wrappedValue.dismiss()
          }) {
            Text("Back")
          }
        }
        .focusSection()
        .padding(.bottom, 40)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .edgesIgnoringSafeArea(.all)
    .background(.thickMaterial)
    .accessibilityIdentifier("login_view")
    .task {
      debugPrint("OryDeviceFlowView path ", router.path)
      await self.regenerateCode()
    }
    .onReceive(timer) { _ in
      Task {
        await checkDeviceVerification(statusUrl: statusUrl)
      }
    }
  }

  func regenerateCode() async {
    do {
      let nonce = EluvioAPI.NONCE_HASHED

      var url = FabricConfigStore.shared.walletUrl
      url += "/login?pid=\(property.id)"
      url += "&action=login&mode=login&response=code&source=code"
      url += "&installId=\(nonce)&origin=\(UIDevice.current.name)"
      if MockData.testShortTokens {
        url += "&ttl=0.025"  // Time in hours, only for debugging short-lived tokens
      }

      debugPrint("URL Code: ", url)

      let parameters: [String: Any] = ["op": "create", "dest": url]
      let response: ActivationCodeResponse = try await NetworkManager.shared.request(
        "/wlt/login/redirect/metamask", method: .post, parameters: parameters)

      self.response = response

      print("createAuthLogin completed")
      debugPrint("Create response: ", response)

      var _url = response.url
      if !_url.hasPrefix("http") {
        _url = "https://".appending(_url)
      }

      debugPrint("URL: ", self.url)
      self.url = await UrlShortener.shortenUrl(_url)
      debugPrint("Ory shortened URL: ", _url)

      let interval = 5.0
      timer = Timer.publish(every: interval, on: .main, in: .common)
      timerCancellable = timer.connect()

    } catch {
      print("Could not get code for MetaMask login", error)
    }
  }

  func checkDeviceVerification(statusUrl _: String) async {
    print("checkDeviceVerification \(response?.id ?? "nil")")
    guard let response = response else { return }
    if isChecking {
      return
    }
    isChecking = true
    defer {
      self.isChecking = false
    }

    guard let result = await checkAuthLogin(code: response.id, passcode: response.passcode)
    else {
      print("MetaMaskFlowView checkDeviceVerification() checkMetaMaskLogin returned nil")
      return
    }

    debugPrint("Ory Result ", result)

    let refreshToken = result.refreshToken
    debugPrint("Refresh Token ", refreshToken ?? "nil")

    do {
      debugPrint("Ory signing in ")

      let account = Account()
      account.type = property.accountType
      account.addr = result.addr
      account.expiresAt = result.expiresAt ?? Int64.max
      account.email = result.email
      account.fabricToken = result.token
      account.clusterToken = result.clusterToken
      account.refreshToken = refreshToken
      debugPrint("EMAIL: ", account.email ?? "nil")

      AccountStore.shared.account = account

      debugPrint("Starting section prefetch")
      await prefetchPropertyAndSections(property.id)

      debugPrint("Ory Signing in done!")
    } catch {
      print("could not sign in: \(error.localizedDescription)")
    }

    await MainActor.run {
      debugPrint("Sign in finished.")

      router.path.removeAll()
      debugPrint("Popped the path state.")
      let params = PropertyParam(propertyId: property.id)
      router.path.append(.property(params))

      self.isChecking = false
    }

    timerCancellable!.cancel()
  }

  private func prefetchPropertyAndSections(_ propertyId: String) async {
    // Get a new copy of Property. Now that we have an auth token,
    // permissions might different.
    await PropertyStore.shared.fetchProperty(id: propertyId)
    guard let property = PropertyStore.shared.getProperty(id: propertyId) else { return }
    guard let page = try? await PropertyStore.shared.getFirstAuthorizedPage(property: property)
    else { return }
    await PropertyStore.shared.fetchSections(property: property, page: page)
  }
}

// MARK: - SwiftUI Previews

#Preview("Ory Device Flow View") {
  // Disabled for now
  //  OryDeviceFlowView()
  //    .environmentObject(EluvioAPI())
  //    .preferredColorScheme(.dark)
}

/// Pass in the response JSON of createMetaMaskLogin
func checkAuthLogin(code: String, passcode: String) async -> CheckTokenPayload? {
  do {
    let response: CheckTokenResponse = try await NetworkManager.shared.request(
      "wlt/login/redirect/metamask/\(code)/\(passcode)")
    return response.payload
  } catch {
    debugPrint("Token check failed")
    return nil
  }
}
struct ActivationCodeResponse: Codable {
  // This is the "code" visible to the user along with the QR
  var id: String
  // This is a secret identifier sent along with 'id' to check token requests
  var passcode: String
  var url: String
  var expiration: Int64
}

struct CheckTokenResponse: Decodable {
  var payload: CheckTokenPayload
  enum CodingKeys: CodingKey {
    case payload
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let payloadString = try container.decode(String.self, forKey: .payload)
    let payloadData = Data(payloadString.utf8)
    self.payload = try JSONDecoder().decode(CheckTokenPayload.self, from: payloadData)
  }
}

struct CheckTokenPayload: Decodable {
  var token: String
  var expiresAt: Int64?
  var refreshToken: String?
  var addr: String
  var clusterToken: String?
  var email: String?
}
