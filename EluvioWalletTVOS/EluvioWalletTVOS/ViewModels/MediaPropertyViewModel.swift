//
//  MediaPropertiesViewModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.
//

import Foundation
import SwiftyJSON

struct MediaPropertyViewModel: Identifiable, Codable, Equatable, Hashable  {
    var id: String? = UUID().uuidString
    var title: String = ""
    var name: String = ""
    var descriptionRichText: AttributedString = ""
    var description: String = ""
    var image: String = ""
    var backgroundImage: String = ""
    var login: JSON? = nil
    var logo: String = ""
    var logoAlt: String = ""
    var position: String = ""
    var sections: [String] = []
    var permissions : JSON? = nil
    var main_page : MediaPropertyPage? = nil
    var permission_auth_state : JSON? = nil
    
    static func == (lhs: MediaPropertyViewModel, rhs: MediaPropertyViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    static func create(mediaProperty: MediaProperty, fabric: Fabric) -> MediaPropertyViewModel{
        
        var image = ""
        
        //debugPrint("Fabric: ", fabric)
        //debugPrint("image: ", mediaProperty.image)
        do {
            image = try fabric.getUrlFromLink(link: mediaProperty.image)
        }catch{
            //print("Could not create image URL \(error)")
        }
        
        var backgroundImage = ""
        
        do {
            backgroundImage = try fabric.getUrlFromLink(link: mediaProperty.main_page?.layout?["background_image"] ?? "")
        }catch{
            //print("Could not create image URL \(error)")
        }
        
        var logo = ""
        do {
            logo = try fabric.getUrlFromLink(link: mediaProperty.main_page?.layout?["logo"])
        }catch{
            //print("Could not create image URL \(error)")
        }
        
        var sections: [String] = []
        
        do {
            let sec = mediaProperty.main_page?.layout?["sections"].arrayValue ?? []
            for s in sec {
                sections.append(s.stringValue)
            }
        }
        
        
        return MediaPropertyViewModel(
                id:mediaProperty.id,
                title: mediaProperty.title ?? mediaProperty.page_title ?? "",
                name: mediaProperty.name ?? "",
                descriptionRichText:  mediaProperty.main_page?.layout?["description_rich_text"].stringValue.html2Attributed() ?? "", description: mediaProperty.main_page?.layout?["description_text"].stringValue ?? "",
                image: image,
                backgroundImage: backgroundImage,
                login: mediaProperty.login,
                logo: logo,
                logoAlt: mediaProperty.main_page?.layout?["logo_alt"].stringValue ?? "",
                position: mediaProperty.main_page?.layout?["position"].stringValue ?? "",
                sections: sections,
                permissions : mediaProperty.permissions,
                main_page: mediaProperty.main_page,
                permission_auth_state: mediaProperty.permission_auth_state
            )
    }
}
