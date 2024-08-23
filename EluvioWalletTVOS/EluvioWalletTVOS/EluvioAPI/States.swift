//
//  States.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-23.
//

import Foundation
import Combine
import AVKit

enum NavDestination: String, Hashable {
    case property, video, gallery, mediaGrid, html, search, sectionViewAll, nft, videoError
}

struct SearchParams {
    var propertyId : String = ""
    var searchTerm : String = ""
    var primaryFilters : [PrimaryFilterViewModel] = []
    var secondaryFilters : [String] = []
    var currentPrimaryFilter : PrimaryFilterViewModel? = nil
    var currentSecondaryFilter : String = ""
}


enum VideoErrorType: String, Hashable {
    case permission, upcoming
}

struct VideoErrorParams{
    var mediaItem : MediaPropertySectionMediaItemView? = nil
    var type : VideoErrorType = .permission
    var backgroundImage: String = ""
    var images : [String] = []
}

class PathState: ObservableObject {
    @Published var path : [NavDestination] = []
    
    var property : MediaProperty? = nil
    var propertyPage : MediaPropertyPage? = nil
    var url : String = ""
    var playerItem : AVPlayerItem? = nil
    var mediaItem : MediaPropertySectionItem? = nil
    var propertyId: String = ""
    var section: MediaPropertySection? = nil
    
    var gallery : [GalleryItem] = []
    var searchParams : SearchParams?
    var videoErrorParams : VideoErrorParams?
    
    var nft : NFTModel? = nil
    
    func reset() {
        property = nil
        propertyId = ""
        propertyPage = nil
        url = ""
        playerItem = nil
        mediaItem = nil
        gallery = []
        searchParams = nil
        section = nil
        nft = nil
        videoErrorParams = nil
    }
}
