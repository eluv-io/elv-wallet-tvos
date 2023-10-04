//
//  BluePage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-01.
//

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct LaunchButton: View {
    var buttonIcon = ""
    var buttonIconHighlighted = ""
    var buttonText = ""
    var hightlightColor : Color = Color(hex:0x2c59d3)
    var highlightTextColor = Color.white
    var action: ()->Void
    
    @FocusState private var isFocused
    
    
    var body: some View {
        Button {
                action()
        } label: {
            HStack(spacing:10){
                if (isFocused && buttonIconHighlighted != ""){
                    Image(buttonIconHighlighted)
                        .resizable()
                        .frame(width:40, height:40)
                }else {
                    Image(buttonIcon)
                        .resizable()
                        .frame(width:40, height:40)
                }
                
                Text(buttonText)
                    .font(.system(size: 32))
                    .fontWeight(.medium)
                    .foregroundColor(isFocused ? highlightTextColor : Color.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(width:380)
            .overlay(content: {
                if (!isFocused) {
                    RoundedRectangle(cornerRadius:10)
                        .stroke(Color.white, lineWidth: 4)
                }
            })
        }
        .buttonStyle(IconButtonStyle(focused:isFocused, highlightColor: hightlightColor))
        .focused($isFocused)
    }
}

struct BluePage: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var fabric: Fabric
    
    var bgImage = ""
    var bundleImage = ""
    var bundleLink = ""
    var playImage = ""
    var playUrl = ""
    var playOutPath = ""
    var playButtonText = "Play Feature Film"
    var buncleButtonText = "Launch Bundle"
    
    @State private var showPlayer = false
    @State private var url = URL(string:"")
    @State private var playerFinished = false

    var body: some View {
        VStack(alignment:.center) {
            HStack(){

                LaunchButton(
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
                
                LaunchButton(
                    buttonIcon: "icon_bundle",
                    buttonText: buncleButtonText,
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
            .offset(x:420, y: 160)
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
        .fullScreenCover(isPresented:$showPlayer){
            PlayerView(playoutUrl:$url, finished: $playerFinished)
        }
    }
}
