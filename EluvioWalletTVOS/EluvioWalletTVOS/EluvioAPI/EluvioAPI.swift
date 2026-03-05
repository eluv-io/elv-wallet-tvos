//
//  EluvioAPI.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-23.
//

import Combine
import CryptoKit
import Foundation
import SwiftUI
import SwiftyJSON

class EluvioAPI: ObservableObject {
  static let shared = EluvioAPI()

  @Published var accountManager: AccountManager = .init()
  @Published var fabric: Fabric = .init()
  @Published var viewState: ViewState
  weak var router: Router?
  @Published var refreshId = UUID().uuidString
  @Published var forceNetworkRefresh = false
  @Published var devMode: Bool = false
  // Requested token expiration during for login.
  @Published var ttlHours: Double = 336
  static var NONCE: String {
    UIDevice.current.identifierForVendor!.uuidString
  }

  static var NONCE_HASHED: String {
    let hashedData = SHA512.hash(data: NONCE.data(using: .utf8)!)
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
  }

  private var cancellables: Set<AnyCancellable> = []

  init() {
    debugPrint("Initiating Eluvio APIs on ", UIDevice.current.localizedModel)

    debugPrint("NONCE: ", EluvioAPI.NONCE)
    debugPrint("NONCE_HASHED: ", EluvioAPI.NONCE_HASHED)

    accountManager = .init()
    // Use MockFabric for UI testing, real Fabric otherwise
    fabric = MockData.isEnabled ? MockFabric() : Fabric()
    viewState = .init()

    devMode = UserDefaults.standard.bool(forKey: "api_devmode")

    Publishers.MergeMany(
      accountManager.objectWillChange,
      fabric.objectWillChange,
      viewState.objectWillChange
    )
    .sink(receiveValue: {
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    })
    .store(in: &cancellables)

    // New stuff - no DI for now, just singletons
    _ = NetworkStore.shared  // trigger init - this is needed for other Stores to work
    _ = FabricConfigStore.shared
    _ = AccountStore.shared
    _ = PropertyStore.shared

    initMocks()
  }

  // Setup mocking if needed for UI testing
  private func initMocks() {
    let isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    let isMockLoggedIn = ProcessInfo.processInfo.arguments.contains("MOCK_LOGGED_IN")
    let isForceLoggedOut = ProcessInfo.processInfo.arguments.contains("FORCE_LOGGED_OUT")
    // Force logged out state for UI testing
    if isUITesting && isForceLoggedOut {
      print("UI Testing with forced logout")
      accountManager.signOut()
    }
    // Set up mock account for UI testing if needed
    else if isUITesting && isMockLoggedIn {
      print("UI Testing with mock login enabled")
      let mockAccount = Account()
      mockAccount.type = .Ory
      mockAccount.login = LoginResponse(addr: "0x0000000000000000000000000000000000000000")
      accountManager.currentAccount = mockAccount
    }
  }

  func isCustomApp() -> Bool {
    if let props = APP_CONFIG.allowed_properties {
      if !props.isEmpty {
        return true
      }
    }

    return false
  }

  @MainActor
  func needsRefresh() {
    debugPrint("EluvioAPI needs refresh")
    refreshId = UUID().uuidString
  }

  @MainActor
  func setEnvironment(env: APIEnvironment) {
    UserDefaults.standard.set(env.rawValue, forKey: "api_environment")
    NetworkStore.shared.environment = env
    forceNetworkRefresh = true
    needsRefresh()
  }

  @MainActor
  func setDevMode(devMode: Bool) {
    UserDefaults.standard.set(devMode, forKey: "api_devmode")
    self.devMode = devMode
    needsRefresh()
  }

  func getDevMode() -> Bool {
    return devMode
  }

  func isDebugNode() -> Bool {
    return fabric.isDebugNode
  }

  func setIsDebugNode(debugNode: Bool) {
    fabric.isDebugNode = debugNode
  }

  func setTtlHours(_ hours: Double) {
    ttlHours = hours
  }

  func getTtlHours() -> Double {
    return ttlHours
  }

  func signIn(account: Account, property: String) async throws {
    await signOut()
    accountManager.currentAccount = account
    try await fabric.connect()
  }

  @MainActor
  func signOut() async {
    accountManager.signOut()
    await fabric.reset()
    setEnvironment(env: .prod)
  }

  /// TODO:
  func handleApiError(code: Int, response: JSON, error: Error) {
    print("handleApiError ", error)
    print("response ", response)
    print("code \(code)")

    if code == 401 {
      return
    }

    if code >= 400, code < 500 {
      return
    }

    print("Response ", response)
    let errors = response["errors"].arrayValue
    print("Response ", errors)
    if errors.isEmpty {
      print("errors field is empty")
      return
    } else if errors[0]["cause"]["reason"].stringValue.contains("token expired") {
      return
    } else if errors[0]["reason"].stringValue.contains("token expired") {
      return
    } else {
      print("Couldn't parse errors")
      return
    }
  }

  func createWalletAuthorization() -> String {
    do {
      if let account = accountManager.currentAccount {
        return try createWalletAuthorizationFromAccount(account: account)
      }
    } catch {
      print("Error creating wallet authorization", error.localizedDescription)
    }

    return ""
  }

  func createWalletAuthorizationFromAccount(account: Account) throws -> String {
    let address = account.getAccountAddress()
    let provider =
      switch account.type {
      case .Auth0(let domain):
        "auth0"
      case .Ory:
        "ory"
      }

    return try fabric.createWalletAuthorization(
      address: address,
      email: account.email,
      expiresAt: account.expiresAt,
      clusterToken: account.clusterToken,
      fabricToken: account.fabricToken,
      provider: provider
    )
  }

  func refreshFabricToken() async {
    if let account = accountManager.currentAccount {
      if account.refreshToken == "" {
        return
      }

      do {
        let response = try await fabric.refreshFabricToken(
          fabricToken: account.fabricToken,
          refreshToken: account.refreshToken,
          nonce: EluvioAPI.NONCE
        )

        if response["error"].stringValue != "" {
          throw FabricError.badInput(response["error"].stringValue)
        }

        let fabricToken = response["token"].stringValue
        let refreshToken = response["refresh_token"].stringValue
        let expiresAt = response["expires_at"].int64Value

        if fabricToken.isEmpty || refreshToken.isEmpty || expiresAt == 0 {
          throw FabricError.badInput(response["error"].stringValue)
        }

        account.fabricToken = fabricToken
        account.refreshToken = refreshToken
        account.expiresAt = expiresAt
        // debugPrint("Got new token ", account.fabricToken)
        // debugPrint("Got new refresh token ", account.fabricToken)
        debugPrint("expires at ", account.expiresAt)
        accountManager.currentAccount = account
        await needsRefresh()
        return
      } catch let FabricError.apiError(code, response, error) {
        handleApiError(code: code, response: response, error: error)
        if code == 401 || code == 403 {
          await signOut()
          router?.path.removeAll()
        }
        return
      } catch {
        print("Problem refreshing token ", error)
        await signOut()
        router?.path.removeAll()
        return
      }
    }
  }
}
