//
//  AccountManager.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-17.
//

import Foundation

enum AccountType {
    case Auth0, Ory, SSO
}

struct Account {
    var type: AccountType = .Auth0
    var fabricToken: String = ""
    var profile: Profile = Profile()
}

typealias PropertyID = String
typealias PropertyIDAccountDict = [PropertyID:Account]
struct AccountManager {
    var accounts: [AccountType: PropertyIDAccountDict]
}
