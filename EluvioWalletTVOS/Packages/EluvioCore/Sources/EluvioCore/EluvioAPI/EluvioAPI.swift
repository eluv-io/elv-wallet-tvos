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

public class EluvioAPI: ObservableObject {
  @MainActor public static let shared = EluvioAPI()

  @Published public var fabric: Fabric = .init()
  @Published public var viewState: ViewState
  @Published public var refreshId = UUID().uuidString
  @Published public var devMode: Bool = false
  public static var NONCE: String {
    UIDevice.current.identifierForVendor!.uuidString
  }

  public static var NONCE_HASHED: String {
    let hashedData = SHA512.hash(data: NONCE.data(using: .utf8)!)
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
  }

  private var cancellables: Set<AnyCancellable> = []

  @MainActor
  public init() {
    debugPrint("Initiating Eluvio APIs on ", UIDevice.current.localizedModel)

    debugPrint("NONCE: ", EluvioAPI.NONCE)
    debugPrint("NONCE_HASHED: ", EluvioAPI.NONCE_HASHED)

    // Use MockFabric for UI testing, real Fabric otherwise
    fabric = MockData.isEnabled ? MockFabric() : Fabric()
    viewState = .init()

    devMode = UserDefaults.standard.bool(forKey: "api_devmode")

    Publishers.MergeMany(
      fabric.objectWillChange,
      viewState.objectWillChange
    )
    .sink(receiveValue: {
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    })
    .store(in: &cancellables)

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
      AccountStore.shared.signOut()
    }
    // Set up mock account for UI testing if needed
    else if isUITesting && isMockLoggedIn {
      print("UI Testing with mock login enabled")
      let mockAccount = Account()
      mockAccount.type = .Ory
      mockAccount.addr = "0x0000000000000000000000000000000000000000"
      AccountStore.shared.account = mockAccount
    }
  }

  public func isCustomApp() -> Bool {
    return APP_CONFIG.allowed_properties?.isEmpty == false
  }

  @MainActor
  public func needsRefresh() {
    debugPrint("EluvioAPI needs refresh")
    refreshId = UUID().uuidString
  }

  @MainActor
  public func setEnvironment(env: APIEnvironment) {
    UserDefaults.standard.set(env.rawValue, forKey: "api_environment")
    NetworkStore.shared.environment = env
    needsRefresh()
  }

  @MainActor
  public func setDevMode(devMode: Bool) {
    UserDefaults.standard.set(devMode, forKey: "api_devmode")
    self.devMode = devMode
    needsRefresh()
  }

  public func getDevMode() -> Bool {
    return devMode
  }

  public func isDebugNode() -> Bool {
    return fabric.isDebugNode
  }

  public func setIsDebugNode(debugNode: Bool) {
    fabric.isDebugNode = debugNode
  }

  /// TODO:
  public func handleApiError(code: Int, response: JSON, error: Error) {
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

  public func createWalletAuthorization() -> String {
    do {
      if let account = AccountStore.shared.account {
        return try createWalletAuthorizationFromAccount(account: account)
      }
    } catch {
      print("Error creating wallet authorization", error.localizedDescription)
    }

    return ""
  }

  public func createWalletAuthorizationFromAccount(account: Account) throws -> String {
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

  public func refreshFabricToken() async {
    await NetworkManager.shared.refreshToken()
  }
}
