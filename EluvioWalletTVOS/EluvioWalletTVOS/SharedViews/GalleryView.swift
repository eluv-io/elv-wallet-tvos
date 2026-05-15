//
//  GalleryView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import AVKit
import EluvioCore
import SwiftUI
import SwiftyJSON

struct GalleryItemView: View {
  var media: GalleryItem? = nil
  @State var imageUrl: String = ""
  @Binding var currentImageUrl: String
  @FocusState var isFocused

  var body: some View {
    Button(action: {}) {
      ScaledWebImage(url: imageUrl, height: 200)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 200, height: 200)
        .cornerRadius(15)
    }
    .buttonStyle(GalleryButtonStyle(focused: isFocused))
    .focused($isFocused)
    .onChange(of: isFocused) { _, newValue in
      if newValue {
        self.currentImageUrl = self.imageUrl
      }
    }
    .onAppear {
      if let url = media?.thumbnail?.url {
        print("Gallery Image URL: ", url)
        self.imageUrl = url
      } else {
        print("Error getting image URL from link ", media?.thumbnail as Any)
      }
    }
  }
}

struct GalleryView: View {
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
      ScaledWebImage(url: currentImageUrl, height: UIScreen.main)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .edgesIgnoringSafeArea(.all)
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Gallery View") {
  GalleryView(
    gallery: (0...5).map { i in
      var item = GalleryItem()
      item.thumbnail = ImageLink.test()
      return item
    }
  )
  .environmentObject(EluvioAPI())
}
