//
//  MediaPropertySectionItemView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-19.
//

import Foundation
import SwiftyJSON

enum ImageAspectRatio: String, Codable { case square, portrait, landscape }

struct MediaPropertySectionMediaItemViewModel: Decodable, Identifiable, Hashable {
  var id: String
  var media_id: String
  var display: DisplaySettings
  var catalog_title: String = ""
  var description: String = ""
  var description_rich_text: String = ""
  var end_time: String = ""
  var start_time: String = ""
  var label: String = ""
  var live_video: Bool = false
  var media_catalog_id: String = ""
  var media_file_url: String = ""
  var media_link: JSON?
  var media_type: String = ""
  var poster_image_url = ""
  var title: String = ""
  var subtitle: String = ""
  var type: String = ""
  var thumbnail_image_square: String = ""
  var thumbnail_image_portrait: String = ""
  var thumbnail_image_landscape: String = ""
  var thumbnail: String {
    if thumbnailFull.isEmpty {
      return ""
    }

    if thumbnailFull.contains("?") {
      return thumbnailFull + "&height=400"
    } else {
      return thumbnailFull + "?height=400"
    }
  }

  var thumbnailFull: String = ""
  var thumb_aspect_ratio: ImageAspectRatio = .square
  var headerString: String = ""

  var icons: [IconItem]? = nil

  var sectionItem: MediaPropertySectionItem? = nil
  var mediaItem: MediaPropertySectionMediaItem? = nil

  var resolvedPermissions: ResolvedPermission? {
    // MediaItem permissions are more specific. Fallback to SectionItem
    mediaItem?.resolvedPermissions ?? sectionItem?.resolvedPermissions
  }

  var disabled: Bool {
    if let disable = sectionItem?.disabled {
      return disable
    }

    if let permission = sectionItem?.resolvedPermissions {
      if !permission.authorized {
        return permission.disable
      }
    }

    if let permission = sectionItem?.media?.resolvedPermissions {
      if !permission.authorized {
        return permission.disable
      }
    }

    if let permission = mediaItem?.resolvedPermissions {
      if !permission.authorized {
        return permission.disable
      }
    }

    return false
  }

  static func == (
    lhs: MediaPropertySectionMediaItemViewModel, rhs: MediaPropertySectionMediaItemViewModel
  ) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func create(media: MediaPropertySectionMediaItem)
    -> MediaPropertySectionMediaItemViewModel
  {
    let title = media.title ?? ""
    let subtitle = media.subtitle ?? ""
    let catalog_title = media.catalog_title ?? ""
    let description = media.description ?? ""
    let description_rich_text = media.description_rich_text ?? ""
    let end_time = media.end_time ?? ""
    let start_time = media.start_time ?? ""
    let media_catalog_id = media.media_catalog_id ?? ""
    let live_video = media.live_video ?? false
    let icons = media.icons

    let fileUrl = media.media_file?.url ?? ""
    let posterImage = media.poster_image?.url ?? ""

    let thumbnailSquare = media.thumbnail_image_square?.url ?? ""

    let thumbnailPortrait = media.thumbnail_image_portrait?.url ?? ""
    let thumbnailLand = media.thumbnail_image_landscape?.url ?? ""

    var thumbnail = ""
    var thumb_aspect_ratio = ImageAspectRatio.square
    if !thumbnailSquare.isEmpty {
      thumbnail = thumbnailSquare
      thumb_aspect_ratio = .square
    } else if !thumbnailLand.isEmpty {
      thumbnail = thumbnailLand
      thumb_aspect_ratio = .landscape
    } else if !thumbnailPortrait.isEmpty {
      thumbnail = thumbnailPortrait
      thumb_aspect_ratio = .portrait
    }

    let headerString = ""

    debugPrint("thumbnail: ", thumbnail)

    return MediaPropertySectionMediaItemViewModel(
      id: media.id ?? "",
      media_id: media.id ?? "",
      display: DisplaySettings(),
      catalog_title: catalog_title,
      description: description,
      description_rich_text: description_rich_text,
      end_time: end_time,
      start_time: start_time,
      label: media.label ?? "",
      live_video: live_video,
      media_catalog_id: media_catalog_id,
      media_file_url: fileUrl,
      media_link: media.media_link,
      media_type: media.media_type ?? "",
      poster_image_url: posterImage,
      title: title,
      subtitle: subtitle,
      type: media.type ?? "",
      thumbnail_image_square: thumbnailSquare,
      thumbnail_image_portrait: thumbnailPortrait,
      thumbnail_image_landscape: thumbnailLand,
      thumbnailFull: thumbnail,
      thumb_aspect_ratio: thumb_aspect_ratio,
      headerString: headerString,
      icons: icons,
      mediaItem: media
    )
  }

