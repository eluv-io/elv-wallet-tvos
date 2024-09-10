//
//  AccountManager.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-17.
//

import Foundation
import Base58Swift

enum AccountType: Codable {
    case Auth0, Ory, SSO, DEBUG
}

class Account: Identifiable, Codable {
    var id: String {
        let _id = getAccountId()
        if _id.isEmpty {
            return UUID().uuidString
        }
        
        return _id
    }
    var type: AccountType = .Auth0
    var fabricToken: String = ""
    var profile: ProfileData = ProfileData()
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
}

typealias PropertyID = String
typealias PropertyIDAccountDict = [PropertyID:Account]

class AccountManager : ObservableObject {
    var accounts: [AccountType: PropertyIDAccountDict] = [.Auth0:[:],.Ory:[:]]
    @Published
    var currentAccount : Account? = nil
    
    var signingIn = false
    
    init(){
        getSavedAccount()
        
/*
       let account = Account ()
        account.fabricToken = "acspjcBzzzk7wijCd6yAz21VGTr86XvtpoLmVGVNpFMDg4yrExvYd8RgNyYnGPXKkTnGiL6MYhLRZgaiC9aKCBN8HYsm2vnQVQgSc5sJyy4hbSb6AWZ3EjhfzGC8t9kNqviy7n6zFF8GWnMsMG14stsdgmurAT4uQoocHjhjkhGAsuVQi32WEcF5pnV3fZsNsxLyNaoyAoQMxXm4ykGU18KCuaBKpPCFMnheF7Um5fp2CGQXqznYBh1d7LQBeVwZnAqq1LqC3WkWbUEG8Rqig5XLpjVwi3iWWGZkaCcwz5xGFHo8gX6mTMTkjc59MDxS"
        account.type = .DEBUG
        account.login = LoginResponse(addr:"0x2cdca879563d986210c2484b7984abcab821fd8c")
        currentAccount = account
        */

    }
    
    func getSavedAccount() {
        if let accountData = UserDefaults.standard.object(forKey: "current_account") as? Data {
            let decoder = JSONDecoder()
            if let account = try? decoder.decode(Account.self, from: accountData) {
                debugPrint("Retrieved "+account.id)
                do {
                    try addAndSetCurrentAccount(account: account, type:account.type)
                }catch{
                    print("Could not add account: ", error.localizedDescription)
                }
            }
        }
    }
    
    func saveCurrentAccount() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(currentAccount) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "current_account")
        }
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
        UserDefaults.standard.removeObject(forKey: "current_account")
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
        saveCurrentAccount()
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
