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
    var shadowRadius: CGFloat {
        if isFocused {
            return 10
        }else{
            return 3
        }
    }
    
    var titleColor: Color {
        if isFocused {
            return Color.black
        }else{
            return Color.white
        }
    }
    
    var subTitleColor: Color {
        if isFocused {
            return Color.black.opacity(0.5)
        }else{
            return Color.gray
        }
    }
    
    var propertyLogo: String {
        return nft.property?.logo ?? ""
    }
    var propertyName: String {
        return nft.property?.title ?? ""
    }
    
    var logoBrightness: CGFloat {
        if isFocused {
            return -0.5
        }else{
            return 0
        }
    }
    
    var body: some View {
        NavigationLink(destination: NFTDetail(nft: nft)) {
            ZStack{
                Image("item-dark").resizable()
                    .overlay{
                        if isFocused{
                            Image("item-highlight").resizable()
                        }
                    }

                VStack() {
                    HStack(alignment:.center, spacing:10){
                        if(propertyLogo.hasPrefix("http")){
                            WebImage(url: URL(string: propertyLogo))
                                .resizable()
                                .indicator(.activity) // Activity Indicator
                                .transition(.fade(duration: 0.5))
                                .scaledToFill()
                                .cornerRadius(3)
                                .frame(width:40, height: 40, alignment: .center)
                                .clipped()
                                .brightness(logoBrightness)
                        }else {
                            Image(propertyLogo)
                                .resizable()
                                .scaledToFill()
                                .cornerRadius(3)
                                .frame(width:40, height: 40, alignment: .center)
                                .clipped()
                                .brightness(logoBrightness)
                        }
                        
                        Text(propertyName).foregroundColor(subTitleColor).font(.itemSubtitle)
                        Spacer()
                        Text("#\(nft.token_id_str)").foregroundColor(subTitleColor).font(.itemSubtitle)
                    }
                    .padding(.bottom)
                    WebImage(url: URL(string: nft.meta.image))
                        .resizable()
                        .indicator(.activity) // Activity Indicator
                        .transition(.fade(duration: 0.5))
                        .scaledToFill()
                        .cornerRadius(3)
                        .frame(width: 420, height: 420, alignment: .center)
                        .clipped()
                    
                    VStack(alignment: .center, spacing: 7) {
                        Spacer()
                        Text(nft.meta.displayName)
                            .foregroundColor(titleColor)
                            .font(.itemTitle)
                        Text(nft.meta.editionName)
                            .foregroundColor(subTitleColor)
                            .font(.itemSubtitle)
                            .textCase(.uppercase)
                        
                        Spacer()
                    }
                    
                    if (isFocused){}
                    
                }
                .padding(30)
            }
            .shadow(radius: shadowRadius)
        }
        .frame(width: 480, height: 700)
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
