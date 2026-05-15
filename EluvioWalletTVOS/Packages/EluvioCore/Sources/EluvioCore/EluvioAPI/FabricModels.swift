//
//  FabricModels.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-02.
//

import Foundation

public struct MediaProgress: Identifiable, Codable {
  public var id: String = ""
  public var duration_s: Double = 0.0
  public var current_time_s: Double = 0.0

  public init(id: String = "", duration_s: Double = 0.0, current_time_s: Double = 0.0) {
    self.id = id
    self.duration_s = duration_s
    self.current_time_s = current_time_s
  }
}

public struct MediaProgressContainer: Codable {
  public var media: [String: MediaProgress] = [:]

  public init(media: [String: MediaProgress] = [:]) {
    self.media = media
  }
}
