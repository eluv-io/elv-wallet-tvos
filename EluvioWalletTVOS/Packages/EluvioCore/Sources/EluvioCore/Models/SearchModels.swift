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

/// The Property's own search configuration. The `/filters` endpoint serves a
/// projection of this that leaves the card theme out, so the themes are read
/// from the Property itself.
public struct PropertySearchSettings: Codable {
  /// Points to a theme in the Property's `styling.card_themes`, like a Section's does.
  public var primary_filter_card_theme_id: String?
  public var filter_options: [PropertySearchFilterOption]?
}

/// One primary filter's entry in the Property's search config. A primary filter
/// configures the secondary row shown beneath it, its theme included, so the
/// secondary theme is named per option rather than once for the Property.
public struct PropertySearchFilterOption: Codable {
  public var primary_filter_value: String?
  public var secondary_filter_card_theme_id: String?
}
