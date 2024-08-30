//
//  AccountManager.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-17.
//

import Foundation
import Base58Swift

enum AccountType {
    case Auth0, Ory, SSO, DEBUG
}

class Account: Identifiable {
    var id: String? {
        let id = getAccountId()
        if id.isEmpty {
            return UUID().uuidString
        }
        
        return id
    }
    var type: AccountType = .Auth0
    var fabricToken: String = ""
    var profile: Profile = Profile()
    var login :  LoginResponse? = nil
    var signInResponse: SignInResponse? = nil
    var isLoggedOut = true
    
    func getAccountId() -> String {
        guard let address = self.login?.addr else
        {
            return ""
        }
        
        guard let bytes = HexToBytes(address) else {
            return ""
        }
        
        let encoded = Base58.base58Encode(bytes)
        
        return "iusr\(encoded)"
    }
    
    func getAccountAddress() -> String {
        guard let address = self.login?.addr else
        {
            return ""
        }
        
        return FormatAddress(address: address)
    }
    
    func signOut() {
        isLoggedOut = true
        login = nil
    }
}

typealias PropertyID = String
typealias PropertyIDAccountDict = [PropertyID:Account]

class AccountManager : ObservableObject {
    var accounts: [AccountType: PropertyIDAccountDict] = [.Auth0:[:],.Ory:[:]]
    @Published
    var currentAccount : Account? = nil
    
    var signingIn = false
    
    init(){
        /*
       let account = Account ()
        account.fabricToken = "acssjcE6QchywYvWdz2tonMozuroKLfT1pN7346dHxsE13KTJE3BoM451LDgbMaCL95AmVtHLoppHHQZhsy2RTxnbLKVHFSGthkGBXdwAX4J53sWVEJVUnf4VcPgXfAUPGDZLXoU7tCeWrR8cgQruxdCUywJsBXML1s5JYX9yzNXo6S9bhHkeJXaH4Pu35EZttK2DJQVonmuVjEJ85XmsVkbv2DjFE4KVYpwjRSaULSCheUut4jiYUTTofyrY14XnzrPNghXYfDo16ManDpPsY5rpeJZnAgZSfsyWgid9CGfbdq8BqxAubWTUZ5UQ9wGwW3f7o8r1to9tR8dhFfDXu9Yp2rg8G4hNPYxn"
        account.type = .DEBUG
        currentAccount = account
         */
    }
    
    var isLoggedOut : Bool {
        if currentAccount == nil{
            return true
        }
        
        return false
    }
    
    func signOut() {
        currentAccount = nil
        accounts = [.Auth0:[:],.Ory:[:]]
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "id_token")
        UserDefaults.standard.removeObject(forKey: "token_type")
    }
    
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
    
    func getPropertyAccount(property:String) -> Account? {
        //If we've set a debug account, use it!
        if let account = currentAccount {
            if account.type == .DEBUG {
                return account
            }
        }
        
        if let account = getAccount(type:.Auth0, property:property) {
            return account
        }
        
        if let account = getAccount(type:.Ory, property:property) {
            return account
        }
        
        if let account = getAccount(type:.SSO, property:property) {
            return account
        }
        
        return nil
    }
    
    func setCurrentAccount(account:Account) {
        currentAccount = account
    }
    
    func addAndSetCurrentAccount(account:Account, type:AccountType, property: String = "") throws {
        try addAccount(account:account, type:type)
        setCurrentAccount(account: account)
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
