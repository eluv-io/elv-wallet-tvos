//
//  SearchModels.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-07-25.
//

import Foundation
import SwiftyJSON

struct PrimaryFilterViewModel: Identifiable, Codable, Equatable, Hashable  {
    var id: String = ""
    var imageUrl: String = ""
    var secondaryFilters: [SecondaryFilterViewModel] = []
    var attribute: String = ""
    var secondaryAttribute: String = ""
    
    var title: String {
        if id.isEmpty {
            return "All"
        }
        
        return id
    }
    
    static func == (lhs: PrimaryFilterViewModel, rhs: PrimaryFilterViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SecondaryFilterViewModel: Identifiable, Codable, Equatable, Hashable {
    var id: String = ""
    var imageUrl: String = ""
    
    var title: String {
        if id.isEmpty {
            return "All"
        }
        
        return id
    }
    
    static func == (lhs: SecondaryFilterViewModel, rhs: SecondaryFilterViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
