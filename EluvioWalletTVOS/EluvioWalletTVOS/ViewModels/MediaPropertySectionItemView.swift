//
//  MediaPropertySectionItemView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-19.
//

import Foundation
import SwiftyJSON

enum ImageAspectRatio : String, Codable  {case square, portrait , landscape }

struct MediaPropertySectionMediaItemViewModel: Codable, Identifiable, Hashable {
    var id : String
    var media_id : String
    var display : JSON
    var catalog_title : String = ""
    var description : String = ""
    var description_rich_text : String = ""
    var end_time : String = ""
    var start_time : String = ""
    var label : String = ""
    var live_video : Bool = false
    var media_catalog_id : String = ""
    var media_file_url : String = ""
    var media_link : JSON?
    var media_type : String = ""
    var poster_image_url = ""
    var title : String = ""
    var subtitle: String = ""
    var type : String = ""
    var thumbnail_image_square : String = ""
    var thumbnail_image_portrait : String = ""
    var thumbnail_image_landscape : String = ""
    var thumbnail : String = ""
    var thumb_aspect_ratio : ImageAspectRatio = .square
    var headerString: String = ""
    
    var icons : [JSON]? = nil
    
    var sectionItem: MediaPropertySectionItem? = nil
    var mediaItem: MediaPropertySectionMediaItem? = nil
    
    var disabled: Bool {
        if let disable = sectionItem?.disabled {
            return disable
        }
        
        if let permission = sectionItem?.resolvedPermission {
            if !permission.authorized {
                return permission.disable
            }
        }
        
        if let permission = sectionItem?.media?.resolvedPermission {
            if !permission.authorized {
                return permission.disable
            }
        }
        
        if let permission = mediaItem?.resolvedPermission {
            if !permission.authorized {
                return permission.disable
            }
        }
        
        return false
    }
    
