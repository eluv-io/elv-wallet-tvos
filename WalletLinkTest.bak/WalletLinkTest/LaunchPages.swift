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
        return configuration.label
    }
}


struct LaunchPage: View {
    @Environment(\.openURL) private var openURL
    //Fullscreen image prototyping a launch page
    var image = ""
    //deeplink into the wallet
    var link = ""

    var body: some View {
        Button {
            debugPrint("Tap")
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
        } label: {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
        }
        .buttonStyle(NoButtonStyle())
        .edgesIgnoringSafeArea(.all)
    }
}
