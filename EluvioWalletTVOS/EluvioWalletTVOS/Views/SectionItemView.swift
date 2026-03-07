//
//  SectionItemView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-19.
//

import AVFoundation
import SDWebImageSwiftUI
import SwiftUI
import SwiftyJSON

// MARK: - Shared media item tap handler

/// Handles the tap action for a media item, routing to the appropriate destination
/// (video, HTML, gallery, purchase, etc.) based on the item's type and permissions.
@MainActor
func handleSectionItemTap(
  router: Router,
  eluvio: EluvioAPI,
  property: MediaProperty,
  pageId: String = "",
  sectionId: String = "",
  viewItem: MediaPropertySectionMediaItemViewModel
) async {
  let sectionItem = viewItem.sectionItem
  let rawMediaItem = viewItem.mediaItem
  let itemId = sectionItem?.id ?? rawMediaItem?.id ?? viewItem.id

  do {
    router.path.append(.black)

    if let permission = viewItem.resolvedPermissions {
      let itemType = sectionItem?.type ?? rawMediaItem?.type
      if !permission.authorized || itemType == "item_purchase" {
        try handleUnauthorizedItem(
          router: router, eluvio: eluvio,
          property: property, pageId: pageId, sectionId: sectionId,
          viewItem: viewItem,
          itemId: itemId,
          itemType: itemType,
          mediaItem: rawMediaItem,
          permission: permission)
        return
      }
    }

    if let mediaItem = viewItem.mediaItem {
      await handleMediaItemTap(
        mediaItem, viewModel: viewItem, router: router, eluvio: eluvio, property: property)
    } else if viewItem.type == "subproperty_link" {
      _ = router.path.popLast()
      if let subPropertyId = sectionItem?.subproperty_id {
        let subPageId = sectionItem?.subproperty_page_id
        let params = PropertyParam(propertyId: subPropertyId, pageId: subPageId)
        router.path.append(.property(params))
      }
    } else if sectionItem?.type?.lowercased() == "page_link" {
      _ = router.path.popLast()
      if let linkPageId = sectionItem?.page_id?.nilIfEmpty() {
        let param = PropertyParam(propertyId: property.id, pageId: linkPageId)
        router.path.append(.property(param))
      }
    } else {
      debugPrint("Item without type: ", viewItem)
      _ = router.path.popLast()
    }
  } catch let FabricError.apiError(code, response, error) {
    eluvio.handleApiError(code: code, response: response, error: error)
    _ = router.path.popLast()
  } catch {
    print("Error processing media item ", error)
    await eluvio.refreshFabricToken()
    _ = router.path.popLast()
    router.path.append(.errorView("Could not access media."))
  }
}

@MainActor
func handleMediaItemTap(
  _ mediaItem: MediaPropertySectionMediaItem,
  viewModel: MediaPropertySectionMediaItemViewModel,
  router: Router,
  eluvio: EluvioAPI,
  property: MediaProperty,
) async {
  // Upcoming check
  if mediaItem.isUpcoming {
    let videoErrorParams = UpcomingVideoParams(
      mediaItem: mediaItem, propertyId: property.id)
    _ = router.path.popLast()
    router.path.append(.upcomingLiveEvent(videoErrorParams))
    return
  }

  // Media type handling
  let mediaType = mediaItem.media_type?.lowercased()

  if mediaType == "video" {
    await handleVideoItem(
      router: router, eluvio: eluvio, property: property, viewItem: viewModel,
      mediaItem: mediaItem)
  } else if mediaType == "html" {
    if !viewModel.media_file_url.isEmpty {
      let params = HtmlParams(viewItem: viewModel)
      _ = router.path.popLast()
      router.path.append(.html(params))
    } else {
      print("MediaItem has empty file for html type")
      _ = router.path.popLast()
    }
  } else if mediaType == "list" || mediaType == "collection" {
    let ids = mediaItem.media ?? mediaItem.media_lists ?? []
    if !ids.isEmpty {
      let params = MediaGridParams(
        property: property, mediaItemIds: ids, title: mediaItem.title ?? "",
        parentMediaItem: mediaItem)
      _ = router.path.popLast()
      router.path.append(.mediaGrid(params))
    } else {
      print("MediaItem has empty list")
      _ = router.path.popLast()
    }
  } else if mediaType == "gallery" {
    if let gallery = mediaItem.gallery {
      _ = router.path.popLast()
      router.path.append(.gallery(gallery))
    } else {
      print("MediaItem has empty gallery")
      _ = router.path.popLast()
    }
  } else if mediaType == "image" {
    let params = ImageParams(viewItem: viewModel)
    _ = router.path.popLast()
    router.path.append(.imageView(params))
  }
}

