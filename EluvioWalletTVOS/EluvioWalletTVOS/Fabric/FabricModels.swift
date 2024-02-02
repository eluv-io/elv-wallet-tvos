//
//  FabricModels.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-02.
//

import Foundation

struct LoginResponse: Codable {
    var type = ""
    var addr: String
    var eth: String
    var token: String
}

struct MediaProgress: Identifiable, Codable {
    var id: String = ""
    var duration_s: Double = 0.0
    var current_time_s: Double = 0.0
}

struct MediaProgressContainer: Codable {
    var media : [String: MediaProgress] = [:]
}
