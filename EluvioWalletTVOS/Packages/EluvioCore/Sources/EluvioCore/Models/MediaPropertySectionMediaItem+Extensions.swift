import AVKit
import Foundation

public extension MediaPropertySectionMediaItem {
  public func additionalViews() -> [MediaPropertySectionMediaItem] {
    return additional_views?.map { view in
      let item = MediaPropertySectionMediaItem()
      item.label = view.label
      item.title = view.label
      item.media_link = view.media_link
      item.thumbnail_image_landscape = view.effectiveImage
      return item
    } ?? []
  }

  public func playerItem(eluvio: EluvioAPI, propertyId: String) async throws -> AVPlayerItem {
    if id.hasPrefix("mvid") {
      let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(
        propertyId: propertyId, mediaId: id)
      return try await MakePlayerItemFromMediaOptionsJson(
        fabric: eluvio.fabric, optionsJson: optionsJson,
        title: title ?? "", description: description ?? "", imageThumb: thumbnail())
    }

    if let link = media_link {
      if !link["."].isEmpty {
        let hash = link["."]["source"].stringValue
        if hash.hasPrefix("hq__") {
          return try await MakePlayerItemFromVersionHash(fabric: eluvio.fabric, versionHash: hash)
        }
        return try await MakePlayerItemFromLink(
          fabric: eluvio.fabric, link: link,
          title: title ?? "", description: description ?? "", imageThumb: thumbnail())
      }
    }

    throw FabricError.badInput(
      "Media item \(id ?? "") does not have a valid link: \(String(describing: media_link))")
  }

  public func url(eluvio: EluvioAPI, propertyId: String) async throws -> String {
    let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(
      propertyId: propertyId, mediaId: id)
    return try await GetUriFromMediaOptionsJson(fabric: eluvio.fabric, optionsJson: optionsJson)
  }

  public func thumbnail() -> String {
    thumbnail_image_square?.url
      ?? thumbnail_image_portrait?.url
      ?? thumbnail_image_landscape?.url
      ?? ""
  }

  public var startDate: Date? {
    if debugTimeStatus {
      return debugStartDate
    }

    if let startTime = start_time {
      return parseDateString(startTime)
    }

    if let startTime = stream_start_time {
      return parseDateString(startTime)
    }

    return nil
  }

  public var streamStartDate: Date? {
    if debugTimeStatus {
      return debugStreamStartDate
    }

    if let startTime = stream_start_time {
      return parseDateString(startTime)
    }
    return startDate
  }

  public var endDate: Date? {
    if debugTimeStatus {
      return debugEndDate
    }

    return parseDateString(end_time ?? "")
  }

  public var startDateTimeString: String {
    let df = DateFormatter()
    df.dateFormat = "MM.d 'at' hh:mm a"
    df.amSymbol = "AM"
    df.pmSymbol = "PM"

    return df.string(from: startDate ?? Date())
  }

  public var streamStartDateTimeString: String {
    let df = DateFormatter()
    df.dateFormat = "MMM d 'at' hh:mm a"
    df.amSymbol = "AM"
    df.pmSymbol = "PM"

    return df.string(from: streamStartDate ?? Date())
  }

  public var timeUntilStart: String {
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

  public var timeUntilStartLong: String {
    if isUpcoming {
      if let date = startDate {
        let remainingTime: TimeInterval = date.timeIntervalSince(Date())

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full

        if remainingTime >= 60 * 60 * 24 {
          formatter.allowedUnits = [.day, .hour, .minute, .second]
        } else if remainingTime >= 60 * 60 {
          formatter.allowedUnits = [.hour, .minute, .second]
        } else if remainingTime >= 60 {
          formatter.allowedUnits = [.second, .minute]
        } else {
          formatter.allowedUnits = [.second]
        }

        formatter.zeroFormattingBehavior = .pad

        // Split the interval with a DST-free calendar: the formatter otherwise walks
        // days forward from its default 2001-01-01 referenceDate in local time, which
        // picks up a stray hour from 2001's DST transition for intervals >~90 days.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        formatter.calendar = calendar

        return formatter.string(from: remainingTime) ?? " "
      }
    }

    return ""
  }

  public var hasStarted: Bool {
    return !isUpcoming
  }

  public var hasEnded: Bool {
    if let endDate = endDate {
      return endDate < Date()
    }
    return false
  }

  public var isUpcoming: Bool {
    if hasEnded {
      return false
    }

    if let date = streamStartDate {
      return date > Date()
    }

    if let date = startDate {
      return date > Date()
    }

    return false
  }

  public var currentlyLive: Bool {
    live_video == true && !isUpcoming && hasStarted && !hasEnded
  }

  /// Media Lists will have a list of media items under `media`, while Media Collections
  /// will have a list of media lists under `mediaLists`. It is assumed that there will
  /// only be one or the other, so we're just trying both with no real priority.
  public var mediaItemIds: [String]? {
    media ?? media_lists
  }

  public static func == (lhs: MediaPropertySectionMediaItem, rhs: MediaPropertySectionMediaItem) -> Bool {
    return lhs.id == rhs.id
      && lhs.title == rhs.title
      && lhs.subtitle == rhs.subtitle
      && lhs.live_video == rhs.live_video
      && lhs.start_time == rhs.start_time
      && lhs.stream_start_time == rhs.stream_start_time
      && lhs.end_time == rhs.end_time
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(live_video)
  }
}
