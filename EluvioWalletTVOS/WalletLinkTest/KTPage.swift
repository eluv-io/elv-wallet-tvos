//
//  KTPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-13.
//

import SwiftUI

struct KTPage: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var fabric: Fabric
    
    var bgImage = ""
    var bundleImage = ""
    var bundleLink = ""
    var playImage = ""
    var playUrl = ""
    var playOutPath = ""
    var playButtonText = "장편 영화 재생"
    var bundleButtonText = "열려 있는"
    
    @State private var showPlayer = false
    @State private var url = URL(string:"")
    @State private var playerFinished = false

    var body: some View {
        VStack(alignment:.center) {
            HStack(){

                LaunchButton(
                    buttonIcon: "icon_play",
                    buttonText:playButtonText,
                    highlightColor: Color(hex:0xb13b2f),
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
                    buttonText: bundleButtonText,
                    highlightColor: Color(hex:0xb13b2f),
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
            .offset(x:230, y: 250)
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

