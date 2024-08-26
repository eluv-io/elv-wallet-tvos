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

class Account: Identifiable {
    var id: String? {
        address
    }
    var address: String?
    var type: AccountType = .Auth0
    var fabricToken: String = ""
    var profile: Profile = Profile()
    var login :  LoginResponse? = nil
    var signInResponse: SignInResponse? = nil
    var isLoggedOut = true
    
    func signOut() {
        isLoggedOut = true
        login = nil
    }
}

typealias PropertyID = String
typealias PropertyIDAccountDict = [PropertyID:Account]

class AccountManager : ObservableObject {
    var accounts: [AccountType: PropertyIDAccountDict] = [.Auth0:[:],.Ory:[:]]
    var signingIn = false
    func isSignedIn(type: AccountType) -> Bool {
        if let types = accounts[type] {
            return !types.isEmpty
        }
        
        return false
    }
    
    func getAccount(type:AccountType, property: String = "") -> Account? {
        if let type = accounts[type] {
            if let account = type[property] {
                return account
            }
        }
        return nil
    }
    
    func addAccount(account:Account, type:AccountType, property: String = "") throws {
        if var typeAccounts = accounts[type] {
            typeAccounts[property] = account
            accounts[type] = typeAccounts
            return
        }
        
        throw FabricError.configError("Could not add account, type not supported.")
    }
    
    func removeAccount(type:AccountType, property: String = "") {
        if var typeAccounts = accounts[type] {
            typeAccounts[property] = nil
            accounts[type] = typeAccounts
        }
    }
    
}
