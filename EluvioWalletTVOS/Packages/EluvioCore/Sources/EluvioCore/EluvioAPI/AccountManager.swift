//
//  AccountManager.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-17.
//

import Base58Swift
import Foundation

public enum AccountType: Codable, Equatable {
  case Ory
  case Auth0(domain: String)
}

public class Account: Identifiable, Codable {
  public var id: String {
    getAccountId() ?? UUID().uuidString
  }

  public var type: AccountType = .Ory
  public var clusterToken: String? = nil
  public var fabricToken: String = ""
  public var refreshToken: String? = nil
  public var addr: String? = nil
  public var expiresAt: Int64 = 0
  public var email: String? = nil
  public var profile: ProfileData = .init()

  public init() {}

  // Backwards compatibility: old accounts stored address inside a "login" object
  private enum CodingKeys: String, CodingKey {
    case type, clusterToken, fabricToken, refreshToken, addr, expiresAt, email, profile, login
  }

  // The custom encode / decode is only required for backward compat.
  // We'll be able to remove this in the future when we're confident no existing clients use the old 'login' field.
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decodeIfPresent(AccountType.self, forKey: .type) ?? .Ory
    clusterToken = try container.decodeIfPresent(String.self, forKey: .clusterToken)
    fabricToken = try container.decodeIfPresent(String.self, forKey: .fabricToken) ?? ""
    refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
    addr = try container.decodeIfPresent(String.self, forKey: .addr)
    expiresAt = try container.decodeIfPresent(Int64.self, forKey: .expiresAt) ?? 0
    email = try container.decodeIfPresent(String.self, forKey: .email)
    profile = try container.decodeIfPresent(ProfileData.self, forKey: .profile) ?? .init()

    // Backwards compat for old "login" field
    if addr == nil, let login = try container.decodeIfPresent([String: String].self, forKey: .login)
    {
      addr = login["addr"]
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(type, forKey: .type)
    try container.encodeIfPresent(clusterToken, forKey: .clusterToken)
    try container.encode(fabricToken, forKey: .fabricToken)
    try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
    try container.encodeIfPresent(addr, forKey: .addr)
    try container.encode(expiresAt, forKey: .expiresAt)
    try container.encodeIfPresent(email, forKey: .email)
    try container.encode(profile, forKey: .profile)
  }

  public func getAccountId() -> String? {
    guard let address = addr else { return nil }
    guard let bytes = HexToBytes(address) else { return nil }
    let encoded = Base58.base58Encode(bytes)
    return "iusr\(encoded)"
  }

  public func getAccountAddress() -> String {
    guard let address = addr else {
      return ""
    }

    return FormatAddress(address: address)
  }

  public func isTokenExpiredIn(seconds: Int) -> Bool {
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

  private var expiresAtDate: Date {
    return Date(timeIntervalSince1970: Double(expiresAt) / 1000)
  }

  public var expiresAtDateString: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    dateFormatter.timeZone = TimeZone.current

    return dateFormatter.string(from: expiresAtDate)
  }
}

extension Account: Equatable {
  public static func == (lhs: Account, rhs: Account) -> Bool {
    lhs.addr == rhs.addr
      && lhs.type == rhs.type
      && lhs.fabricToken == rhs.fabricToken
      && lhs.refreshToken == rhs.refreshToken
      && lhs.clusterToken == rhs.clusterToken
      && lhs.expiresAt == rhs.expiresAt
      && lhs.email == rhs.email
  }
}
