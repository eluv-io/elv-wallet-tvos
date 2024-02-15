//
//  ShowcasePage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-02-14.
//

import SwiftUI

struct DeepLinkApi {
    var scheme = "elvwallet"
    var propertyBaseURL : String {
        return "\(scheme)://property"
    }
    var bundleURL : String {
        return "\(scheme)://items"
    }
    var mintURL : String {
        return "\(scheme)://mint"
    }
    var playURL : String {
        return "\(scheme)://play"
    }
    
    func createPropertyLink(
        marketplace: String,
        token: String="",
        address: String=""
    ) -> String {
        return propertyBaseURL + "/\(marketplace)" + "?back_link=walletlink://"
        + (token.isEmpty ? "" : "&authorization=\(token)") + (address.isEmpty ? "" : "&address=\(address)")
    }

    func createBundleLink(
        contract:String,
        marketplace: String,
        sku: String,
        token: String="",
        address: String=""
    ) -> String {
        return bundleURL + "?" + "contract=\(contract)" + "&marketplace=\(marketplace)"
        + "&sku=\(sku)" + "&back_link=walletlink://"
        + (token.isEmpty ? "" : "&authorization=\(token)") + (address.isEmpty ? "" : "&address=\(address)")
    }

    func createPlayLink(
        contract:String,
        token: String="",
        address: String=""
    ) -> String {
        return playURL + "?" + "contract=\(contract)" + "&back_link=walletlink://"
        + (token.isEmpty ? "" : "&authorization=\(token)") + (address.isEmpty ? "" : "&address=\(address)")
    }

    func createMintLink(
        contract:String,
        marketplace: String,
        sku: String,
        token: String="",
        address: String=""
    ) -> String{
        return mintURL + "?" + "marketplace=\(marketplace)" + "&sku=\(sku)" + "&contract=\(contract)" + "&back_link=walletlink://"
        + (token.isEmpty ? "" : "&authorization=\(token)") + (address.isEmpty ? "" : "&address=\(address)")
    }
}




struct ShowcaseMenu: View {
    @EnvironmentObject var login : LoginManager
    let msMarketPlaceId = "iq__2zDdtbemEaVt5riyZ58aWNS6P9HR"
    let sku = "U3po5obeo1RRsiUYDd1aWK"
    let contract = "0x265e8cdd7dc0dc85921222e16bf472ebe6f9cf5a"
    let playoutPath = "/q/hq__B1uYXysLE5XsGis2JUeTuBG8zfK7BaCy7Ng2DK8zmcLcyQArmTgc9B85ZfE5TDt1djQbGMmdbX/rep/playout/default/hls-clear/playlist.m3u8"
    let pageImage = "ShowCase TV Launch - no buttons"
    let deepLinkApi: DeepLinkApi
    
    var body: some View {
        NavigationLink(
            destination:
                ShowcasePage(
                    bgImage: "ShowCase TV Launch - no buttons",
                    bundleLink: deepLinkApi.createBundleLink(
                        contract:contract,
                        marketplace:msMarketPlaceId,
                        sku:sku,
                        token: login.loginInfo?.token ?? "",
                        address: login.loginInfo?.addr ?? ""
                    ),
                    playOutPath: playoutPath,
                    token: login.loginInfo?.token ?? ""
                )
        ) {
            Text(
                "A Quiet Place: Day One - Showcase Wallet"
            )
            .frame(
                width:CONTENT_WIDTH
            )
        }
    }
}

struct ShowcasePage: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var fabric: Fabric
    
    var bgImage = ""
    var bundleImage = ""
    var bundleLink = ""
    var playImage = ""
    var playUrl = ""
    var playOutPath = ""
    var playLink = ""
    var token = ""
    var playButtonText = "Play Feature Film"
    var bundleButtonText = "Launch Bundle"
    var buttonHighlightColor = Color(hex:0x92288f)
    
    @State private var showPlayer = false
    @State private var url = URL(string:"")
    @State private var playerFinished = false

    var body: some View {
        VStack(alignment:.center) {
            HStack(spacing:20){

                LaunchButton2(
                    buttonIcon: "icon_play",
                    buttonText:playButtonText,
                    highlightColor: buttonHighlightColor,
                    buttonColor: buttonHighlightColor,
                    height:90,
                    action: {
                        if playOutPath != "" {
                            let combinedUrl = fabric.createUrl(path:playOutPath, token:token)
                            debugPrint("playoutUrl: ", combinedUrl)
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
                
                LaunchButton2(
                    buttonIcon: "icon_bundle",
                    buttonText: bundleButtonText,
                    highlightColor: buttonHighlightColor,
                    buttonColor: buttonHighlightColor,
                    height:90,
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
            .offset(x:640, y: -90)
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
