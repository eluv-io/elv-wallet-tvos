//
//  UEFAPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-02.
//

import SwiftUI

struct UEFAPage: View {
    @Environment(\.openURL) private var openURL

    var bgImage = ""
    var bundleImage = ""
    var bundleLink = ""
    var playImage = ""
    var playUrl = ""
    var playButtonText = "Watch Latest Match"
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
                    hightlightColor: Color.white,
                    highlightTextColor: Color.black,
                    action: {
                        /*
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
                         */
                        
                        if let url = URL(string: playUrl) {
                            self.url = url
                            showPlayer = true
                        }
                        
                    }
                )
                
                LaunchButton(
                    buttonIcon: "icon_bundle",
                    buttonIconHighlighted: "icon_bundle_black",
                    buttonText: buncleButtonText,
                    hightlightColor: Color.white,
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
            .offset(x:90, y: 180)
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

