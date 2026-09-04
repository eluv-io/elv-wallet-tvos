import EluvioCore
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
  /// Filters to preselect when the search page opens, set by "search_page_link"
  /// section items. Empty means "no preselection" - the default filter applies.
  var primaryFilter: String = ""
  var secondaryFilter: String = ""
}

/// Where the user was when they started playback. Autoplay needs these ids together to work
/// out what comes next, and passing them one at a time through the tap chain drops them.
/// Android carries a "permission context" for the same reason; tvOS had no equivalent.
struct PlaybackContext: Hashable {
  var pageId: String = ""
  var sectionId: String = ""
  var mediaListId: String = ""
}

struct VideoParams: Hashable {
  var viewItem: MediaPropertySectionMediaItemViewModel
  var playout: PlayoutInfo
  var property: MediaProperty?
  var context: PlaybackContext = .init()
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
