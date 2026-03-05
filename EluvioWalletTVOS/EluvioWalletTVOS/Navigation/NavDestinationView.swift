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
    case .html(let params):
      QRView(
        url: params.viewItem?.media_file_url ?? params.url, backgroundImage: params.backgroundImage,
        title: params.title)
    case .purchaseQRView(let params):
      PurchaseView(backgroundImage: params.backgroundImage, propertyId: params.propertyId)

    case .video(let params):
      PlayerView(
        viewItem: params.viewItem,
        property: params.property,
        playout: params.playout
      )
    case .upcomingLiveEvent(let params):
      CountDownView(
        mediaItem: params.mediaItem,
        propertyId: params.propertyId)
    case .videoPermissionError(let params):
      PlayerErrorView(propertyId: params.propertyId)
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
    case .gallery(let items):
      GalleryView(gallery: items)
    case .search(let params):
      SearchView(propertyId: params.propertyId)
    case .sectionViewAll(let params):
      ScrollView {
        SectionGridView(
          property: params.property, pageId: params.pageId,
          section: params.section, margin: 80, showBackground: false, topPadding: 40
        )
      }
      .scrollClipDisabled()
      .edgesIgnoringSafeArea(.all)
    case .nft(let nft):
      ItemDetailView(item: nft)
    case .errorView(let msg):
      Text(msg)
        .font(.title)
        .background(.black)
        .edgesIgnoringSafeArea(.all)
    case .imageView(let params):
      MediaItemView(viewItem: params.viewItem)
        .edgesIgnoringSafeArea(.all)
    case .login(let params):
      OryDeviceFlowView(property: params.property)
    case .progress:
      ProgressView()
        .edgesIgnoringSafeArea(.all)
    case .black:
      Color.black
        .edgesIgnoringSafeArea(.all)
    #if DEBUG
      case .debugMenu:
        DebugMenuView()
    #endif
    }
  }
}
