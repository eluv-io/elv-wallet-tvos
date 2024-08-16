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
                MediaCard(display:display, image:nft.meta.image ?? "", isFocused:isFocused, title:nft.meta.name ?? "")
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
        }

    }
}

struct NFTTileView: View {
    @State var nft = NFTModel()
    var isForsale = false
    @State private var buttonFocus: Bool = false
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.tile
    
    var image : String {
        if (display == MediaDisplay.tile){
            //print("TILE: ", nft.title_image ?? "")
            return nft.title_image ?? nft.meta.image ?? ""
        }
        return nft.meta.image ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(destination: NFTDetail(nft: nft)) {
                MediaCard(display:display, image:image, isFocused:isFocused, title:nft.meta.name ?? "")
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused, scale:1.02))
            .focused($isFocused)
        }

    }
}


struct DropView<DestinationType: View>: View {
    @State var nft = NFTModel()
    @State private var buttonFocus: Bool = false
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.property
    
    var image = ""
    var title = ""
    var destination: DestinationType
    var scale: CGFloat = 1.0
    var width :CGFloat {
        return 480*scale
    }
    
    var height :CGFloat {
        return 660*scale
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(destination: destination) {
                MediaCard(display:display, image:image, isFocused:isFocused, title:title)
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused, scale:1.02))
            .focused($isFocused)
        }

    }
}


struct NFTView<DestinationType: View>: View {
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
    var image = ""
    var title = ""
    var subtitle = ""
    var propertyLogo = ""
    var propertyName = ""
    var tokenId = ""
    var tokenDisplay : String {
        if tokenId.isEmpty {
            return ""
        }
        
        if tokenId.hasPrefix("#") {
            return tokenId
        }
        
        return "#\(tokenId)"
    }
    var destination: DestinationType
    var scale: CGFloat = 1.0
    var width :CGFloat {
        return 480*scale
    }
    
    var height :CGFloat {
        return 660*scale
    }
    
    var logoBrightness: CGFloat {
        if isFocused {
            return -0.5
        }else{
            return 0
        }
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            ZStack{
                Image("dark-item-top-radial").resizable()
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
                        }else if (propertyLogo != ""){
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
                        Text(tokenDisplay).foregroundColor(subTitleColor).font(.itemSubtitle)
                    }
                    .padding(.bottom)
                    if (image.hasPrefix("http")){
                        WebImage(url: URL(string: image))
                            .resizable()
                            .indicator(.activity) // Activity Indicator
                            .transition(.fade(duration: 0.5))
                            .scaledToFill()
                            .cornerRadius(3)
                            .frame(width: 420, height: 420, alignment: .center)
                            .clipped()
                    }else {
                        Image(image)
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(3)
                            .frame(width: 420, height: 420, alignment: .center)
                            .clipped()
                    }
                    
                    VStack(alignment: .center, spacing: 7) {
                        Spacer()
                        Text(title)
                            .foregroundColor(titleColor)
                            .font(.itemTitle)
                        Text(subtitle)
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
        .scaleEffect(scale)
        .frame(width: width, height: height)
        .buttonStyle(TitleButtonStyle(focused: isFocused))
        .focused($isFocused)
    }
}

struct NFTView2: View {
    @EnvironmentObject var pathState: PathState
    var nft : NFTModel = NFTModel()
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

    var image : String {
        nft.meta.image ?? ""
    }
    var title : String {
        nft.meta.displayName ?? ""
    }
    
    var subtitle : String {
        nft.meta.editionName ?? ""
    }
    
    var propertyLogo : String {
        nft.property?.logo ?? ""
    }
    var propertyName : String {
        nft.property?.title ?? ""
    }
    var tokenId : String {
        "#" + (nft.token_id_str ?? "")
    }
    
    
    var tokenDisplay : String {
        if tokenId.isEmpty {
            return ""
        }
        
        if tokenId.hasPrefix("#") {
            return tokenId
        }
        
        return "#\(tokenId)"
    }
    var scale: CGFloat = 1.0
    var width :CGFloat {
        return 480*scale
    }
    
    var height :CGFloat {
        return 660*scale
    }
    
    var logoBrightness: CGFloat {
        if isFocused {
            return -0.5
        }else{
            return 0
        }
    }
    
    var body: some View {
        Button(action:{
            pathState.nft = nft
            pathState.path.append(.nft)
        }) {
            ZStack{
                Image("dark-item-top-radial").resizable()
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
                        }else if (propertyLogo != ""){
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
                        Text(tokenDisplay).foregroundColor(subTitleColor).font(.itemSubtitle)
                    }
                    .padding(.bottom)
                    if (image.hasPrefix("http")){
                        WebImage(url: URL(string: image))
                            .resizable()
                            .indicator(.activity) // Activity Indicator
                            .transition(.fade(duration: 0.5))
                            .scaledToFill()
                            .cornerRadius(3)
                            .frame(width: 420, height: 420, alignment: .center)
                            .clipped()
                    }else {
                        Image(image)
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(3)
                            .frame(width: 420, height: 420, alignment: .center)
                            .clipped()
                    }
                    
                    VStack(alignment: .center, spacing: 7) {
                        Spacer()
                        Text(title)
                            .foregroundColor(titleColor)
                            .font(.itemTitle)
                        Text(subtitle)
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
        .scaleEffect(scale)
        .frame(width: width, height: height)
        .buttonStyle(TitleButtonStyle(focused: isFocused))
        .focused($isFocused)
    }
}

struct NFTView_Previews: PreviewProvider {
    static var previews: some View {
        NFTView<NFTDetail>(
            image: test_NFTs[0].meta.image ?? "",
            title: test_NFTs[0].meta.displayName ?? "",
            subtitle: test_NFTs[0].meta.editionName ?? "",
            propertyLogo: test_NFTs[0].property?.image ?? "",
            propertyName: test_NFTs[0].property?.title ?? "",
            tokenId: test_NFTs[0].token_id_str ?? "",
            destination: NFTDetail(nft: test_NFTs[0]))
            .listRowInsets(EdgeInsets())
    }
}
