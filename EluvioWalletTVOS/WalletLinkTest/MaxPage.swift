//
//  MaxPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-02.
//

import SwiftUI

struct MaxPage: View {
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
    var buncleButtonText = "Launch Bundle"
    
    @State private var showPlayer = false
    @State private var url = URL(string:"")
    @State private var playerFinished = false

    var body: some View {
        VStack(alignment:.center) {
            HStack(){

                LaunchButton(
                    buttonIcon: "icon_play",
                    buttonIconHighlighted: "icon_play_black",
                    buttonText:playButtonText,
                    highlightColor: Color.white,
                    highlightTextColor: Color.black,
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
                    buttonIconHighlighted: "icon_bundle_black",
                    buttonText: buncleButtonText,
                    highlightColor: Color.white,
                    highlightTextColor: Color.black,
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
            .offset(x:130, y: 220)
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
