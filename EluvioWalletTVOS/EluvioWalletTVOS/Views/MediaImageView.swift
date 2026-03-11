import AVKit
import SwiftUI
import SwiftyJSON

struct MediaItemView: View {
  var viewItem: MediaPropertySectionMediaItemViewModel

  var url: String { viewItem.thumbnail }
  var title: String { viewItem.title }

  var body: some View {
    ZStack {
      HStack(alignment: .center) {
        Spacer()
        ScaledWebImage(url: url, height: UIScreen.main)
          .resizable()
          .scaledToFit()
          .background(.black)
        Spacer()
      }

      if !title.isEmpty {
        VStack {
          Spacer()
          VStack(alignment: .center) {
            Text(title).font(.title3)
              .lineLimit(2)
              .padding(40)
              .padding([.leading, .trailing], 80)
          }
          .frame(maxWidth: .infinity)
          .edgesIgnoringSafeArea(.all)
          .background(.black.opacity(0.6))
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
      }
    }
    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    .edgesIgnoringSafeArea(.all)
  }
}
