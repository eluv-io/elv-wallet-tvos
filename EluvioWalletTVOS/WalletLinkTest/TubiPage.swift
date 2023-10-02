//
//  TubiPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-29.
//

import SwiftUI
import Combine

struct TitleButtonStyle: ButtonStyle {
    let focused: Bool
    var scale = 1.04
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(.clear)
            .scaleEffect(self.focused ? scale: 1, anchor: .center)
            .animation(self.focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.2), value: self.focused)
    }
}

struct IconButtonStyle: ButtonStyle {
    let focused: Bool
    var initialOpacity: CGFloat = 1.0
    var highlightColor: Color = Color.clear
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(focused ? highlightColor : Color.clear)
            .cornerRadius(10)
            .scaleEffect(self.focused ? 1.03: 1, anchor: .center)
            .animation(self.focused ? .easeIn(duration: 0.1) : .easeOut(duration: 0.1), value: self.focused)
            .opacity(self.focused ? 1.0 : initialOpacity)
    }
}


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

    var bgImage = ""
    var bundleImage = ""
    //deeplink into the wallet
    var bundleLink = ""
    
    var playImage = ""
    var playUrl = ""
    
    var playButtonText = "Play Live Channel"
    var buncleButtonText = "Launch Bundle"
    
    @State private var showPlayer = ""

    var body: some View {
        VStack(alignment:.center) {
            HStack(){

                TubiLaunchButton(
                    image: playImage,
                    showPlayOverlay: true,
                    buttonIcon: "icon_play",
                    buttonText:playButtonText,
                    action: {
                        if let url = URL(string: playUrl) {
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
                
                TubiLaunchButton(
                    image:bundleImage,
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

    }
}
