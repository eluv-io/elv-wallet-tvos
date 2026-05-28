import Foundation

enum NavDestination: Hashable {
  case property(PropertyParam)
  case video(VideoParams)
  case gallery([GalleryItem])
  case mediaGrid(MediaGridParams)
  case html(HtmlParams)
  case search(SearchParams)
  case sectionViewAll(SectionViewAllParams)
  case nft(NFTModel)
  case videoPermissionError(VideoPermissionErrorParams)
  case upcomingLiveEvent(UpcomingVideoParams)
  case login(LoginParam)
  case errorView(String)
  case progress, black
  case purchaseQRView(PurchaseParams)
  case imageView(ImageParams)
  case profile

  #if DEBUG
    case debugMenu
  #endif
}
