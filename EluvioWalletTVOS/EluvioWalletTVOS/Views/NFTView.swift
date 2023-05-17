//
//  NFTView.swift
//  NFTView
//
//  Created by Wayne Tran on 2021-08-11.


import SwiftUI
import SDWebImageSwiftUI

struct NFTView: View {
    @State var nft = NFTModel()
    var isForsale = false
    @State private var buttonFocus: Bool = false
    @FocusState var isFocused
    
    var body: some View {
        NavigationLink(destination: NFTDetail(nft: nft)) {
            VStack() {
                WebImage(url: URL(string: nft.meta.image))
                    .resizable()
                        .scaledToFill()
                        //.frame(width:500, height: 500)
                        .clipped()
            }
        }
        .buttonStyle(PrimaryButtonStyle(focused: isFocused))
        .focused($isFocused)
    }
}


struct NFTView_Previews: PreviewProvider {
    static var previews: some View {
        NFTView(nft: test_NFTs[0])
            .listRowInsets(EdgeInsets())
    }
}
