//
//  SearchModels.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-07-25.
//

import Foundation
import SwiftyJSON

public enum FilterStyle: Codable {
  case text, image
}

public struct PrimaryFilterViewModel: Identifiable, Codable, Equatable, Hashable {
  public var id: String = ""
  public var imageUrl: String = ""
  public var secondaryFilters: [SecondaryFilterViewModel] = []
  public var attribute: String = ""
  public var secondaryAttribute: String = ""
  public var secondaryFilterStyle: FilterStyle = .text

  public init(
    id: String = "",
    imageUrl: String = "",
    secondaryFilters: [SecondaryFilterViewModel] = [],
    attribute: String = "",
    secondaryAttribute: String = "",
    secondaryFilterStyle: FilterStyle = .text
  ) {
    self.id = id
    self.imageUrl = imageUrl
    self.secondaryFilters = secondaryFilters
    self.attribute = attribute
    self.secondaryAttribute = secondaryAttribute
    self.secondaryFilterStyle = secondaryFilterStyle
  }

  public static func GetFilterStyle(style: String) -> FilterStyle {
    if style == "image" {
      return .image
    }

    return .text
  }

  public var title: String {
    if id.isEmpty {
      return "All"
    }

    return id
  }

  public static func == (lhs: PrimaryFilterViewModel, rhs: PrimaryFilterViewModel) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

public struct SecondaryFilterViewModel: Identifiable, Codable, Equatable, Hashable {
  public var id: String = ""
  public var imageUrl: String = ""

  public init(id: String = "", imageUrl: String = "") {
    self.id = id
    self.imageUrl = imageUrl
  }

  public var title: String {
    if id.isEmpty {
      return "All"
    }

    return id
  }

  public static func == (lhs: SecondaryFilterViewModel, rhs: SecondaryFilterViewModel) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
