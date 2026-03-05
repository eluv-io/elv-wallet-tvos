//
//  GalleryView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import AVKit
import SDWebImageSwiftUI
import SwiftUI
import SwiftyJSON

struct GalleryItemView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  var media: GalleryItem? = nil
  @State var imageUrl: String = "https://picsum.photos/600/800"
  @Binding var currentImageUrl: String
  @FocusState var isFocused

  var body: some View {
    Button(action: {}) {
      WebImage(url: URL(string: imageUrl))
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 200, height: 200)
        .cornerRadius(15)
    }
    .buttonStyle(GalleryButtonStyle(focused: isFocused))
    .focused($isFocused)
    .onChange(of: isFocused) { newValue in
      if newValue {
        self.currentImageUrl = self.imageUrl
      }
    }
    .onAppear {
      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        self.imageUrl = "https://picsum.photos/600/800"
        self.currentImageUrl = "https://picsum.photos/1000/1000"
      } else {
        if let url = media?.thumbnail?.url {
          print("Gallery Image URL: ", url)
          self.imageUrl = url
        } else {
          print("Error getting image URL from link ", media?.thumbnail as Any)
        }
      }
    }
  }
}

struct GalleryView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  var gallery: [GalleryItem]
  @State var currentImageUrl: String = ""

  var body: some View {
    VStack {
      Spacer()
      ScrollView(.horizontal) {
        HStack(alignment: .bottom, spacing: 20) {
          ForEach(self.gallery) { galleryItem in
            GalleryItemView(media: galleryItem, currentImageUrl: $currentImageUrl)
          }
        }
        .padding(50)
      }
    }
    .background {
      WebImage(url: URL(string: currentImageUrl))
        .resizable()
        .aspectRatio(contentMode: .fit)
        .edgesIgnoringSafeArea(.all)
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Gallery View") {
  GalleryView(gallery: [
    GalleryItem(),
    GalleryItem(),
    GalleryItem(),
    GalleryItem(),
    GalleryItem(),
    GalleryItem(),
  ])
  .environmentObject(EluvioAPI())
}
