//
//  LaunchPages.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-26.
//

import SwiftUI
import Combine

struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.clear)
            .background(.clear)
    }
}

struct LaunchPage: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var fabric: Fabric
    
    var bgImage = ""
    var link = ""
    var buttonText = "Launch App"
    var buttonHighlightColor = Color(hex:0xff7300)
    
    @State private var showPlayer = false
    @State private var url = URL(string:"")
    @State private var playerFinished = false

    var body: some View {
        VStack(alignment:.center) {
            HStack(spacing:20){
                
                LaunchButton(
                    //buttonIcon: buttonImage,
                    buttonText: buttonText,
                    highlightColor: buttonHighlightColor,
                    action: {
                        if let url = URL(string: link) {
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
            .offset(x:500, y: 100)
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
