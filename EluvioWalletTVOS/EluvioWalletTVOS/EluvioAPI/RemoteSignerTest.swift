//
//  RemoteSignerTest.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2026-02-05.
//

//Use this class to test the visual updates of section items, particularly the currently live state.
//The first 3 calls to getPropertyPageSections will return all live. The 4th call will set the first item to not live.
class RemoteSignerTest_LiveRefresh {
    private var callCount = 0
    
    func getPropertyPageSections(property: String, page: String, noCache:Bool = false, accessCode: String, parameters : [String: String] = [:]) async throws -> MediaPropertySectionsResponse{
        
        callCount += 1
        
        debugPrint("RemoteSignerTest_LiveRefresh: getPropertyPageSections called - Call count: \(callCount)")
        
        let jsonFileName = callCount <= 3 ? "page_sections.json" : "page_sections_2.json"
        
        debugPrint("RemoteSignerTest_LiveRefresh: Loading JSON file: \(jsonFileName)")
        
        let sections: MediaPropertySectionsResponse = loadJsonFileFatal(jsonFileName)
        return sections
    }
}
