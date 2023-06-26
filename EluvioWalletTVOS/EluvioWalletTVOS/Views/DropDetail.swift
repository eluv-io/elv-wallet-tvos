//
//  DropDetail.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-06-07.
//

import SwiftUI
import SwiftyJSON
import AVKit
import SDWebImageSwiftUI

struct DropDetail: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @State var drop : ProjectModel
    @State var backgroundImageUrl : String = ""
    @FocusState var isFocused
    @FocusState private var headerFocused: Bool
    
    @State var playerImageOverlayUrl : String = ""
    @State var playerTextOverlay : String = ""
    @State var showPlayer = false
    @State var playerItem : AVPlayerItem? = nil
    @State var playerFinished = false
    
    var body: some View {
        ZStack(alignment:.topLeading) {
            if (self.backgroundImageUrl.hasPrefix("http")){
                WebImage(url: URL(string: self.backgroundImageUrl))
                    .resizable()
                    .indicator(.activity) // Activity Indicator
                    .transition(.fade(duration: 0.5))
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
                    .frame(alignment: .topLeading)
                    .clipped()
            }else if(self.backgroundImageUrl != "") {
                Image(self.backgroundImageUrl)
                    .resizable()
                    .transition(.fade(duration: 0.5))
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
                    .frame(alignment: .topLeading)
                    .clipped()
            }else{
                Rectangle().foregroundColor(Color.clear)
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Button{} label: {
                        VStack(alignment: .leading, spacing: 40)  {
                            Text(drop.title ?? "").font(.title3)
                                .foregroundColor(Color.white)
                                .fontWeight(.bold)
                                .frame(maxWidth:1500, alignment:.leading)

                            Text(drop.description ?? "")
                                .foregroundColor(Color.white)
                                .frame(maxWidth:1200, alignment:.leading)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($headerFocused)
                    
                    
                    if (!drop.contents.isEmpty){
                        VStack(alignment: .leading, spacing: 40){
                            ScrollView (.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .top, spacing: 20) {
                                    ForEach(drop.contents) { nft in
                                         NFTView<NFTPlayerView>(
                                             image: nft.meta.image ?? "",
                                             title: nft.meta.displayName ?? "",
                                             subtitle: nft.meta.editionName ?? "",
                                             propertyLogo: nft.property?.logo ?? "",
                                             propertyName: nft.property?.title ?? "",
                                             tokenId: nft.token_id_str ?? "",
                                             destination: NFTPlayerView(nft:nft),
                                             scale: 0.72
                                         )
                                    }
                                }
                            }
                            .introspectScrollView { view in
                                view.clipsToBounds = false
                            }
                        }
                        .focusSection()
                    }
                    
                }
                .padding(80)
                .focusSection()
            }
            .introspectScrollView { view in
                view.clipsToBounds = false
            }
            .fullScreenCover(isPresented: $showPlayer) {
                PlayerView(playerItem:self.$playerItem,
                           playerImageOverlayUrl:playerImageOverlayUrl,
                           playerTextOverlay:playerTextOverlay,
                           finished: $playerFinished
                )
                .preferredColorScheme(colorScheme)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .onAppear(){

                if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"){
                    self.backgroundImageUrl = "https://picsum.photos/600/800"
                }else{
                    var imageLink: JSON? = nil
                    do {
                        if let bg = drop.background_image_tv {
                            if bg != "" {
                                self.backgroundImageUrl = bg
                            }
                        }

                    }catch{
                        print("Error getting image URL from link ", imageLink)
                    }
                }
                /*
                DispatchQueue.main.asyncAfter(deadline: .now()+0.7) {
                    headerFocused = true
                }*/
            }
        }
        .background(Color.mainBackground)
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .ignoresSafeArea()
        .focusSection()
    }
    
}

struct DropDetail_Previews: PreviewProvider {
    static var previews: some View {
        NFTDetail(nft: test_NFTs[0])
                .listRowInsets(EdgeInsets())
    }
}
