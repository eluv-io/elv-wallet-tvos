//
//  MediaPropertiesViewModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.
//

import Foundation
import SwiftyJSON

struct MediaPropertyViewModel: Identifiable, Codable, Equatable, Hashable  {
    var id: String = UUID().uuidString
    var title: String = ""
    var name: String = ""
    var descriptionRichText: AttributedString = ""
    var description: String = ""
    var image: String = ""
    var backgroundImage: String = ""
    // Note: JSON properties are not cached, they'll be nil when loaded from cache
    var login: JSON? = nil
    var logo: String = ""
    var logoAlt: String = ""
    var position: String = ""
    var sections: [String] = []
    var permissions : JSON? = nil
    var main_page : MediaPropertyPage? = nil
    var permission_auth_state : JSON? = nil
    var purchaseImage : String = ""
    var hasAuth : Bool = false
    // Note: model reference is not cached
    var model : MediaProperty? = nil
    
    var startScreenImage: String = ""
    var startScreenBackground: String = ""
    
    // Custom Codable implementation to handle non-codable properties
    enum CodingKeys: String, CodingKey {
        case id, title, name, description, image, backgroundImage
        case logo, logoAlt, position, sections, purchaseImage, hasAuth
        case startScreenImage, startScreenBackground
        // Skip: descriptionRichText, login, permissions, main_page, permission_auth_state, model
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        image = try container.decode(String.self, forKey: .image)
        backgroundImage = try container.decode(String.self, forKey: .backgroundImage)
        logo = try container.decode(String.self, forKey: .logo)
        logoAlt = try container.decode(String.self, forKey: .logoAlt)
        position = try container.decode(String.self, forKey: .position)
        sections = try container.decode([String].self, forKey: .sections)
        purchaseImage = try container.decode(String.self, forKey: .purchaseImage)
        hasAuth = try container.decode(Bool.self, forKey: .hasAuth)
        startScreenImage = try container.decode(String.self, forKey: .startScreenImage)
        startScreenBackground = try container.decode(String.self, forKey: .startScreenBackground)
        
        // Non-codable properties default to nil/empty
        descriptionRichText = AttributedString()
        login = nil
        permissions = nil
        main_page = nil
        permission_auth_state = nil
        model = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(image, forKey: .image)
        try container.encode(backgroundImage, forKey: .backgroundImage)
        try container.encode(logo, forKey: .logo)
        try container.encode(logoAlt, forKey: .logoAlt)
        try container.encode(position, forKey: .position)
        try container.encode(sections, forKey: .sections)
        try container.encode(purchaseImage, forKey: .purchaseImage)
        try container.encode(hasAuth, forKey: .hasAuth)
        try container.encode(startScreenImage, forKey: .startScreenImage)
        try container.encode(startScreenBackground, forKey: .startScreenBackground)
    }
    
    // Regular initializer for runtime creation
    init(id: String = UUID().uuidString, title: String = "", name: String = "", 
         descriptionRichText: AttributedString = "", description: String = "", 
         image: String = "", backgroundImage: String = "", login: JSON? = nil,
         logo: String = "", logoAlt: String = "", position: String = "", 
         sections: [String] = [], permissions: JSON? = nil, 
         main_page: MediaPropertyPage? = nil, permission_auth_state: JSON? = nil,
         purchaseImage: String = "", hasAuth: Bool = false, model: MediaProperty? = nil,
         startScreenImage: String = "", startScreenBackground: String = "") {
        
        self.id = id
        self.title = title
        self.name = name
        self.descriptionRichText = descriptionRichText
        self.description = description
        self.image = image
        self.backgroundImage = backgroundImage
        self.login = login
        self.logo = logo
        self.logoAlt = logoAlt
        self.position = position
        self.sections = sections
        self.permissions = permissions
        self.main_page = main_page
        self.permission_auth_state = permission_auth_state
        self.purchaseImage = purchaseImage
        self.hasAuth = hasAuth
        self.model = model
        self.startScreenImage = startScreenImage
        self.startScreenBackground = startScreenBackground
    }
    
    static func == (lhs: MediaPropertyViewModel, rhs: MediaPropertyViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    static func create(mediaProperty: MediaProperty, fabric: Fabric) async -> MediaPropertyViewModel{
        
        var image = ""
        
        //debugPrint("Fabric: ", fabric)
        //debugPrint("image: ", mediaProperty.image)
        do {
            image = try fabric.getUrlFromLink(link: mediaProperty.image)
        }catch{
            //print("Could not create image URL \(error)")
        }
        
        var startScreenImage = ""
        do {
            startScreenImage = try fabric.getUrlFromLink(link: mediaProperty.start_screen_logo)
        }catch{}
        
        var startScreenBackground = ""
        do {
            startScreenBackground = try fabric.getUrlFromLink(link: mediaProperty.start_screen_background)
        }catch{}
        
        var backgroundImage = ""
        do {
            backgroundImage = try fabric.getUrlFromLink(link: mediaProperty.image_tv)
        }catch{}
        
        var purchaseImage = ""
        do {
            purchaseImage = try fabric.getUrlFromLink(link: mediaProperty.purchase_settings?["background_tv"])
        }catch{}
 
        if purchaseImage.isEmpty {
            purchaseImage = backgroundImage
        }else{
            //debugPrint("Found purchaseImage ", purchaseImage)
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
            id:mediaProperty.id ?? UUID().uuidString,
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
            permissions: mediaProperty.permissions,
            main_page: mediaProperty.main_page,
            permission_auth_state: mediaProperty.permission_auth_state,
            purchaseImage: purchaseImage,
            hasAuth: fabric.checkPropertyAuthState(property:mediaProperty),
            model : mediaProperty,
            startScreenImage: startScreenImage,
            startScreenBackground: startScreenBackground
        )
    }
}
