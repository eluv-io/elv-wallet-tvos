//
//  MSPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-12-28.
//

import SwiftUI

let msScheme = "mswallet"
let msPropertyBaseURL = "\(msScheme)://property"
let msBundleURL = "\(msScheme)://items"
let msMintURL = "\(msScheme)://mint"
let msPlayURL = "\(msScheme)://play"

func CreateMSPropertyLink(
    marketplace: String,
    token: String="",
    address: String=""
) -> String {
    return msPropertyBaseURL + "/\(marketplace)" + "?back_link=walletlink://"
    + (token.isEmpty ? "" : "&authorization=\(token)") + (address.isEmpty ? "" : "&address=\(address)")
}

func CreateMSBundleLink(
    contract:String,
    marketplace: String,
    sku: String,
    token: String="",
    address: String=""
) -> String {
    return msBundleURL + "?" + "contract=\(contract)" + "&marketplace=\(marketplace)"
    + "&sku=\(sku)" + "&back_link=walletlink://"
    + (token.isEmpty ? "" : "&authorization=\(token)") + (address.isEmpty ? "" : "&address=\(address)")
}

func CreateMSPlayLink(
    contract:String,
    token: String="",
    address: String=""
) -> String {
    return msPlayURL + "?" + "contract=\(contract)" + "&back_link=walletlink://"
    + (token.isEmpty ? "" : "&authorization=\(token)") + (address.isEmpty ? "" : "&address=\(address)")
}

func CreateMSMintLink(
    contract:String,
    marketplace: String,
    sku: String,
    token: String="",
    address: String=""
) -> String{
    return msMintURL + "?" + "marketplace=\(marketplace)" + "&sku=\(sku)" + "&contract=\(contract)" + "&back_link=walletlink://"
    + (token.isEmpty ? "" : "&authorization=\(token)") + (address.isEmpty ? "" : "&address=\(address)")
}

struct MSMenuNavigationLinks: View {
    @EnvironmentObject var login : LoginManager
    let msMarketPlaceId = "iq__2J6bUaQkReBrLYSFYQ7nfuPtyyA"
    
    var body: some View {
        NavigationLink(
            destination:
                LaunchPage(
                    bgImage: "MS Property Page Launch No btn",
                    link: CreateMSPropertyLink(
                        marketplace:msMarketPlaceId,
                        token: login.loginInfo?.token ?? "",
                        address: login.loginInfo?.addr ?? ""
                    ),
                    buttonHighlightColor: Color(hex:0x49a1e9)
                )
        ) {
            Text(
                "Property Page - MS Wallet"
            )
            .frame(
                width:CONTENT_WIDTH
            )
        }
        
        NavigationLink(
            destination:
                MSPage(
                    bgImage: "AQP-no-buttons",
                    bundleLink: CreateMSBundleLink(
                        contract:"0x265e8cdd7dc0dc85921222e16bf472ebe6f9cf5a",
                        marketplace:msMarketPlaceId,
                        sku:"3MFmfwc2STJStPA27kdsrb",
                        token: login.loginInfo?.token ?? "",
                        address: login.loginInfo?.addr ?? ""
                    ),
                    playOutPath:"/q/hq__B1uYXysLE5XsGis2JUeTuBG8zfK7BaCy7Ng2DK8zmcLcyQArmTgc9B85ZfE5TDt1djQbGMmdbX/rep/playout/default/hls-clear/playlist.m3u8",
                    token: login.loginInfo?.token ?? ""
                )
        ) {
            Text(
                "A Quiet Place: Day One - MS Wallet"
            )
            .frame(
                width:CONTENT_WIDTH
            )
        }
        
        
        NavigationLink(
            destination:
                MSPage(
                    bgImage: "BMOL-no-buttons",
                    bundleLink: CreateMSBundleLink(
                        contract:"0xee240128c00e0983d3e0ee1adab4da2f2393f3fb",
                        marketplace:msMarketPlaceId,
                        sku:"LXfVupF9qzwUueYwCRJQJ",
                        token: login.loginInfo?.token ?? "",
                        address: login.loginInfo?.addr ?? ""
                    ),
                    playOutPath:"/q/hq__3qChzMEkpzsJtde65yxekhnHZitGe43jBAz58PdU4e56KVxKUbPqQFYuvoPu2jCq3CDPJoDHRV/rep/playout/default/hls-clear/playlist.m3u8",
                    token: login.loginInfo?.token ?? ""
                )
        ) {
            Text(
                "One Love - MS Wallet"
            )
            .frame(
                width:CONTENT_WIDTH
            )
        }
        
        NavigationLink(
            destination:
                MSPage(
                    bgImage: "TG-no-buttons",
                    bundleLink: CreateMSMintLink(
                        contract:"0xd2896f45879b1a007aff5d052b9d6ab8c4933fad",
                        marketplace:msMarketPlaceId,
                        sku:"TgzuWdmnaVwrkGEFbGE9CU",
                        token: login.loginInfo?.token ?? "",
                        address: login.loginInfo?.addr ?? ""
                    ),
                    playOutPath:"/q/hq__MVrabVyoxNPvJKCBiRstnhAsEyZXxBBwaRKvfSS413nfyepktJdFLmZ4q2D8uECNVQ2sxnH9JP/rep/playout/default/hls-clear/playlist.m3u8",
                    token: login.loginInfo?.token ?? "",
                    bundleButtonText: "Activate"
                    
                )
        ) {
            Text(
                "Top Gun - MS Wallet"
            )
            .frame(
                width:CONTENT_WIDTH
            )
        }
        
        NavigationLink(
            destination:
                MSPage(
                    bgImage: "LOTR-no-buttons",
                    bundleLink: CreateMSBundleLink(
                        contract:"0xb97c464a16d7f3c2d64f9009da39cc76178c7fd5",
                        marketplace:msMarketPlaceId,
                        sku:"QhNCnXHbH5uuDoktGvYuac",
                        token: login.loginInfo?.token ?? "",
                        address: login.loginInfo?.addr ?? ""
                    ),
                    playLink: CreateMSPlayLink(
                        contract:"0xb97c464a16d7f3c2d64f9009da39cc76178c7fd5"),
                    token: login.loginInfo?.token ?? ""
                )
        ) {
            Text(
                "LOTR: Extended Edition Epic - MS Wallet"
            )
            .frame(
                width:CONTENT_WIDTH
            )
        }
        
        NavigationLink(
            destination:
                MSPage(
                    bgImage: "Flash-no-buttons",
                    bundleLink: CreateMSBundleLink(
                        contract:"0x896409ad1da7f3f48749d15602eabac3578694b4",
                        marketplace:msMarketPlaceId,
                        sku:"VP9try5Z2zdg7zJczJiAhN",
                        token: login.loginInfo?.token ?? "",
                        address: login.loginInfo?.addr ?? ""
                    ),
                    playLink: CreateMSPlayLink(
                        contract:"0x896409ad1da7f3f48749d15602eabac3578694b4"),
                    token: login.loginInfo?.token ?? ""
                )
        ) {
            Text(
                "The Flash - MS Wallet"
            )
            .frame(
                width:CONTENT_WIDTH
            )
        }
    }
}

struct MSPage: View {
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
    var buttonHighlightColor = Color(hex:0x1d1f1e)
    
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
                    height:100,
                    action: {
                        if playOutPath != "" {
                            let combinedUrl = fabric.createUrl(path:playOutPath, token:token)
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
                    height:100,
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
            .offset(x:100, y: 200)
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
