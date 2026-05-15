//
//  Profile.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-06-20.
//

import Foundation

public var DEMO_LOCATIONS: [String]? = ["los angeles", "phoenix", "washington dc"]

public struct ProfileData: Codable, Equatable {
  // DEMO:
  public var locations: [String]? = DEMO_LOCATIONS
  public var preferredLocation: String? = "los angeles"
}

public class Profile: ObservableObject {
  @Published
  public var profileData = ProfileData()

  public func setPreferredLocation(location: String) async throws {
    profileData.preferredLocation = location
    if var locations = profileData.locations {
      if !locations.contains(location) {
        locations.append(location)
        profileData.locations = locations
      }
    } else {
      profileData.locations = DEMO_LOCATIONS
    }

    debugPrint("SetPreferredLocation ", location)

    try await save()
  }

  public func save() async throws {
    let jsonData = try JSONEncoder().encode(profileData)
    let jsonString = String(data: jsonData, encoding: .utf8)!

    debugPrint("Saving settings ", jsonString)

    UserDefaults.standard.set(jsonString, forKey: "profile_settings")
  }

  public func refresh() async throws {
    if let settings = UserDefaults.standard.string(forKey: "profile_settings")?.data(using: .utf8) {
      do {
        let data = try JSONDecoder().decode(ProfileData.self, from: settings)
        profileData = ProfileData(preferredLocation: data.preferredLocation)
      } catch {
        print("Error fetching profile data ", error)
      }
    } else {
      profileData = ProfileData()
      try await save()
    }
  }
}
