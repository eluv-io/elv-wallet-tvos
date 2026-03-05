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
  var clusterToken: String = ""
  var fabricToken: String = ""
  var refreshToken: String = ""
  var login: LoginResponse? = nil
  var signInResponse: SignInResponse? = nil
  var expiresAt: Int64 = 0
  var email = ""
  var profile: ProfileData = .init()

  func getAccountId() -> String? {
    guard let address = login?.addr else { return nil }
    guard let bytes = HexToBytes(address) else { return nil }
    let encoded = Base58.base58Encode(bytes)
    return "iusr\(encoded)"
  }

  func getAccountAddress() -> String {
    guard let address = login?.addr else {
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