func handleUnauthorizedItem(
  router: Router,
  eluvio: EluvioAPI,
  property: MediaProperty,
  pageId: String = "",
  sectionId: String = "",
  viewItem: MediaPropertySectionMediaItemViewModel,
  itemId: String,
  itemType: String?,
  mediaItem: MediaPropertySectionMediaItem?,
  permission: ResolvedPermission,
) throws {
  let purchaseImage = property.purchaseImage

  if permission.purchaseGate || itemType == "item_purchase" {
    let auth = eluvio.createWalletAuthorization()
    let url = try eluvio.fabric.createWalletPurchaseUrl(
      id: itemId, propertyId: property.id, pageId: pageId,
      sectionId: sectionId, sectionItemId: itemId,
      permissionIds: permission.permissionItemIds,
      secondaryPurchaseOption: permission.secondaryPurchaseOption,
      authorization: auth)

    let params = PurchaseParams(
      url: url,
      backgroundImage: purchaseImage,
      propertyId: property.id,
      pageId: permission.alternatePageId,
      sectionId: sectionId,
      sectionItem: viewItem.sectionItem,
      mediaItem: mediaItem)
    _ = router.path.popLast()
    router.path.append(.purchaseQRView(params))
    return
  } else if permission.showAlternatePage {
    let auth = eluvio.createWalletAuthorization()
    let url = eluvio.fabric.createWalletPageLink(
      propertyId: property.id, pageId: permission.alternatePageId,
      authorization: auth)

    let params = PurchaseParams(
      url: url,
      backgroundImage: purchaseImage,
      propertyId: property.id,
      pageId: permission.alternatePageId,
      sectionId: sectionId,
      sectionItem: viewItem.sectionItem,
      mediaItem: mediaItem)
    _ = router.path.popLast()
    router.path.append(.purchaseQRView(params))
    return
  }

  _ = router.path.popLast()
  router.path.append(.errorView("Could not access media."))
}

@MainActor
func handleVideoItem(
  router: Router,
  eluvio: EluvioAPI,
  property: MediaProperty,
  viewItem: MediaPropertySectionMediaItemViewModel,
  mediaItem: MediaPropertySectionMediaItem?
) async {
  if viewItem.media_link != nil {
    if viewItem.media_link?["."]["resolution_error"]["kind"].stringValue
      == "permission denied"
    {
      let videoErrorParams = VideoPermissionErrorParams(propertyId: property.id)
      _ = router.path.popLast()
      router.path.append(.videoPermissionError(videoErrorParams))
      return
    }

    do {
      let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(
        propertyId: property.id, mediaId: viewItem.media_id)
      let playout = try ResolveMediaPlayoutInfo(
        fabric: eluvio.fabric, optionsJson: optionsJson)
      let params = VideoParams(
        viewItem: viewItem,
        playout: playout,
        property: property)
      _ = router.path.popLast()
      router.path.append(.video(params))
    } catch {
      print("Error getting link url for playback ", error)
      let videoErrorParams = VideoPermissionErrorParams(propertyId: property.id)
      _ = router.path.popLast()
      router.path.append(.videoPermissionError(videoErrorParams))
    }
  } else {
    _ = router.path.popLast()
  }
}

// MARK: - Views

struct MediaItemGridView: View {
  @EnvironmentObject var eluvio: EluvioAPI

  var property: MediaProperty
  var items: [MediaPropertySectionMediaItem]
  var title: String = ""

  @FocusState var isFocused

  var display: MediaDisplay {
    if let item = items.first {
      if item.thumbnail_image_portrait != nil {
        return .feature
      }

      if item.thumbnail_image_landscape != nil {
        return .video
      }
    }

    return .square
  }

  var numColumns: Int {
    if display == .video {
      return 4
    } else if display == .square {
      return 6
    } else {
      return 4
    }
  }

