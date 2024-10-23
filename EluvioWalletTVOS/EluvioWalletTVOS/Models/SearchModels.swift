//
//  SearchModels.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-07-25.
//

import Foundation
import SwiftyJSON

enum FilterStyle: Codable {
    case text, image
}

struct PrimaryFilterViewModel: Identifiable, Codable, Equatable, Hashable  {
    var id: String = ""
    var imageUrl: String = ""
    var secondaryFilters: [SecondaryFilterViewModel] = []
    var attribute: String = ""
    var secondaryAttribute: String = ""
    var secondaryFilterStyle: FilterStyle = .text
    
    static func GetFilterStyle(style:String) -> FilterStyle {
        if style == "image" {
            return .image
        }
        
        return .text
    }
    
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
