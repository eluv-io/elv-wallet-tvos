//
//  ThumbnailView.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-02-01.
//

import SwiftUI

struct ThumbnailItem: Identifiable {
    var id: String? = UUID().uuidString
    var page: Int = 0
    var image: UIImage
}

struct ThumbnailItemView: View {
    @State var item1: ThumbnailItem? = nil
    @State var item2: ThumbnailItem? = nil
    @FocusState var isFocused
    @Binding var page: Int
    var width: CGFloat = 80
    var height: CGFloat = 80
    //Need to be an array because it is a struct and can't reference itself
    @Binding var selectedView: [ThumbnailItemView]
    
    var selected : Bool {
        if let item = self.item1 {
            return page == item.page
        }
        return false
    }
    
    var body: some View {
        Button(action: {

        }) {
            HStack(spacing:0){
                if (item1 != nil){
                    Image(uiImage: item1?.image ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame( width: width, height: height, alignment: .top)
                        .clipped()
                }
                if (item2 != nil){
                    Image(uiImage: item2?.image ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame( width: width, height: height, alignment:.top)
                        .clipped()
                }
            }
        }
        .buttonStyle(ThumbnailButtonStyle(focused: isFocused, selected: selected))
        .focused($isFocused)
        .onChange(of: isFocused) {
            if (isFocused){
                if let item = self.item1 {
                    debugPrint("page ", page)
                    debugPrint("item.page", item.page)
                    if (abs(page - item.page) > 2){
                        debugPrint("selectedView count ", selectedView.count)
                        if selectedView.count == 1 {
                            selectedView[0].isFocused = true
                            debugPrint("Setting focus")
                        }else{
                            debugPrint("Setting page, no selected view")
                            page = item.page
                        }
                    }else {
                        debugPrint("Selecting page ", page)
                        page = item.page
                    }
                }
            }
        }
        .onChange(of:page) {
            if let item = self.item1 {
                if selected{
                    debugPrint("ThumbnailItemView onChange page: ", page)
                    debugPrint("Selected ")
                    if(selectedView.count == 0){
                        selectedView.append(self)
                    }else{
                        selectedView[0] = self
                    }
                }
            }
        }
        .onAppear(){
            if selected {
                debugPrint("ThumbnailItemView onAppear page: ", page)
                //isFocused = true
                if(selectedView.count == 0){
                    selectedView.append(self)
                }else{
                    selectedView[0] = self
                }
            }
        }
    }
}


struct ThumbnailRowView: View {
    @State var thumbs : [ThumbnailItem] = []
    @State var selectedView: [ThumbnailItemView] = []
    @Binding var page : Int
    var thumbWidth : CGFloat = 50
    var thumbHeight: CGFloat = 80
    @FocusState var isFocused
    
    var body: some View {
        ScrollViewReader { value in
            ScrollView(.horizontal) {
                LazyHStack(spacing:thumbWidth*0.2) {
                    ThumbnailItemView(item1:thumbs[0], item2: nil, page:$page, width:thumbWidth, height:thumbHeight, selectedView: $selectedView)
                    
                    ForEach(Array(stride(from: 1, to: thumbs.count, by: 2)), id: \.self) { index in
                        HStack(spacing:0){
                            ThumbnailItemView(item1:thumbs[index], item2: index + 1 < thumbs.count ? thumbs[index+1] : nil, page:$page, width:thumbWidth, height:thumbHeight, selectedView: $selectedView)
                        }
                        .id(index)
                    }
                }
            }
            .scrollClipDisabled()
            .onChange(of:page) {
                debugPrint("ThumbnailRowView onChange page ", page)
                withAnimation {
                    value.scrollTo(page-1)
                }
            }
            .onAppear(){
                debugPrint("ThumbnailRowView onAppear ", page)
                withAnimation {
                    value.scrollTo((page-1))
                }
            }
        }
    }
}
