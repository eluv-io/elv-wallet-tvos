//
//  AudioPageModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-02-05.
//

import Foundation

struct AudioPageModel: Codable {
    var page : Int
    var start : TimeInterval
    var startString : String? = ""
    var startSeconds: TimeInterval {
        return start / 1000.0
    }
}