  var body: some View {
    VStack {
      HStack {
        Text(title)
          .font(.rowTitle)
        Spacer()
      }
      .frame(maxWidth: .infinity)
      .padding(.bottom, 30)

      if items.dividedIntoGroups(of: numColumns).count <= 1 {
        HStack(spacing: 34) {
          ForEach(items, id: \.self) { item in
            SectionMediaItemView(
              item: item, property: property, forceDisplay: display
            )
          }
          Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .edgesIgnoringSafeArea([.leading, .trailing])
        .focusSection()
      } else {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 80) {
          ForEach(items.dividedIntoGroups(of: numColumns), id: \.self) { groups in
            GridRow(alignment: .top) {
              ForEach(groups, id: \.self) { item in
                SectionMediaItemView(
                  item: item, property: property,
                  forceDisplay: display
                )
              }
              .gridColumnAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gridColumnAlignment(.leading)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .focusSection()
      }
    }
    .edgesIgnoringSafeArea([.leading, .trailing])
    .padding([.top, .bottom], 40)
    .padding([.leading], 80)
    .focusSection()
  }
}

struct SectionItemListView: View {
  @EnvironmentObject var eluvio: EluvioAPI

  var property: MediaProperty
  var mediaItemIds: [String]
  var title: String = ""
  var parentMediaItem: MediaPropertySectionMediaItem
  var isSearch: Bool = false

  private var items: [MediaPropertySectionMediaItem] {
    MediaItemStore.shared.observeMediaItems(ids: mediaItemIds)
  }
  @FocusState var isFocused

  var body: some View {
    MediaItemGridView(
      property: property, items: items, title: title
    )
    .focusSection()
    .task {
      await MediaItemStore.shared.fetchMediaItems(
        propertyId: property.id,
        ids: mediaItemIds,
        parentPermissions: parentMediaItem.resolvedPermissions,
        permissionStates: property.permission_auth_state ?? [:])
    }
  }
}

struct SectionMediaItemView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router

  var item: MediaPropertySectionMediaItem
  var sectionItem: MediaPropertySectionItem?
  var property: MediaProperty
  var forceDisplay: MediaDisplay? = nil

  var display: MediaDisplay {
    if let forceDisplay = forceDisplay {
      return forceDisplay
    }

    if item.thumbnail_image_square != nil {
      return .square
    }

    if item.thumbnail_image_portrait != nil {
      return .feature
    }

    if item.thumbnail_image_landscape != nil {
      return .video
    }

    return .square
  }

  @FocusState var isFocused

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button(action: {
        Task {
          var vm = MediaPropertySectionMediaItemViewModel.create(media: item)
          vm.sectionItem = sectionItem
          await handleSectionItemTap(
            router: router, eluvio: eluvio,
            property: property, viewItem: vm)
        }
      }) {
        MediaCard(
          display: display,
          image: item.thumbnail(),
          isFocused: isFocused,
          isUpcoming: item.isUpcoming,
          startTimeString: item.startDateTimeString,
          title: item.title ?? "",
          isLive: item.currentlyLive,
          showFocusedTitle: item.title ?? "" == "" ? false : true)
      }
      .buttonStyle(TitleButtonStyle(focused: isFocused, scale: 1.0))
      .focused($isFocused)
    }
  }
}

