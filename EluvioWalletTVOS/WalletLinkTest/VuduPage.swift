//
//  VuduPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-23.
//

import SwiftUI

struct VuduPage: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var fabric: Fabric
    
    var bgImage = ""
    var bundleImage = ""
    var bundleLink = ""
    var playImage = ""
    var playUrl = ""
    var playOutPath = ""
    var playLink = ""
    var playButtonText = "Play Feature Film"
    var bundleButtonText = "Launch Bundle"
    var buttonHighlightColor = Color(hex:0x3984c5)
    
    @State private var showPlayer = false
    @State private var url = URL(string:"")
    @State private var playerFinished = false

    var body: some View {
        VStack(alignment:.center) {
            HStack(spacing:20){

                LaunchButton(
                    buttonIcon: "icon_play",
                    buttonText:playButtonText,
                    highlightColor: buttonHighlightColor,
                    action: {
                        if playOutPath != "" {
                            let combinedUrl = fabric.createUrl(path:playOutPath)
                            if let url = URL(string: combinedUrl) {
                                self.url = url
                                showPlayer = true
                            }else{
                                print("Error creating url", combinedUrl)
                            }
                        }
                        else if let url = URL(string: playLink){
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
                
                LaunchButton(
                    buttonIcon: "icon_bundle",
                    buttonText: bundleButtonText,
                    highlightColor: buttonHighlightColor,
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
            .offset(x:170, y: 140)
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
