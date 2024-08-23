//
//  ProfileClient.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-08-02.
//

import Foundation
import Alamofire
import SwiftyJSON

enum ProfileMode:String {
    case PUB = "pub"
    case PRI = "pri"
}

enum ProfileType:String  {
    case APP = "app"
    case USR = "usr"
}

class ProfileClient {
    var fabric: Fabric
    var viewedMedia: [String: Bool] = [:]
    let appId = "eluvio-media-wallet"
    
    init(fabric:Fabric){
        self.fabric = fabric
    }
    
    func mediaViewKey(contractAddress:String, mediaId:String) -> String {
        let address = FormatAddress(address: contractAddress);
        return "nft-media-viewed-\(address)-\(mediaId)"
    }
    
    func userProfilePath(appId:String="", type:ProfileType, mode:ProfileMode = .PUB, userAddress:String="", key:String) throws -> String{
        var address = FormatAddress(address:userAddress)
        if userAddress.isEmpty {
            address = try fabric.getAccountAddress()
        }
        
        if let stateUrl = fabric.getStateStoreUrl() {
            let url = stateUrl.appending(fabric.network == "main" ? "/main" : "/dv3").appending("/\(type == .APP ? "app/"+appId: "usr")").appending("/\(address)").appending("/\(mode.rawValue)").appending("/\(key)")
            return url
        }
        
        throw FabricError.configError("ProfileClient: could not get state Store Url")
    }
    
    
    func getProfileMetadata(appId:String="", type:ProfileType, mode:ProfileMode = .PUB, userAddress:String="", key:String) async throws -> JSON {
        let url = try userProfilePath(appId:appId, type:type, mode:mode, userAddress:userAddress, key:key)
        return try await fabric.getJsonRequest(url: url)
    }
    
    func setProfileMetadata(appId:String="", type:ProfileType, mode:ProfileMode = .PUB, userAddress:String="", key:String, value: String) async throws {
        let url = try userProfilePath(appId:appId, type:type, mode:mode, userAddress:userAddress, key:key)
        _ = try await fabric.httpJsonRequest(url: url, method: .post, body: value)
    }
    
    func removeProfileMetadata(appId:String="", type:ProfileType, mode:ProfileMode = .PUB, userAddress:String="", key:String) async throws {
        let url = try userProfilePath(appId:appId, type:type, mode:mode, userAddress:userAddress, key:key)
        _ = try await fabric.httpJsonRequest(url: url, method: .delete)
    }
    
    func getUserProfile(userAddress:String) async throws -> (userName:String, imageUrl:String, badgeInfo: JSON){
        
        var userName = ""
        do {
            userName  = try await self.getProfileMetadata(type: .USR, userAddress:userAddress, key: "username")["value"].stringValue
        }catch {
            print("Response Code ", error.asAFError?.responseCode ?? "")
            if error.asAFError?.responseCode != 404 {
                print("Error getting profile user name", error)
            }
        }
        
        var imageUrl = ""
        do {
            imageUrl = try await self.getProfileMetadata(type: .USR, userAddress:userAddress, key: "icon_url")["value"].stringValue
        }catch {
            print("Response Code ", error.asAFError?.responseCode ?? "")
            if error.asAFError?.responseCode != 404 {
                print("Error getting profile imageUrl", error)
            }
        }
        
        var badgeInfo = JSON()
        do {
            badgeInfo = try await self.getProfileMetadata(appId: "elv-badge-srv",type: .APP, userAddress:fabric.getBadgerAddress(), key: "badges_\(userAddress)")
        }catch{
            print("Response Code ", error.asAFError?.responseCode ?? "")
            if error.asAFError?.responseCode != 404 {
                print("Error getting profile badgeInfo", error)
            }
        }
        
        return (userName, imageUrl, badgeInfo)
    }
    
    
    func mediaViewed(contractAddress:String, mediaId:String) -> Bool {

        return self.viewedMedia[self.mediaViewKey(contractAddress:contractAddress, mediaId:mediaId)] ?? false;
    }

    func checkViewedMedia(contractAddress:String, mediaIds:[String]) async throws {
        
        var viewed = self.viewedMedia
        
        for mediaId in mediaIds {
            let key = self.mediaViewKey(contractAddress:contractAddress, mediaId:mediaId);
            if(viewed[key] ?? false) { return}
            do {
                let result = try await self.getProfileMetadata(
                    appId: self.appId,
                    type: ProfileType.APP,
                    mode: ProfileMode.PRI,
                    key: key
                )
                debugPrint(result)
                if(result["value"].boolValue) {
                    viewed[key] = true;
                }
            }catch {
                print("Error getting profile metadata for key ", key)
            }
        }
        
        
        self.viewedMedia = viewed;
    }

    func setMediaViewed(contractAddress:String, mediaId:String) async throws {

        let key = self.mediaViewKey(contractAddress:contractAddress, mediaId:mediaId)
        if !(self.viewedMedia[key] ?? false) {
          try await self.setProfileMetadata(
              appId: self.appId,
              type: ProfileType.APP,
              mode: ProfileMode.PRI,
              key: key,
              value: "true"
          );
        }

        self.viewedMedia[key] = true;
    }

    func removeMediaViewed(key: String) async throws {

        try await self.removeProfileMetadata(
            appId: self.appId,
            type: ProfileType.APP,
            mode: ProfileMode.PRI,
            key: key
        );

        self.viewedMedia.removeValue(forKey: key)
      }
}