    static func == (lhs: MediaPropertySectionMediaItemViewModel, rhs: MediaPropertySectionMediaItemViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func create(media: MediaPropertySectionMediaItem, fabric: Fabric) -> MediaPropertySectionMediaItemViewModel{

        var mediaFile : JSON?
        var posterImageLink : JSON?
        var thumbnailSquareLink : JSON?
        var thumbnailPortraitLink : JSON?
        var thumbnailLandLink : JSON?
        
        var title = ""
        var subtitle = ""
        var catalog_title = ""
        var description = ""
        var description_rich_text = ""
        var end_time = ""
        var start_time = ""
        var media_catalog_id = ""
        var live_video = false
        var icons : [JSON]? = nil
        
        mediaFile = media.media_file
        posterImageLink = media.poster_image
        thumbnailSquareLink = media.thumbnail_image_square
        thumbnailPortraitLink = media.thumbnail_image_portrait
        thumbnailLandLink = media.thumbnail_image_landscape
        
        catalog_title = media.catalog_title ?? ""
        description = media.description ?? ""
        description_rich_text = media.description_rich_text ?? ""
        end_time = media.end_time ?? ""
        start_time = media.start_time ?? ""
        live_video = media.live_video ?? false
        media_catalog_id = media.media_catalog_id ?? ""
        title = media.title ?? ""
        subtitle = media.subtitle ?? ""
        icons = media.icons
        
        var fileUrl = ""
        do {
            fileUrl = try fabric.getUrlFromLink(link: mediaFile, staticUrl: true)
        }catch{}
        
        var posterImage = ""
        do {
            posterImage = try fabric.getUrlFromLink(link: posterImageLink)
        }catch{}
        
        var thumbnailSquare = ""
        do {
            thumbnailSquare = try fabric.getUrlFromLink(link: thumbnailSquareLink)
        }catch{}
        
        var thumbnailPortrait = ""
        do {
            thumbnailPortrait = try fabric.getUrlFromLink(link: thumbnailPortraitLink)
        }catch{}
        
        var thumbnailLand = ""
        do {
            thumbnailLand = try fabric.getUrlFromLink(link: thumbnailLandLink )
        }catch{}
        
        var thumbnail = ""
        var thumb_aspect_ratio = ImageAspectRatio.square
        if !thumbnailSquare.isEmpty {
            thumbnail = thumbnailSquare
            thumb_aspect_ratio = .square
        }else if !thumbnailLand.isEmpty {
            thumbnail = thumbnailLand
            thumb_aspect_ratio = .landscape
        }else if !thumbnailPortrait.isEmpty {
            thumbnail = thumbnailPortrait
            thumb_aspect_ratio = .portrait
        }
        
        var headerString = ""

        return MediaPropertySectionMediaItemViewModel (
            id: media.id ?? "",
            media_id : media.id ?? "",
            display :  JSON(),
            catalog_title: catalog_title,
            description: description,
            description_rich_text: description_rich_text,
            end_time: end_time,
            start_time: start_time,
            label: media.label ?? "",
            live_video : live_video,
            media_catalog_id: media_catalog_id,
            media_file_url: fileUrl,
            media_link: media.media_link,
            media_type : media.media_type ?? "",
            poster_image_url: posterImage,
            title : title,
            subtitle : subtitle,
            type : media.type ?? "",
            thumbnail_image_square : thumbnailSquare,
            thumbnail_image_portrait : thumbnailPortrait,
            thumbnail_image_landscape: thumbnailLand,
            thumbnail : thumbnail,
            thumb_aspect_ratio: thumb_aspect_ratio,
            headerString: headerString,
            icons: icons,
            mediaItem: media
        )
    }

    static func create(item: MediaPropertySectionItem, fabric: Fabric) -> MediaPropertySectionMediaItemViewModel{
        //debugPrint("MediaPropertySectionMediaItemViewModel:create()", item.media?.title)
        var mediaFile : JSON?
        var posterImageLink : JSON?
        var thumbnailSquareLink : JSON?
        var thumbnailPortraitLink : JSON?
        var thumbnailLandLink : JSON?
        var thumb_aspect_ratio = ImageAspectRatio.square
        var title = ""
        var subtitle = ""
        var catalog_title = ""
        var description = ""
        var description_rich_text = ""
        var end_time = ""
        var start_time = ""
        var media_catalog_id = ""
        var live_video = false
        var icons : [JSON]? = nil

        if let media = item.media {
            mediaFile = media.media_file
            posterImageLink = media.poster_image

            
            catalog_title = media.catalog_title ?? ""
            description = media.description ?? ""
            description_rich_text = media.description_rich_text ?? ""
            end_time = media.end_time ?? ""
            start_time = media.start_time ?? ""
            live_video = media.live_video ?? false
            media_catalog_id = media.media_catalog_id ?? ""

            icons = media.icons
            
            //if let mediaSettings = item.use_media_settings {
            //    if mediaSettings {
            thumbnailSquareLink = media.thumbnail_image_square
            thumbnailPortraitLink = media.thumbnail_image_portrait
            thumbnailLandLink = media.thumbnail_image_landscape
            title = media.title ?? ""
            subtitle = media.subtitle ?? ""
            //    }
            //}
        }
        
        if let display = item.display {
            if display["thumbnail_image_square"].exists() {
                thumbnailSquareLink = display["thumbnail_image_square"]
            }
            if display["thumbnail_image_portrait"].exists() {
                thumbnailPortraitLink = display["thumbnail_image_portrait"]
            }
            
            if display["thumbnail_image_landscape"].exists() {
                thumbnailLandLink = display["thumbnail_image_landscape"]
            }
            if !display["title"].stringValue.isEmpty {
                title = display["title"].stringValue
            }
            if !display["subtitle"].stringValue.isEmpty {
                subtitle = display["subtitle"].stringValue
            }
            
            let aspectRatio = display["aspect_ratio"].stringValue.lowercased()
            if aspectRatio == "landscape" {
                thumb_aspect_ratio = .landscape
            }else if aspectRatio == "portrait" {
                thumb_aspect_ratio = .portrait
            }else if aspectRatio == "square" {
                thumb_aspect_ratio = .square
            }

        }

        var fileUrl = ""
        do {
            fileUrl = try fabric.getUrlFromLink(link: mediaFile, staticUrl: true)
        }catch{}
        
        var posterImage = ""
        do {
            posterImage = try fabric.getUrlFromLink(link: posterImageLink)
        }catch{}
        
        var thumbnailSquare = ""
        do {
            thumbnailSquare = try fabric.getUrlFromLink(link: thumbnailSquareLink)
        }catch{}
        
        var thumbnailPortrait = ""
        do {
            thumbnailPortrait = try fabric.getUrlFromLink(link: thumbnailPortraitLink)
        }catch{}
        
        var thumbnailLand = ""
        do {
            thumbnailLand = try fabric.getUrlFromLink(link: thumbnailLandLink )
        }catch{}
        
        var thumbnail = ""

        if !thumbnailSquare.isEmpty {
            thumbnail = thumbnailSquare
            thumb_aspect_ratio = .square
        }else if !thumbnailLand.isEmpty {
            thumbnail = thumbnailLand
            thumb_aspect_ratio = .landscape
        }else if !thumbnailPortrait.isEmpty {
            thumbnail = thumbnailPortrait
            thumb_aspect_ratio = .portrait
        }
        
        var headerString = ""
        if let headers = item.media?.headers {
            headerString = headers.joined(separator: "   ")
        }
        
        return MediaPropertySectionMediaItemViewModel (
            id: item.id ?? "",
            media_id : item.media_id ?? "",
            display : item.display ?? JSON(),
            catalog_title: catalog_title,
            description: description,
            description_rich_text: description_rich_text,
            end_time: end_time,
            start_time: start_time,
            label: item.label ?? "",
            live_video : live_video,
            media_catalog_id: media_catalog_id,
            media_file_url: fileUrl,
            media_link: item.media?.media_link,
            media_type : item.media?.media_type ?? "",
            poster_image_url: posterImage,
            title : title,
            subtitle : subtitle,
            type : item.type ?? "",
            thumbnail_image_square : thumbnailSquare,
            thumbnail_image_portrait : thumbnailPortrait,
            thumbnail_image_landscape: thumbnailLand,
            thumbnail : thumbnail,
            thumb_aspect_ratio: thumb_aspect_ratio,
            headerString: headerString,
            icons: item.media?.icons,
            sectionItem: item,
            mediaItem: item.media
        )
    }
}
