//
//  NFTView.swift
//  NFTView
//
//  Created by Wayne Tran on 2021-08-11.


import SwiftUI
import SDWebImageSwiftUI

struct NFTAlbumView: View {
    @State var nft = NFTModel()
    var isForsale = false
    @State private var buttonFocus: Bool = false
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.album
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(destination: NFTDetail(nft: nft)) {
                MediaCard(display:display, image:  nft.meta.image)
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
        /*
            Text(nft.meta.displayName)
                .foregroundColor(Color.white)
                .lineLimit(3)
                .font(.caption)
                .frame(width: 300, height: 80, alignment: .topLeading)
         */
        }

    }
}

struct NFTView: View {
    @State var nft = NFTModel()
    var isForsale = false
    @State private var buttonFocus: Bool = false
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.feature
    
    var body: some View {
        NavigationLink(destination: NFTDetail(nft: nft)) {
            VStack() {
                WebImage(url: URL(string: nft.meta.image))
                    .resizable()
                        .scaledToFill()
                        //.frame(width:500, height: 500)
                        .clipped()
                VStack(alignment: .leading, spacing: 7) {
                    Text(nft.meta.displayName)
                        .foregroundColor(Color.white)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
            }
        }
        .buttonStyle(TitleButtonStyle(focused: isFocused))
        .focused($isFocused)
    }
}


struct NFTView_Previews: PreviewProvider {
    static var previews: some View {
        NFTView(nft: test_NFTs[0])
            .listRowInsets(EdgeInsets())
    }
}
