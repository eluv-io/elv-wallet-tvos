//
//  Profile.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-06-20.
//

import Foundation

struct ProfileData: Codable {
    var locations : [String]? = []
    var preferredLocation: String?
}

class Profile: ObservableObject {
    @Published
    var profileData = ProfileData()
    
    init(){

    }
    
    func setPreferredLocation(location: String) async throws {
        profileData.preferredLocation = location
        if var locations = profileData.locations {
            if !locations.contains(location) {
                locations.append(location)
                profileData.locations = locations
            }
        }else {
            profileData.locations = []
        }
        
        try await save()
    }
    
    func save() async throws {
        let jsonData = try JSONEncoder().encode(profileData)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        UserDefaults.standard.set(jsonString, forKey: "profile_settings")
    }
    
    func refresh() async throws{
        if let settings = UserDefaults.standard.string(forKey: "profile_settings")?.data(using:.utf8) {
            do {
                profileData = try JSONDecoder().decode(ProfileData.self, from:settings)
                //print("Profile DATA",profileData)
            }catch{
                print("Error fetching profile data ", error)
            }
        }else{
            //XXX:Demo only
            profileData = ProfileData(locations:["los angeles", "phoenix", "new york"], preferredLocation: "los angeles")
            try await save()
        }
    }
}
