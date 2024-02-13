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
    var width : CGFloat = 200
    var height : CGFloat = 200
    
    var body: some View {
        VStack(spacing:20){
            Button{
                selectedItem = item
                selected = true
            } label: {
                if let image = item.image {
                    Image(uiImage:image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width:width, height: height)
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
            .buttonStyle(.borderless)
            .focused($isFocused)
            //.frame(width:width, height:height)
            
            Text(item.name)
                .font(.fine)
                //.padding()
                .frame(width:width*2)
                .lineLimit(2)
        }
 //       .frame(width:width, height:height)
    }
}

struct InteractiveTab: View {
    @State var items: [InteractiveMediaItem]
    @State var selectedItem = InteractiveMediaItem()
    var imageWidth : CGFloat = 160
    @State var showItem = false
    
    var body: some View {
        VStack(alignment:.center){
            ScrollView(.horizontal) {
                LazyHStack(spacing:40) {
                    ForEach(0..<items.count, id: \.self) { index in
                        MediaTabItemView(item: $items[index], selected: $showItem, selectedItem: $selectedItem, width: imageWidth, height: 130)
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
