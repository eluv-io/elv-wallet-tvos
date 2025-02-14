//
//  States.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-23.
//

import Foundation
import Combine
import AVKit

enum NavDestination: Hashable {
    case property(PropertyParam), video, gallery, mediaGrid(MediaGridParams), html(HtmlParams), search, sectionViewAll, nft,
         videoError, login(LoginParam), errorView(String), progress, black, purchaseQRView(PurchaseParams), imageView(ImageParams)
}

struct ImageParams:Hashable{
    var url: String = ""
    var title : String = ""
}

enum LoginType : String {
    case auth0, ory
}

struct MediaGridParams : Hashable {
    var propertyId : String? = nil
    var pageId : String = "main"
    var list : [String] = []
    var sectionItem: MediaPropertySectionItem? = nil
}

struct PropertyParam : Hashable {
    var property : MediaProperty? = nil
    var pageId : String = "main"
}

struct LoginParam : Hashable {
    var type : LoginType
    var property : MediaProperty? = nil
}

struct SearchParams {
    var propertyId : String = ""
    var searchTerm : String = ""
    var primaryFilters : [PrimaryFilterViewModel] = []
    var secondaryFilters : [SecondaryFilterViewModel] = []
    var currentPrimaryFilter : PrimaryFilterViewModel? = nil
    var currentSecondaryFilter : SecondaryFilterViewModel? = nil
}

enum VideoErrorType: String, Hashable {
    case permission, upcoming
}

struct VideoParams:Hashable{
    var mediaId: String = ""
    var playerItem : AVPlayerItem? = nil
}

struct VideoErrorParams{
    var mediaItem : MediaPropertySectionMediaItem? = nil
    var type : VideoErrorType = .permission
    var backgroundImage: String = ""
    var images : [String] = []
    var headerString : String = ""
    var propertyId: String = ""
}

struct HtmlParams:Hashable{
    var url : String = ""
    var backgroundImage: String = ""
    var title: String = ""
}

struct PurchaseParams:Hashable{
    var url : String = ""
    var backgroundImage: String = ""
    var propertyId: String = ""
    var pageId : String = ""
    var sectionId : String = ""
    var sectionItem: MediaPropertySectionItem? = nil
    var mediaItem: MediaPropertySectionMediaItem? = nil
}

class PathState: ObservableObject {
    @Published var path : [NavDestination] = []
    
    var property : MediaProperty? = nil
    var propertyPage : MediaPropertyPage? = nil
    var url : String = ""
    var backgroundImage : String = ""
    var mediaItem : MediaPropertySectionMediaItem? = nil
    var propertyId: String = ""
    var pageId: String = ""
    var section: MediaPropertySection? = nil
    var sectionItem: MediaPropertySectionItem? = nil
    
    var gallery : [GalleryItem] = []
    var searchParams : SearchParams?
    var videoErrorParams : VideoErrorParams?
    var videoParams : VideoParams?
    
    var nft : NFTModel? = nil
    
    
    func reset() {
        property = nil
        propertyId = ""
        pageId = "main"
        propertyPage = nil
        url = ""
        backgroundImage = ""
        videoParams = nil
        mediaItem = nil
        gallery = []
        searchParams = nil
        section = nil
        sectionItem = nil
        nft = nil
        videoErrorParams = nil
    }
}