  static func create(item: MediaPropertySectionItem)
    -> MediaPropertySectionMediaItemViewModel
  {
    // debugPrint("MediaPropertySectionMediaItemViewModel:create()", item.media?.title)
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
    var icons: [IconItem]? = nil

    if let media = item.media {
      catalog_title = media.catalog_title ?? ""
      description = media.description ?? ""
      description_rich_text = media.description_rich_text ?? ""
      end_time = media.end_time ?? ""
      start_time = media.start_time ?? ""
      live_video = media.live_video ?? false
      media_catalog_id = media.media_catalog_id ?? ""
      icons = media.icons
      title = media.title ?? ""
      subtitle = media.subtitle ?? ""
    }

    let thumbnailSquareLink: ImageLink? =
      item.display?.thumbnail_image_square ?? item.media?.thumbnail_image_square
    let thumbnailPortraitLink: ImageLink? =
      item.display?.thumbnail_image_portrait ?? item.media?.thumbnail_image_portrait
    let thumbnailLandLink: ImageLink? =
      item.display?.thumbnail_image_landscape ?? item.media?.thumbnail_image_landscape

    if let display = item.display {
      if display.title?.isEmpty == false {
        title = display.title ?? ""
      }
      if display.subtitle?.isEmpty == false {
        subtitle = display.subtitle ?? ""
      }

      let aspectRatio = display.aspect_ratio?.lowercased()
      if aspectRatio == "landscape" {
        thumb_aspect_ratio = .landscape
      } else if aspectRatio == "portrait" {
        thumb_aspect_ratio = .portrait
      } else if aspectRatio == "square" {
        thumb_aspect_ratio = .square
      }
    }

    let fileUrl = item.media?.media_file?.url ?? ""
    let posterImage = item.media?.poster_image?.url ?? ""

    var thumbnail = ""

    if let link = thumbnailSquareLink {
      thumbnail = link.url ?? ""
      thumb_aspect_ratio = .square
    } else if let link = thumbnailLandLink {
      thumbnail = link.url ?? ""
      thumb_aspect_ratio = .landscape
    } else if let link = thumbnailPortraitLink {
      thumbnail = link.url ?? ""
      thumb_aspect_ratio = .portrait
    }

    var headerString = ""
    if let headers = item.media?.headers {
      headerString = headers.joined(separator: "   ")
    }

    return MediaPropertySectionMediaItemViewModel(
      id: item.id ?? "",
      media_id: item.media_id ?? "",
      display: item.display ?? DisplaySettings(),
      catalog_title: catalog_title,
      description: description,
      description_rich_text: description_rich_text,
      end_time: end_time,
      start_time: start_time,
      label: item.label ?? "",
      live_video: live_video,
      media_catalog_id: media_catalog_id,
      media_file_url: fileUrl,
      media_link: item.media?.media_link,
      media_type: item.media?.media_type ?? "",
      poster_image_url: posterImage,
      title: title,
      subtitle: subtitle,
      type: item.type ?? "",
      thumbnail_image_square: thumbnailSquareLink?.url ?? "",
      thumbnail_image_portrait: thumbnailPortraitLink?.url ?? "",
      thumbnail_image_landscape: thumbnailLandLink?.url ?? "",
      thumbnailFull: thumbnail,
      thumb_aspect_ratio: thumb_aspect_ratio,
      headerString: headerString,
      icons: item.media?.icons,
      sectionItem: item,
      mediaItem: item.media
    )
  }
}
