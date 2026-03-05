import Foundation

struct ImageParams: Hashable {
  var viewItem: MediaPropertySectionMediaItemViewModel
}

struct MediaGridParams: Hashable {
  var property: MediaProperty
  var mediaItemIds: [String] = []
  var title: String = ""
  var parentMediaItem: MediaPropertySectionMediaItem
}

struct PropertyLink: Hashable {
  var id: String
  var title: String
}

struct PropertyParam: Hashable {
  var propertyId: String
  var pageId: String? = nil
  var propertyLinks: [PropertyLink] = []
}

struct LoginParam: Hashable {
  var property: MediaProperty
}

struct SearchParams: Hashable {
  var propertyId: String = ""
}

struct VideoParams: Hashable {
  struct PlayoutInfo: Hashable {
    var hlsPlaylistUrl: String
    var drmType: String
    var licenseServer: String = ""
  }

  var viewItem: MediaPropertySectionMediaItemViewModel
  var playout: PlayoutInfo
  var property: MediaProperty?
}

struct VideoPermissionErrorParams: Hashable {
  var propertyId: String = ""
}

struct UpcomingVideoParams: Hashable {
  var mediaItem: MediaPropertySectionMediaItem
  var propertyId: String = ""
}

struct HtmlParams: Hashable {
  var url: String = ""
  var backgroundImage: String = ""
  var title: String = ""
  var viewItem: MediaPropertySectionMediaItemViewModel? = nil
}

struct PurchaseParams: Hashable {
  var url: String = ""
  var backgroundImage: String = ""
  var propertyId: String = ""
  var pageId: String = ""
  var sectionId: String = ""
  var sectionItem: MediaPropertySectionItem?
  var mediaItem: MediaPropertySectionMediaItem?
}

struct SectionViewAllParams: Hashable {
  var property: MediaProperty
  var pageId: String
  var section: MediaPropertySection
}
