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
import SDWebImageSwiftUI
import SwiftUI
import SwiftyJSON

struct OryDeviceFlowView: View {
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router
  @State var url = ""
  @State var statusUrl: String = ""
  @State var code = ""
  @State var deviceCode = ""
  @State var timer = Timer.publish(every: 1, on: .main, in: .common)
  @State var timerCancellable: Cancellable? = nil
  @State var showError = false
  @State var errorMessage = ""
  @State private var response = JSON()

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
      WebImage(url: URL(string: backgroundImage))
        .resizable()
        .scaledToFill()
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .center, spacing: 30) {
        VStack(alignment: .center, spacing: 20) {
          Text("Sign In")
            .font(.title)
            .fontWeight(.semibold)
            .padding()

          Text(code)
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
    .fullScreenCover(isPresented: $showError) {
      VStack {
        Spacer()
        Text("Error connecting to the Network. Please try again later.")
        Spacer()
      }
      .background(Color.black.opacity(0.8))
      .background(.thickMaterial)
    }
  }

  func regenerateCode() async {
    do {
      let nonce = EluvioAPI.NONCE_HASHED

      var url = FabricConfigStore.shared.walletUrl
      url += "/login?pid=\(property.id)"
      url += "&action=login&mode=login&response=code&source=code"
      url += "&installId=\(nonce)&origin=\(UIDevice.current.name)"
      // url += "&ttl=0.008"  // Time in hours, only for debugging short-lived tokens

      debugPrint("URL Code: ", url)

      let parameters: [String: Any] = ["op": "create", "dest": url]
      let json: JSON = try await NetworkManager.shared.request(
        "/wlt/login/redirect/metamask", method: .post, parameters: parameters)

      response = json

      print("createAuthLogin completed")

      debugPrint("Create response: ", json)

      var _url = json["url"].stringValue
      if !_url.hasPrefix("https"), !_url.hasPrefix("http") {
        _url = "https://".appending(_url)
      }

      debugPrint("URL: ", self.url)
      self.url = await UrlShortener.shortenUrl(_url)
      debugPrint("Ory shortened URL: ", _url)

      code = json["id"].stringValue
      deviceCode = json["passcode"].stringValue

      let interval = 5.0
      timer = Timer.publish(every: interval, on: .main, in: .common)
      timerCancellable = timer.connect()

    } catch {
      print("Could not get code for MetaMask login", error)
    }
  }

  func checkDeviceVerification(statusUrl _: String) async {
    print("checkDeviceVerification \(code)")
    if isChecking {
      return
    }

    isChecking = true

    defer {
      self.isChecking = false
    }

    do {
      guard let result = try await eluvio.fabric.signer?.checkAuthLogin(createResponse: response)
      else {
        print("MetaMaskFlowView checkDeviceVerification() checkMetaMaskLogin returned nil")
        return
      }

      let status = result["status"].intValue

      if status != 200 {
        print("Check value \(result)")
        return
      }
      debugPrint("Ory Result ", result)

      let refreshToken = result["refresh_token"].stringValue
      debugPrint("Refresh Token ", refreshToken)

      let json = JSON(parseJSON: result["payload"].stringValue)

      if json.isEmpty {
        print("MetaMaskFlowView checkDeviceVerification() json payload is empty.")
        showError = true
        return
      }

      let type = json["type"].stringValue
      let token = json["token"].stringValue
      let addr = json["addr"].stringValue
      let eth = json["eth"].stringValue
      let email = json["email"].stringValue
      let expiresAt = json["expiresAt"].int64Value
      let clusterToken = json["clusterToken"].stringValue

      debugPrint("EMAIL: ", email)

      do {
        let login = LoginResponse(type: type, addr: addr, eth: eth, token: token)
        debugPrint("Ory signing in ")

        let account = Account()
        account.type = property.accountType
        account.login = login
        account.expiresAt = expiresAt
        account.email = email
        account.fabricToken = token
        account.clusterToken = clusterToken
        account.refreshToken = refreshToken

        try await eluvio.signIn(account: account, property: property.id)
        // needsRefresh() is now called by signIn's pre-cache Task when auth cache is ready

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
    } catch {
      await MainActor.run {
        print("checkDeviceVerification error", error)
        self.errorMessage = error.localizedDescription
        showError = true
      }
    }
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
