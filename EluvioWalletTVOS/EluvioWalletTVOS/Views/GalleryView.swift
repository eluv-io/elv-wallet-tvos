//
//  GalleryView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import SwiftUI
import SwiftyJSON
import AVKit
import SDWebImageSwiftUI

struct GalleryItemView: View {
    @EnvironmentObject var fabric: Fabric
    @State var media: GalleryItem? = nil
    @State var imageUrl: String = "https://picsum.photos/600/800"
    @Binding var currentImageUrl : String
    @FocusState var isFocused
    
    var body: some View {
            Button(action: {

            }) {
                /*
                CacheAsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame( width: 200, height: 200)
                        .cornerRadius(15)
                } placeholder: {
                    ProgressView()
                }
                 */
                WebImage(url: URL(string: imageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame( width: 200, height: 200)
                    .cornerRadius(15)
                
            }
            .buttonStyle(GalleryButtonStyle(focused: isFocused))
            .focused($isFocused)
            .onChange(of: isFocused) { newValue in
                if newValue {
                    self.currentImageUrl = self.imageUrl
                }
            }
            .onAppear(){
                //print("Gallery Item: ", self.media)
                
                if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
                    self.imageUrl = "https://picsum.photos/600/800"
                    self.currentImageUrl = "https://picsum.photos/1000/1000"
                }else{
                    do {
                        self.imageUrl = try fabric.getUrlFromLink(link: media?.image)
                        print("Gallery Image URL: ", self.imageUrl)
                    }catch{
                        print("Error getting image URL from link ", media?.image as Any)
                    }
                }
            }
        
    }
}

struct GalleryView: View {
    @EnvironmentObject var fabric: Fabric
    @Binding var gallery: [GalleryItem]
    @State var currentImageUrl : String = ""
    
    var body: some View {
            VStack{
                Spacer()
                ScrollView(.horizontal) {
                    HStack(alignment: .bottom, spacing: 20) {
                        ForEach(self.gallery) {galleryItem in
                            GalleryItemView(media: galleryItem, currentImageUrl: $currentImageUrl)
                        }
                    }
                    .padding(50)
                }
            }
            .background(){
                WebImage(url: URL(string: currentImageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
                
            }
        }
}


struct GalleryView_Previews: PreviewProvider {
    
    @State static var test : [GalleryItem] = [
        GalleryItem(),
        GalleryItem(),
        GalleryItem(),
        GalleryItem(),
        GalleryItem(),
        GalleryItem(),
    ]
    
    static var previews: some View {
        GalleryView(gallery: $test)
    }
}
