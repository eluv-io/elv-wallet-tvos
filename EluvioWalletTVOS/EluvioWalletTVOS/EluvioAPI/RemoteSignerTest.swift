//
//  RemoteSignerTest.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2026-02-05.
//

//Use this class to test the visual updates of section items, particularly the currently live state.

class RemoteSignerTest_LiveRefresh {
    private var callCount = 0
    
    //The first 2 calls to getPropertyPageSections will return all live. The 3rd call will remove the first item.
    func getPropertyPageSections(property: String, page: String, noCache:Bool = false, accessCode: String, parameters : [String: String] = [:]) async throws -> MediaPropertySectionsResponse{
        
        callCount += 1
        
        debugPrint("RemoteSignerTest_LiveRefresh: getPropertyPageSections called - Call count: \(callCount)")
        
        let jsonFileName = callCount <= 2 ? "page_sections.json" : "page_sections_2.json"
        
        debugPrint("RemoteSignerTest_LiveRefresh: Loading JSON file: \(jsonFileName)")
        
        let sections: MediaPropertySectionsResponse = loadJsonFileFatal(jsonFileName)
        return sections
    }
    
    //The first 2 calls to getPropertyPageSectionsReverse will return 3 live. The 3rd call will return 4.
    func getPropertyPageSectionsReverse(property: String, page: String, noCache:Bool = false, accessCode: String, parameters : [String: String] = [:]) async throws -> MediaPropertySectionsResponse{
        
        callCount += 1
        
        debugPrint("RemoteSignerTest_LiveRefresh: getPropertyPageSections called - Call count: \(callCount)")
        
        let jsonFileName = callCount <= 2 ? "page_sections_2.json" : "page_sections.json"
        
        debugPrint("RemoteSignerTest_LiveRefresh: Loading JSON file: \(jsonFileName)")
        
        let sections: MediaPropertySectionsResponse = loadJsonFileFatal(jsonFileName)
        return sections
    }
    
    //The first 2 calls to getPropertyPageSections will return all live except the first one. The 3rd call will set the first item to live.
    func getPropertyPageSectionsToLive(property: String, page: String, noCache:Bool = false, accessCode: String, parameters : [String: String] = [:]) async throws -> MediaPropertySectionsResponse{
        
        callCount += 1
        
        debugPrint("RemoteSignerTest_LiveRefresh: getPropertyPageSections called - Call count: \(callCount)")
        
        let jsonFileName = callCount <= 2 ? "page_sections_3.json" : "page_sections.json"
        
        debugPrint("RemoteSignerTest_LiveRefresh: Loading JSON file: \(jsonFileName)")
        
        let sections: MediaPropertySectionsResponse = loadJsonFileFatal(jsonFileName)
        return sections
    }
}
