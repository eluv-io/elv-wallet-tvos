//
//  InteractiveTab.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-02-01.
//

import SwiftUI
import SDWebImageSwiftUI

struct MediaTabItemView: View {
    @Binding var item : MediaItem
    @Binding var selected: Bool
    @Binding var selectedItem: MediaItem
    var width : CGFloat = 400
    var body: some View {
        Button{
            selectedItem = item
            selected = true
        } label: {
            WebImage(url: URL(string:item.image ?? ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width:width, height:width*2)
                .padding()
        }
        .buttonStyle(.borderless)
        .frame(width:width, height:width*2)
    }
}

struct InteractiveTab: View {
    @State var items: [MediaItem]
    @State var selectedItem = MediaItem()
    var imageWidth : CGFloat = 250
    @State var showItem = false
    
    var body: some View {
        VStack(alignment:.center){
            ScrollView(.horizontal) {
                LazyHStack(spacing:imageWidth * 0.7) {
                    ForEach(0..<items.count, id: \.self) { index in
                        MediaTabItemView(item: $items[index], selected: $showItem, selectedItem: $selectedItem, width: imageWidth)
                            .padding()
                    }
                }
                .frame(maxWidth:.infinity)
                .padding()
            }
            .scrollClipDisabled()
            .padding()
        }
        .padding(.top,20)
        .fullScreenCover(isPresented: $showItem){ [selectedItem] in
            if selectedItem.name != "" {

            }else if let item = selectedItem as? InteractiveMediaItem{
                InteractiveMediaView(item: item)
            }
        }
    }
}
