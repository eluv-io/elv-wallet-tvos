//
//  MediaPropertySectionItemView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-19.
//

import Foundation
import SwiftyJSON

enum ImageAspectRatio : String, Codable  {case square, portrait , landscape }

struct MediaPropertySectionMediaItemViewModel: Codable {
    var id : String
    var media_id : String
    var display : JSON
    var catalog_title : String = ""
    var description : String = ""
    var description_rich_text : String = ""
    var end_time : String = ""
    var start_time : String = ""
    var label : String = ""
    var live : Bool = false
    var media_catalog_id : String = ""
    var media_file_url : String
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
    
    var startDate : Date? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withFractionalSeconds,
            .withFullDate,
            .withTime, // without time zone
            .withColonSeparatorInTime,
            .withDashSeparatorInDate
        ]
        return dateFormatter.date(from:start_time)
    }
    
    var startDateTimeString: String {
        let df = DateFormatter()
        df.dateFormat = "MMM d 'at' hh:mm a"
        df.amSymbol = "AM"
        df.pmSymbol = "PM"
        
        return df.string(from: startDate ?? Date())
    }
    
    var timeUntilStart: String {
        if isUpcoming {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.zeroFormattingBehavior = .pad
            
            if let date = startDate {
                let remainingTime: TimeInterval = date.timeIntervalSince(Date())
                return formatter.string(from: remainingTime) ?? ""
            }
        }
        
        return ""
    }
    
    var isUpcoming : Bool {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withFractionalSeconds,
            .withFullDate,
            .withTime, // without time zone
            .withColonSeparatorInTime,
            .withDashSeparatorInDate
        ]
        guard let date = dateFormatter.date(from:start_time) else {return false}
        
        return date > Date()
    }
    
    static func create(item: MediaPropertySectionItem, fabric: Fabric) -> MediaPropertySectionMediaItemViewModel{

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
        var live = false
        var icons : [JSON]? = nil
        
        if let media = item.media {
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
            live = media.live ?? false
            media_catalog_id = media.media_catalog_id ?? ""
            title = media.title ?? ""
            subtitle = media.subtitle ?? ""
            icons = media.icons
        }
        
        if let type = item.type {
            if type.contains("link") {
                if let display = item.display {
                    thumbnailSquareLink = display["thumbnail_image_square"]
                    thumbnailPortraitLink = display["thumbnail_image_portrait"]
                    thumbnailLandLink = display["thumbnail_image_landscape"]
                    title = display["title"].stringValue
                    subtitle = display["subtitle"].stringValue
                }
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
        
        if let aspectRatio = item.display?["aspect_ratio"].stringValue.lowercased() {
            if aspectRatio == "landscape" {
                thumb_aspect_ratio = .landscape
            }else if aspectRatio == "portrait" {
                thumb_aspect_ratio = .portrait
            }else if aspectRatio == "square" {
                thumb_aspect_ratio = .square
            }
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
            live : live,
            media_catalog_id: media_catalog_id,
            media_file_url: fileUrl,
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
            icons: item.media?.icons
        )
    }
}
