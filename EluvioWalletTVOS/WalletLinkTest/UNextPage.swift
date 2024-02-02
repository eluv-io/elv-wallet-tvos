//
//  UNextPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-13.
//

import SwiftUI

struct UNextPage: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var fabric: Fabric
    
    var bgImage = ""
    var bundleImage = ""
    var bundleLink = ""
    var playImage = ""
    var playUrl = ""
    var playOutPath = ""
    var playButtonText = "長編映画を再生する"
    var bundleButtonText = "開ける"
    
    @State private var showPlayer = false
    @State private var url = URL(string:"")
    @State private var playerFinished = false

    var body: some View {
        VStack(alignment:.leading) {
            HStack{
                VStack(alignment:.leading){
                    LaunchButton(
                        buttonIcon: "icon_play",
                        buttonIconHighlighted: "icon_play_black",
                        buttonText:playButtonText,
                        highlightColor: .white,
                        highlightTextColor: .black,
                        width: 700,
                        height: 100,
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
                        buttonIconHighlighted: "icon_bundle_black",
                        buttonText: bundleButtonText,
                        highlightColor: .white,
                        highlightTextColor: .black,
                        width: 700,
                        height: 100,
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
                }
                Spacer()
            }
            .offset(x:70, y:110)
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
        .fullScreenCover(isPresented:$showPlayer){  [url] in
            PlayerView2(playoutUrl:url, finished: $playerFinished)
        }
    }
}