struct SectionItemView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router

  var sectionId: String
  var pageId: String
  var property: MediaProperty
  var forceAspectRatio: String = ""
  var forceDisplay: MediaDisplay?
  var viewItem: MediaPropertySectionMediaItemViewModel

  @FocusState var isFocused

  var permission: ResolvedPermission? {
    return viewItem.sectionItem?.media?.resolvedPermissions
  }

  var scaleFactor = 1.0

  var hide: Bool { permission?.hide == true }

  var disable: Bool { viewItem.disabled }

  var opacity: CGFloat { permission?.authorized == false ? 0.6 : 1.0 }

  var display: MediaDisplay {
    if let forceDisplay = forceDisplay {
      return forceDisplay
    }

    let aspectRatio = forceAspectRatio.lowercased()

    if aspectRatio == "landscape" {
      return .video
    } else if aspectRatio == "portrait" {
      return .feature
    } else if aspectRatio == "square" {
      return .square
    }

    switch viewItem.thumb_aspect_ratio {
    case .portrait: return .feature
    case .landscape: return .video
    default: return .square
    }
  }

  var title: String {
    return viewItem.title.nilIfEmpty()
      ?? viewItem.sectionItem?.media?.title?.nilIfEmpty()
      ?? viewItem.mediaItem?.title ?? ""
  }

  @State var subtitle: String = ""

  @State var mediaProgress: MediaProgress?
  @State var isVisible: Bool = false
  @State var refreshId = UUID()

  var progressText: String {
    guard let progress = mediaProgress else {
      return ""
    }

    let left = progress.duration_s - progress.current_time_s
    let timeStr = left.asTimeString(style: .abbreviated)
    return "\(timeStr) left"
  }

  var progressValue: Double {
    if !isLive {
      guard let progress = mediaProgress else {
        return 0.0
      }

      if progress.duration_s != 0 {
        return progress.current_time_s / progress.duration_s
      }
    }
    return 0.0
  }

  func updateProgress() {
    if !isVisible {
      return
    }
    Task {
      do {
        let mediaId = viewItem.media_id
        if let account = eluvio.accountManager.currentAccount {
          let progress = try eluvio.fabric.getUserViewedProgress(
            address: account.getAccountAddress(), mediaId: mediaId)
          if progress.current_time_s > 0 {
            // debugPrint("Found saved progress ", progress)
            await MainActor.run {
              self.mediaProgress = progress
            }
          }
        }

      } catch {
        print("MediaView could not create MediaItemViewModel ", error)
      }
    }
  }

  var body: some View {
    Group {
      // Trigger a re-render when refreshId changed, without causing the entire view to be considered "new"
      Color.clear.id(refreshId).frame(height: 0)

      if !hide {
        VStack(alignment: .leading, spacing: 10) {
          Text(title).font(.system(size: 1)).hidden()  // This is needed for some reason single items in a section didn't show
          Button(action: {
            if disable { return }
            Task {
              await handleSectionItemTap(
                router: router, eluvio: eluvio,
                property: property, pageId: pageId, sectionId: sectionId,
                viewItem: viewItem)
            }
          }) {
            MediaCard(
              display: display,
              image: imageThumbnail,
              isFocused: isFocused,
              isUpcoming: isUpcoming,
              startTimeString: startTimeString,
              title: viewItem.title,
              subtitle: viewItem.subtitle,
              timeString: viewItem.headerString,
              isLive: isLive,
              centerFocusedText: false,
              showFocusedTitle: viewItem.title.isEmpty ? false : true,
              showBottomTitle: true,
              progressValue: progressValue,
              sizeFactor: scaleFactor,
              permission: permission
            )
            .opacity(opacity)
          }
          .buttonStyle(TitleButtonStyle(focused: isFocused, scale: 1.0))
          .focused($isFocused)
        }
      }
    }
    .task(id: timeTillLiveStateChange) {
      await refreshWhenLiveStatusChanges()
    }
    .onScrollVisibilityChange(threshold: 0.5) { isVisible in
      self.isVisible = isVisible
      if isVisible {
        Task(priority: .background) {
          updateProgress()
        }
      }
    }
  }

  private func refreshWhenLiveStatusChanges() async {
    let id = media?.id ?? "unknown_mvid"
    guard let wait = timeTillLiveStateChange, wait > 0 else {
      printLiveStatus("No live status change expected for \(id).")
      return
    }
    printLiveStatus("Live status of \(id) will change in \(wait) seconds - queueing refresh")
    if (try? await Task.sleep(for: .seconds(wait))) != nil {
      // Only refresh on a successful wait, not if the task is cancelled
      printLiveStatus("Live status of \(id) changed. Triggering refresh.")
      refreshId = UUID()
    } else {
      printLiveStatus("Queued refresh for \(id) cancelled.")
    }
  }

  private func printLiveStatus(_ message: String) {
    // This gets really verbose, but useful for debugging.
    // Commented out while not needed:
    //    debugPrint(message)
  }

  private var media: MediaPropertySectionMediaItem? {
    viewItem.sectionItem?.media ?? viewItem.mediaItem
  }
  var imageThumbnail: String { viewItem.thumbnail }
  var isUpcoming: Bool { media?.isUpcoming == true }
  var isLive: Bool { media?.currentlyLive == true }
  var startTimeString: String { media?.startDateTimeString ?? "" }

  private var timeTillLiveStateChange: TimeInterval? {
    guard let media = media else { return nil }
    return if media.hasEnded {
      // Stream ended, no more changes.
      nil
    } else if media.hasStarted {
      // Stream started, next change is Stream End
      media.endDate?.timeIntervalSinceNow
    } else {
      // Stream hasn't started yet. Next change is Stream Start
      media.streamStartDate?.timeIntervalSinceNow
    }
  }
}
