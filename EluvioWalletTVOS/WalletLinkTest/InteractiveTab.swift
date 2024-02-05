//
//  InteractiveTab.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-02-01.
//

import SwiftUI
import SDWebImageSwiftUI

struct MediaTabItemView: View {
    @Binding var item : InteractiveMediaItem
    @Binding var selected: Bool
    @Binding var selectedItem: InteractiveMediaItem
    @FocusState var isFocused
    var width : CGFloat = 100
    var body: some View {
        VStack(spacing:10){
            Button{
                selectedItem = item
                selected = true
            } label: {
                if let image = item.image {
                    Image(uiImage:image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    //.frame(width:width, height:width)
                }else{
                    ZStack{
                        Rectangle()
                            .background(.gray)
                            .frame(width:width, height:width)
                        VStack{
                            Image(systemName: "play.rectangle")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width:width/2, height:width/2)
                                .padding()
                        }
                    }
                }
            }
            .buttonStyle(.card)
            .focused($isFocused)
            .frame(width:width, height:width*0.8)
            
            Text(item.name)
                .font(.fine)
                //.padding()
                .frame(width:width*2)
                .lineLimit(1)
        }
        .frame(width:width, height:width)
    }
}

struct InteractiveTab: View {
    @State var items: [InteractiveMediaItem]
    @State var selectedItem = InteractiveMediaItem()
    var imageWidth : CGFloat = 100
    @State var showItem = false
    
    var body: some View {
        VStack(alignment:.center){
            ScrollView(.horizontal) {
                LazyHStack(spacing:imageWidth) {
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
        .focusSection()
        .fullScreenCover(isPresented: $showItem){ [selectedItem] in
            InteractiveMediaView(item: selectedItem)
        }
    }
}
