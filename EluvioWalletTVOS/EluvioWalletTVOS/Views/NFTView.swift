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
                MediaCard(display:display, imageUrl:nft.meta.image, isFocused:isFocused, title:nft.meta.name)
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
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
            ZStack() {
                WebImage(url: URL(string: nft.meta.image))
                    .resizable()
                    .indicator(.activity) // Activity Indicator
                    .transition(.fade(duration: 0.5))
                    .scaledToFill()
                    .clipped()
                    .cornerRadius(3)
                
                if (isFocused){
                    VStack(alignment: .leading, spacing: 7) {
                        Spacer()
                        Text(nft.meta.displayName.capitalized)
                            .foregroundColor(Color.white)
                            .font(.subheadline)
                        Text(nft.meta.editionName.capitalized)
                            .foregroundColor(Color.white)
                        Spacer()
                    }
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
                    .padding(40)
                    .background(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.highlight, lineWidth: 4)
                    )
                }
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
