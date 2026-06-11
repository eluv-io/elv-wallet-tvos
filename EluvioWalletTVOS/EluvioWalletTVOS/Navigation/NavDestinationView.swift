import EluvioCore
import FirebaseAnalytics
import SwiftUI

extension NavDestination {
  @ViewBuilder
  func view() -> some View {
    switch self {
    case .property(let params):
      MediaPropertyDetailView(
        propertyId: params.propertyId, pageId: params.pageId, propertyLinks: params.propertyLinks
      )
      .id([params.propertyId, params.pageId])
      .analyticsScreen(name: "MediaPropertyDetailView")
    case .html(let params):
      QRView(
        url: params.viewItem?.media_file_url ?? params.url, backgroundImage: params.backgroundImage,
        title: params.title
      )
      .analyticsScreen(name: "QRView")
    case .purchaseQRView(let params):
      PurchaseView(backgroundImage: params.backgroundImage, propertyId: params.propertyId)
        .analyticsScreen(name: "PurchaseView")
    case .video(let params):
      PlayerView(
        viewItem: params.viewItem,
        property: params.property,
        playout: params.playout
      )
      .analyticsScreen(name: "PlayerView")
    case .upcomingLiveEvent(let params):
      CountDownView(
        mediaItem: params.mediaItem,
        propertyId: params.propertyId
      )
      .analyticsScreen(name: "CountDownView")
    case .videoPermissionError(let params):
      PlayerErrorView(propertyId: params.propertyId)
        .analyticsScreen(name: "PlayerErrorView")
    case .mediaGrid(let params):
      ScrollView {
        if !params.mediaItemIds.isEmpty {
          SectionItemListView(
            property: params.property, mediaItemIds: params.mediaItemIds,
            title: params.title, parentMediaItem: params.parentMediaItem
          )
          .edgesIgnoringSafeArea(([.leading, .trailing]))
        }
      }
      .scrollClipDisabled()
      .edgesIgnoringSafeArea([.leading, .trailing])
      .analyticsScreen(name: "SectionItemListView")
    case .gallery(let items):
      GalleryView(gallery: items)
        .analyticsScreen(name: "GalleryView")
    case .search(let params):
      SearchView(propertyId: params.propertyId)
        .analyticsScreen(name: "SearchView")
    case .sectionViewAll(let params):
      ScrollView {
        SectionGridView(
          property: params.property, pageId: params.pageId,
          section: params.section, margin: 80, showBackground: false, topPadding: 40
        )
      }
      .scrollClipDisabled()
      .edgesIgnoringSafeArea(.all)
      .analyticsScreen(name: "SectionGridView")
    case .nft(let nft):
      ItemDetailView(item: nft)
    case .errorView(let msg):
      Text(msg)
        .font(.title)
        .background(.black)
        .edgesIgnoringSafeArea(.all)
        .analyticsScreen(name: "ErrorView")
    case .imageView(let params):
      MediaItemView(viewItem: params.viewItem)
        .edgesIgnoringSafeArea(.all)
        .analyticsScreen(name: "MediaItemView")
    case .login(let params):
      OryDeviceFlowView(property: params.property)
        .analyticsScreen(name: "OryDeviceFlowView")
    case .progress:
      ProgressView()
        .edgesIgnoringSafeArea(.all)
        .analyticsScreen(name: "ProgressView")
    case .black:
      Color.black
        .edgesIgnoringSafeArea(.all)
    case .profile:
      ProfileView()
        .analyticsScreen(name: "ProfileView")
    #if DEBUG
      case .debugMenu:
        DebugMenuView()
    #endif
    }
  }
}
