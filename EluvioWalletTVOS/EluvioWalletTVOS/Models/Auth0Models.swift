//
//  Auth0Models.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-31.
//

import Foundation


struct SignInResponse {
    var accessToken: String
    var tokenType: String
    var idToken: String
    var refreshToken: String
    
    init() {
        accessToken = ""
        tokenType = ""
        idToken = ""
        refreshToken = ""
    }
}
