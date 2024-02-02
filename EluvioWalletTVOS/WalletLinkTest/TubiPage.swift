//
//  TubiPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-29.
//

import SwiftUI
import Combine

struct TubiLaunchButton: View {
    var image = ""
    var showPlayOverlay = false
    var buttonIcon = ""
    var buttonText = ""
    var action: ()->Void
    
    var hightlightColor : Color = Color.red
    
    @FocusState private var isFocused
    
    
    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width:430, height: 430*9/16)
                .overlay(content: {
                    if (showPlayOverlay){
                        Image(systemName: "play.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .opacity(0.7)
                    }
                })
                .overlay(content: {
                    if (isFocused) {
                        RoundedRectangle(cornerRadius:0)
                            .stroke(hightlightColor, lineWidth: 8)
                    }
                })
            
            Button {
                    action()
            } label: {
                HStack(spacing:10){
                    Image(buttonIcon)
                        .resizable()
                        .frame(width:40, height:40)
                    
                    Text(buttonText)
                        .font(.system(size: 32))
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(width:420)
            }
            .buttonStyle(IconButtonStyle(focused:isFocused, highlightColor: hightlightColor))
            .focused($isFocused)
        }
    }
}


struct TubiPage: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var fabric: Fabric
    
    var bgImage = ""
    var bundleImage = ""
    var bundleLink = ""
    var playImage = ""
    var playUrl = ""
    var playOutPath = ""
    
    var playButtonText = "Play Live Channel"
    var bundleButtonText = "Launch Bundle"
    
    @State private var showPlayer = false
    @State var url = URL(string:"")
    @State private var playerFinished = false

    var body: some View {
        VStack(alignment:.center) {
            HStack(){

                TubiLaunchButton(
                    image: playImage,
                    showPlayOverlay: true,
                    buttonIcon: "icon_play",
                    buttonText:playButtonText,
                    action: {
                        let combinedUrl = fabric.createUrl(path:playOutPath)
                        if let url = URL(string: combinedUrl) {
                            debugPrint("Play URL ", url)
                            self.url = url
                            self.showPlayer = true
                        }
                    }
                )
                
                TubiLaunchButton(
                    image:bundleImage,
                    buttonIcon: "icon_bundle",
                    buttonText: bundleButtonText,
                    action: {
                        if let url = URL(string: bundleLink) {
                            openURL(url) { accepted in
                                print(accepted ? "Success" : "Failure")
                                if (!accepted){
                                    openURL(URL(string:appStoreUrl)!) { accepted in
                                        print(accepted ? "Success" : "Failure")
                                        if (!accepted) {
                                            print("Could not open URL ", appStoreUrl)
                                        }
                                    }
                                }
                            }
                        }
                    }
                )
                
                Spacer()
            }
            //.frame(maxWidth:.infinity, maxHeight:.infinity)
            .offset(x:170, y: 160)
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .edgesIgnoringSafeArea(.all)
        .background(
            Image(bgImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth:.infinity, maxHeight:.infinity)
                .edgesIgnoringSafeArea(.all)
        )
        .fullScreenCover(isPresented:$showPlayer){ [url] in
            PlayerView2(playoutUrl:url, finished: $playerFinished)
        }

    }
}
