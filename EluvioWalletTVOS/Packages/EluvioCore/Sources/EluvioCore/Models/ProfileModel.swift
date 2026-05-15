//
//  ProfileModel.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-10-10.
//

import Foundation
import SwiftUI

public struct ProfileModel: Identifiable, Codable {
  public var id = ""
  public var display_name = ""
  public var description = ""
  public var address = ""
  public var image = ""
  public var followers = ""
  public var following = ""
  public var num_sold = ""
  public var tokens = ""
  public var marketplaces: [MarketplaceViewModel]
}
