//
//  Auth0Models.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-31.
//

import Foundation

public struct SignInResponse: Codable {
  public var accessToken: String
  public var tokenType: String
  public var idToken: String
  public var refreshToken: String

  public init() {
    accessToken = ""
    tokenType = ""
    idToken = ""
    refreshToken = ""
  }
}
