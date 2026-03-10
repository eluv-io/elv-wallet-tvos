//
//  AccountManager.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-17.
//

import Base58Swift
import Foundation

enum AccountType: Codable, Equatable {
  case Ory
  case Auth0(domain: String)
}

class Account: Identifiable, Codable {
  var id: String {
    getAccountId() ?? UUID().uuidString
  }

  var type: AccountType = .Ory
  var clusterToken: String? = nil
  var fabricToken: String = ""
  var refreshToken: String? = nil
  var addr: String? = nil
  var signInResponse: SignInResponse? = nil
  var expiresAt: Int64 = 0
  var email: String? = nil
  var profile: ProfileData = .init()

  init() {}

  // Backwards compatibility: old accounts stored address inside a "login" object
  private enum CodingKeys: String, CodingKey {
    case type, clusterToken, fabricToken, refreshToken, addr, signInResponse, expiresAt, email,
      profile, login
  }

  // The custom encode / decode is only required for backward compat.
  // We'll be able to remove this in the future when we're confident no existing clients use the old 'login' field.
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decodeIfPresent(AccountType.self, forKey: .type) ?? .Ory
    clusterToken = try container.decodeIfPresent(String.self, forKey: .clusterToken)
    fabricToken = try container.decodeIfPresent(String.self, forKey: .fabricToken) ?? ""
    refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
    addr = try container.decodeIfPresent(String.self, forKey: .addr)
    signInResponse = try container.decodeIfPresent(SignInResponse.self, forKey: .signInResponse)
    expiresAt = try container.decodeIfPresent(Int64.self, forKey: .expiresAt) ?? 0
    email = try container.decodeIfPresent(String.self, forKey: .email)
    profile = try container.decodeIfPresent(ProfileData.self, forKey: .profile) ?? .init()

    if addr == nil, let login = try container.decodeIfPresent([String: String].self, forKey: .login)
    {
      addr = login["addr"]
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(type, forKey: .type)
    try container.encodeIfPresent(clusterToken, forKey: .clusterToken)
    try container.encode(fabricToken, forKey: .fabricToken)
    try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
    try container.encodeIfPresent(addr, forKey: .addr)
    try container.encodeIfPresent(signInResponse, forKey: .signInResponse)
    try container.encode(expiresAt, forKey: .expiresAt)
    try container.encodeIfPresent(email, forKey: .email)
    try container.encode(profile, forKey: .profile)
  }

  func getAccountId() -> String? {
    guard let address = addr else { return nil }
    guard let bytes = HexToBytes(address) else { return nil }
    let encoded = Base58.base58Encode(bytes)
    return "iusr\(encoded)"
  }

  func getAccountAddress() -> String {
    guard let address = addr else {
      return ""
    }

    return FormatAddress(address: address)
  }

  func isTokenExpiredIn(seconds: Int) -> Bool {
    if expiresAt == 0 {
      return false
    }
    let now = Int64(Date().timeIntervalSince1970)

    debugPrint("NOW DATE \(Date(timeIntervalSince1970: Double(now)))")
    let tokenIn = Int64(expiresAt / 1000) - Int64(seconds)
    debugPrint("tokenIn DATE \(Date(timeIntervalSince1970: Double(tokenIn)))")

    debugPrint("Now \(now), tokenIn \(tokenIn)")
    return now > tokenIn
  }

  fileprivate var expiresAtDate: Date {
    return Date(timeIntervalSince1970: Double(expiresAt) / 1000)
  }

  var expiresAtDateString: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    dateFormatter.timeZone = TimeZone.current

    return dateFormatter.string(from: expiresAtDate)
  }
}

class AccountManager: ObservableObject {
  @Published
  var currentAccount: Account? = nil {
    didSet {
      saveAccount(currentAccount)
    }
  }

  init() {
    currentAccount = getSavedAccount()
  }

  private func getSavedAccount() -> Account? {
    // We used to save a "type" field, which didn't hold enough data to
    guard let accountData = UserDefaults.standard.object(forKey: "current_account") as? Data else {
      return nil
    }
    guard let account = try? JSONDecoder().decode(Account.self, from: accountData) else {
      return nil
    }
    debugPrint("Retrieved " + account.id)

    // Testing expiration in 3 hours from now
    // account.expiresAt = Int64((Date().timeIntervalSince1970 + 60*60*3) * 1000)
    debugPrint("Now Date \(Date())")
    debugPrint("ExpiresAt Date \(account.expiresAtDate)")
    debugPrint("isTokenExpiredIn \(account.isTokenExpiredIn(seconds: 60 * 60 * 4))")

    return account
  }

  private func saveAccount(_ account: Account?) {
    if account == nil {
      UserDefaults.standard.removeObject(forKey: "current_account")
    } else {
      if let encoded = try? JSONEncoder().encode(account) {
        UserDefaults.standard.set(encoded, forKey: "current_account")
      }
    }
  }

  var isLoggedOut: Bool {
    return currentAccount == nil
  }

  func signOut() {
    currentAccount = nil
  }
}
