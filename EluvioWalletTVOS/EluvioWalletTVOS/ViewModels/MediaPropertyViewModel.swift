//
//  MediaPropertiesViewModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.
//

import Foundation

struct MediaPropertyViewModel: Identifiable, Codable, Equatable  {
    var id: String? = UUID().uuidString
    var title: String = ""
    var descriptionRichText: AttributedString = ""
    var description: String = ""
    var image: String = ""
    var backgroundImage: String = ""
    var logo: String = ""
    var logoAlt: String = ""
    var position: String = ""
    var sections: [String] = []
    
    static func == (lhs: MediaPropertyViewModel, rhs: MediaPropertyViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    static func create(mediaProperty: MediaProperty, fabric: Fabric) -> MediaPropertyViewModel{
        
        var image = ""
        
        do {
            image = try fabric.getUrlFromLink(link: mediaProperty.image)
        }catch{
            print("Could not create image URL \(error)")
        }
        
        var backgroundImage = ""
        
        do {
            backgroundImage = try fabric.getUrlFromLink(link: mediaProperty.main_page?.layout?["background_image"] ?? "")
        }catch{
            print("Could not create image URL \(error)")
        }
        
        var logo = ""
        do {
            logo = try fabric.getUrlFromLink(link: mediaProperty.main_page?.layout?["logo"])
        }catch{
            print("Could not create image URL \(error)")
        }
        
        var sections: [String] = []
        
        do {
            var sec = mediaProperty.main_page?.layout?["sections"].arrayValue ?? []
            for s in sec {
                sections.append(s.stringValue)
            }
        }
        
        
        return MediaPropertyViewModel(
                id:mediaProperty.id,
                title: mediaProperty.page_title ?? "",
                descriptionRichText: mediaProperty.main_page?.layout?["description_rich_text"].stringValue.html2Attributed() ?? "",
                image: image,
                backgroundImage: backgroundImage,
                logo: logo,
                logoAlt: mediaProperty.main_page?.layout?["logo_alt"].stringValue ?? "",
                position: mediaProperty.main_page?.layout?["position"].stringValue ?? "",
                sections: sections
            )
    }
}
