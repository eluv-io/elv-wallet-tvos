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
    var login :  LoginResponse? = nil
    var signInResponse: SignInResponse? = nil
}

typealias PropertyID = String
typealias PropertyIDAccountDict = [PropertyID:Account]

class AccountManager : ObservableObject {
    var accounts: [AccountType: PropertyIDAccountDict] = [:]
    var signingIn = false
    var isSignedIn: Bool {
        return !accounts.isEmpty
    }
    
}
