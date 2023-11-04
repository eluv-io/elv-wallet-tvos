//
//  ContentView.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-13.
//

import SwiftUI

//
//  Styles.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-29.
//
import SwiftUI
import Foundation


let appStoreUrl = "https://apps.apple.com/in/app/eluvio-media-wallet/id1591550411"

//Auth Stuff
let clientId = "ed20064a-a4b9-4ec9-bc89-df559eb983a3"
let clientSecret = "5bUz_D~uWnZ~_ic_sjGYIhQV64"
let oauthEndpoint = "https://eloquent-carson-yt726m2tf6.projects.oryapis.com/oauth2/token"
let wltJwtEndpoint = "https://wlt.stg.svc.eluv.io/as/wlt/login/jwt"

let staticTokenMain = "eyJxc3BhY2VfaWQiOiJpc3BjMlJVb1JlOWVSMnYzM0hBUlFVVlNwMXJZWHp3MSJ9Cg=="

let bundleBaseURL = "elvwallet://items"
let playBaseURL = "elvwallet://play"
let mintBaseURL = "elvwallet://mint"
let propertyBaseURL = "elvwallet://property"

let fandangoPropertyBaseURL = "fandango://property"
let fandangoBundleURL = "fandango://items"
let fandangoMintURL = "fandango://mint"
let fandangoPlayURL = "fandango://play"

let CONTENT_WIDTH : CGFloat = 1000

func CreateFandangoPropertyLink(
    marketplace: String
) -> String {
    return fandangoPropertyBaseURL + "/\(marketplace)" + "?back_link=walletlink://"
}

func CreateFandangoBundleLink(
    contract:String,
    marketplace: String,
    sku: String
) -> String {
    return fandangoBundleURL + "?" + "contract=\(contract)" + "&marketplace=\(marketplace)"
    + "&sku=\(sku)" + "&back_link=walletlink://"
}

func CreateFandangoPlayLink(
    contract:String
) -> String {
    return fandangoPlayURL + "?" + "contract=\(contract)" + "&back_link=walletlink://"
}

func CreateFandangoMintLink(
    contract:String,
    marketplace: String,
    sku: String
) -> String{
    return fandangoMintURL + "?" + "marketplace=\(marketplace)" + "&sku=\(sku)" + "&contract=\(contract)" + "&back_link=walletlink://"
}

func CreatePropertyLink(
    marketplace: String
) -> String {
    return propertyBaseURL + "/\(marketplace)" + "?back_link=walletlink://"
}

func CreateBundleLink(
    contract:String,
    marketplace: String,
    sku: String
) -> String {
    return bundleBaseURL + "?" + "contract=\(contract)" + "&marketplace=\(marketplace)"
    + "&sku=\(sku)" + "&back_link=walletlink://"
}

func CreatePlayLink(
    contract:String
) -> String {
    return playBaseURL + "?" + "contract=\(contract)" + "&back_link=walletlink://"
}

//For DEMO ONLY: minting into the a wallet even if it exists
//Contract is just for convenience in the demo
func CreateMintLink(
    contract:String,
    marketplace: String,
    sku: String
) -> String{
    return mintBaseURL + "?" + "marketplace=\(marketplace)" + "&sku=\(sku)" + "&contract=\(contract)"
        + "&back_link=walletlink://"
}

struct ContentView: View {
    @Environment(
        \.openURL
    ) private var openURL
    @StateObject
    var fabric = Fabric()
    @FocusState private var headerFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment:.center) {
                    Button{} label: {
                        HStack(
                            alignment:.center,
                            spacing:20
                        ){
                            Image("e_logo")
                            .resizable()
                            .frame(
                                width:120,
                                height:120
                            )
                            Text("Eluvio Wallet Link Demo")
                                .foregroundColor(Color.white)
                                .font(.title)
                        }
                    }
                    .buttonStyle(NonSelectionButtonStyle())
                    .focused($headerFocused)
                    
                    Divider()
                    VStack(
                        alignment:.center
                    ){
                        // Fandango Media Wallet Launchers
                        
                        NavigationLink(
                            destination:
                                FandangoPage(
                                    bgImage: "Fandango Launch - no buttons",
                                    link: CreateFandangoPropertyLink(
                                        marketplace:"iq__2YZajc8kZwzJGZi51HJB7TAKdio2"
                                    )
                                )
                        ) {
                            Text(
                                "Property Page - FANDANGO"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                VuduPage(
                                    bgImage: "VUDU-AQuietPlace-NoButtons",
                                    bundleLink: CreateFandangoBundleLink(
                                        contract:"0xb77dd8be37c6c8a6da8feb87bebdb86efaff74f4",
                                        marketplace:"iq__2YZajc8kZwzJGZi51HJB7TAKdio2",
                                        sku:"5teHdjLfYtPuL3CRGKLymd"
                                    ),
                                    playOutPath:"/q/hq__B1uYXysLE5XsGis2JUeTuBG8zfK7BaCy7Ng2DK8zmcLcyQArmTgc9B85ZfE5TDt1djQbGMmdbX/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "A Quiet Place: Day One - FANDANGO"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        
                        NavigationLink(
                            destination:
                                VuduPage(
                                    bgImage: "VUDU-OneLove-NoButtons",
                                    bundleLink: CreateFandangoBundleLink(
                                        contract:"0x8e225b2dbe6272d136b58f94e32c207a72cdfa3b",
                                        marketplace:"iq__2YZajc8kZwzJGZi51HJB7TAKdio2",
                                        sku:"TzTKjJdW1fLhhvJmptU6N6"
                                    ),
                                    playOutPath:"/q/hq__3qChzMEkpzsJtde65yxekhnHZitGe43jBAz58PdU4e56KVxKUbPqQFYuvoPu2jCq3CDPJoDHRV/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "One Love - FANDANGO"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                VuduPage(
                                    bgImage: "VUDU-TopGun-NoButtons",
                                    bundleLink: CreateFandangoMintLink(
                                        contract:"0x86b9f9b5d26c6f111afaecf64a7c3e3e8a1736da",
                                        marketplace:"iq__2YZajc8kZwzJGZi51HJB7TAKdio2",
                                        sku:"BLnoodkYExnbPJi5AncCJ"
                                    ),
                                    playOutPath:"/q/hq__MVrabVyoxNPvJKCBiRstnhAsEyZXxBBwaRKvfSS413nfyepktJdFLmZ4q2D8uECNVQ2sxnH9JP/rep/playout/default/hls-clear/playlist.m3u8",
                                    bundleButtonText: "Activate"
                                )
                        ) {
                            Text(
                                "Top Gun - FANDANGO"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                VuduPage(
                                    bgImage: "VUDU LOTR Epic - no buttons",
                                    bundleLink: CreateFandangoBundleLink(
                                        contract:"0xb97c464a16d7f3c2d64f9009da39cc76178c7fd5",
                                        marketplace:"iq__2YZajc8kZwzJGZi51HJB7TAKdio2",
                                        sku:""
                                    ),
                                    playLink: CreateFandangoPlayLink(
                                        contract:"0xb97c464a16d7f3c2d64f9009da39cc76178c7fd5")
                                )
                        ) {
                            Text(
                                "LOTR: Extended Edition Epic - FANDANGO"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                VuduPage(
                                    bgImage: "VUDU Flash Launch screen - no buttons",
                                    bundleLink: CreateFandangoBundleLink(
                                        contract:"0x896409ad1da7f3f48749d15602eabac3578694b4",
                                        marketplace:"iq__2YZajc8kZwzJGZi51HJB7TAKdio2",
                                        sku:""
                                    ),
                                    playLink: CreateFandangoPlayLink(
                                        contract:"0x896409ad1da7f3f48749d15602eabac3578694b4")
                                )
                        ) {
                            Text(
                                "The Flash - FANDANGO"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        Divider().frame(width:CONTENT_WIDTH).padding()
                        
                        /// VUDU
                        
                        NavigationLink(
                            destination:
                                VuduPage(
                                    bgImage: "VUDU-AQuietPlace-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xb77dd8be37c6c8a6da8feb87bebdb86efaff74f4",
                                        marketplace:"iq__486mYdFPkvmJ8YDQHxHEsW7TRr1D",
                                        sku:"NTSaHLRni4rXc8HY4u9Ap5"
                                    ),
                                    playOutPath:"/q/hq__B1uYXysLE5XsGis2JUeTuBG8zfK7BaCy7Ng2DK8zmcLcyQArmTgc9B85ZfE5TDt1djQbGMmdbX/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "A Quiet Place: Day One - VUDU"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                VuduPage(
                                    bgImage: "VUDU-OneLove-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0x8e225b2dbe6272d136b58f94e32c207a72cdfa3b",
                                        marketplace:"iq__486mYdFPkvmJ8YDQHxHEsW7TRr1D",
                                        sku:"6zEubv9HxV6sD7TiKCt2Uh"
                                    ),
                                    playOutPath:"/q/hq__3qChzMEkpzsJtde65yxekhnHZitGe43jBAz58PdU4e56KVxKUbPqQFYuvoPu2jCq3CDPJoDHRV/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "One Love - VUDU"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                VuduPage(
                                    bgImage: "VUDU-TopGun-NoButtons",
                                    bundleLink: CreateMintLink(
                                        contract:"0x86b9f9b5d26c6f111afaecf64a7c3e3e8a1736da",
                                        marketplace:"iq__486mYdFPkvmJ8YDQHxHEsW7TRr1D",
                                        sku:"4K7QgmEhnVUhbX5knUv47B"
                                    ),
                                    playOutPath:"/q/hq__MVrabVyoxNPvJKCBiRstnhAsEyZXxBBwaRKvfSS413nfyepktJdFLmZ4q2D8uECNVQ2sxnH9JP/rep/playout/default/hls-clear/playlist.m3u8",
                                    bundleButtonText: "Activate"
                                )
                        ) {
                            Text(
                                "Top Gun - VUDU"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        Divider().frame(width:CONTENT_WIDTH).padding()
                        
                        
                        /// BLUE
                        
                        NavigationLink(
                            destination:
                                BluePage(
                                    bgImage: "BLUE-AQuietPlace-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0x4343b822b172a18416e3b842ecbec7e6f37dc4af",
                                        marketplace:"iq__2JfsLkPskQ4wBFqL6FaXxnicU8XU",
                                        sku:"H7v4eaU3CNv9TAK1n1RQLk"
                                    ),
                                    playOutPath:"/q/hq__B1uYXysLE5XsGis2JUeTuBG8zfK7BaCy7Ng2DK8zmcLcyQArmTgc9B85ZfE5TDt1djQbGMmdbX/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "A Quiet Place: Day One - Blue"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        
                        NavigationLink(
                            destination:
                                BluePage(
                                    bgImage: "BLUE-OneLove-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xfe6eca032ff865731c280d1f10f641a573b3ffb6",
                                        marketplace:"iq__2JfsLkPskQ4wBFqL6FaXxnicU8XU",
                                        sku:"UaZHyXZnXEb1EVqawpwFG7"
                                    ),
                                    playOutPath:"/q/hq__3qChzMEkpzsJtde65yxekhnHZitGe43jBAz58PdU4e56KVxKUbPqQFYuvoPu2jCq3CDPJoDHRV/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "One Love - Blue"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                BluePage(
                                    bgImage: "BLUE-TopGun-NoButtons",
                                    bundleLink: CreateMintLink(
                                        contract:"0x8f5bd77149dd1543c955fdb062b9eaf283e720e8",
                                        marketplace:"iq__2JfsLkPskQ4wBFqL6FaXxnicU8XU",
                                        sku:"SZVBrNZEmutBq1aSvB9VZe"
                                    ),
                                    playOutPath:"/q/hq__MVrabVyoxNPvJKCBiRstnhAsEyZXxBBwaRKvfSS413nfyepktJdFLmZ4q2D8uECNVQ2sxnH9JP/rep/playout/default/hls-clear/playlist.m3u8",
                                    bundleButtonText: "Activate"
                                )
                        ) {
                            Text(
                                "Top Gun - Blue"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        Divider().frame(width:CONTENT_WIDTH).padding()
                        //FETCH
                        
                        NavigationLink(
                            destination:
                                FetchPage(
                                    bgImage: "FETCH-AQuietPlace-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xa1692fadb4c7869150e9a127832150cbe41d66f7",
                                        marketplace:"iq__9YVCGN888PEEZ42ydQznrKqGCzv",
                                        sku:"VLuvVAzjjESLJUAzgETy2e"
                                    ),
                                    playOutPath:"/q/hq__B1uYXysLE5XsGis2JUeTuBG8zfK7BaCy7Ng2DK8zmcLcyQArmTgc9B85ZfE5TDt1djQbGMmdbX/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "A Quiet Place: Day One - Fetch"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                FetchPage(
                                    bgImage: "FETCH-OneLove-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xd18a39b13b6f26b9b18947c8af3c839ebe996da4",
                                        marketplace:"iq__9YVCGN888PEEZ42ydQznrKqGCzv",
                                        sku:"3MgmkiUxX4AKNgsDqvGVQy"
                                    ),
                                    playOutPath:"/q/hq__3qChzMEkpzsJtde65yxekhnHZitGe43jBAz58PdU4e56KVxKUbPqQFYuvoPu2jCq3CDPJoDHRV/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "One Love - Fetch"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                FetchPage(
                                    bgImage: "FETCH-TopGun-NoButtons",
                                    bundleLink: CreateMintLink(
                                        contract:"0x31c521b0244a48fd536671b7ff98703483721767",
                                        marketplace:"iq__9YVCGN888PEEZ42ydQznrKqGCzv",
                                        sku:"PcAKhWtiLbFHwGPHwAzbLN"
                                    ),
                                    playOutPath:"/q/hq__MVrabVyoxNPvJKCBiRstnhAsEyZXxBBwaRKvfSS413nfyepktJdFLmZ4q2D8uECNVQ2sxnH9JP/rep/playout/default/hls-clear/playlist.m3u8",
                                    bundleButtonText: "Activate"
                                )
                        ) {
                            Text(
                                "Top Gun - Fetch"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        Divider().frame(width:CONTENT_WIDTH).padding()
                        // KT
                        
                        NavigationLink(
                            destination:
                                KTPage(
                                    bgImage: "KT-AQuietPlace-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xa1d1c0af6e1092610bc94d1468ab53bb1a2ef136",
                                        marketplace:"iq__2bWmbXgLJ1yd7WHDUAH8HJzurJXs",
                                        sku:"MyyknMqCm1kKhZ71magLFf"
                                    ),
                                    playOutPath:"/q/hq__B1uYXysLE5XsGis2JUeTuBG8zfK7BaCy7Ng2DK8zmcLcyQArmTgc9B85ZfE5TDt1djQbGMmdbX/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "A Quiet Place: Day One - KT"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                KTPage(
                                    bgImage: "KT-OneLove-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0x41c2ff18653833ad3f2f866a45e70655e49881cd",
                                        marketplace:"iq__2bWmbXgLJ1yd7WHDUAH8HJzurJXs",
                                        sku:"WkHJifc7JUAUANGgZp7eGL"
                                    ),
                                    playOutPath:"/q/hq__3qChzMEkpzsJtde65yxekhnHZitGe43jBAz58PdU4e56KVxKUbPqQFYuvoPu2jCq3CDPJoDHRV/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "One Love - KT"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                KTPage(
                                    bgImage: "KT-TopGun-NoButtons",
                                    bundleLink: CreateMintLink(
                                        contract:"0x7ec94256db5fb85ee9f58930fa45c3f951ce3924",
                                        marketplace:"iq__2bWmbXgLJ1yd7WHDUAH8HJzurJXs",
                                        sku:"D885THn4zotH8vPzc4N8rW"
                                    ),
                                    playOutPath:"/q/hq__MVrabVyoxNPvJKCBiRstnhAsEyZXxBBwaRKvfSS413nfyepktJdFLmZ4q2D8uECNVQ2sxnH9JP/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "Top Gun - KT"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }

                        Divider().frame(width:CONTENT_WIDTH).padding()
                        
                        NavigationLink(
                            destination:
                                UNextPage(
                                    bgImage: "UNEXT-AQuietPlace-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xb6902431d2d0587bf961eb512191284473931e7b",
                                        marketplace:"iq__4Lje7rSXCzn62RRT2tWZb6VgB5qY",
                                        sku:"HRfr9ks5YXduw1YUQwruFP"
                                    ),
                                    playOutPath:"/q/hq__B1uYXysLE5XsGis2JUeTuBG8zfK7BaCy7Ng2DK8zmcLcyQArmTgc9B85ZfE5TDt1djQbGMmdbX/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "A Quiet Place: Day One - U-Next"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }

                        NavigationLink(
                            destination:
                                UNextPage(
                                    bgImage: "UNEXT-OneLove-NoButtons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0x575e850cd0fbd6c353d79b20f034ccfd81924ce7",
                                        marketplace:"iq__4Lje7rSXCzn62RRT2tWZb6VgB5qY",
                                        sku:"8uiAgcftFSVrX42LV4BPkW"
                                    ),
                                    playOutPath:"/q/hq__3qChzMEkpzsJtde65yxekhnHZitGe43jBAz58PdU4e56KVxKUbPqQFYuvoPu2jCq3CDPJoDHRV/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "One Love - U-Next"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }

                        
                        NavigationLink(
                            destination:
                                UNextPage(
                                    bgImage: "UNEXT-TopGun-NoButtons",
                                    bundleLink: CreateMintLink(
                                        contract:"0x00da448b526b3a2a0e6aa95ab1dc97efc0922c1c",
                                        marketplace:"iq__4Lje7rSXCzn62RRT2tWZb6VgB5qY",
                                        sku:"M3CFGNeF236FgT7XLLoAne"
                                    ),
                                    playOutPath:"/q/hq__MVrabVyoxNPvJKCBiRstnhAsEyZXxBBwaRKvfSS413nfyepktJdFLmZ4q2D8uECNVQ2sxnH9JP/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "Top Gun - U-Next"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        Divider().frame(width:CONTENT_WIDTH).padding()
                        // FOX
                        
                        NavigationLink(
                            destination:
                                TubiPage(
                                    bgImage: "TUBI launch screen - Sports - no buttons",
                                    bundleImage: "FOX Sports Bundle Thumbnail",
                                    bundleLink: CreateBundleLink(
                                        contract: "0x91eaf3bfa0e26cd94f035950e9b79ef3bfa0b1f8",
                                        marketplace: "iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82",
                                        sku: "3HVqSTXa4N1seLkL3sYnSL"
                                    ),
                                    playImage: "Live Fox Sports Thumbnail",
                                    playOutPath: "/q/iq__3tfUq87qve9ywYu1jL3tGYfXk1ij/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "FOX - Sports All Access"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                TubiPage(
                                    bgImage: "TUBI launch screen - Weather - no buttons",
                                    bundleImage: "FOX Weather Bundle Thumbnail",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xeb65174e4ed37a0b99b2f8d130ef84c7cc740264",
                                        marketplace:"iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82",
                                        sku:"RzVfTVinSpRh1jde2uS5b8"
                                    ),
                                    playImage: "Live Fox Weather Thumbnail",
                                    playOutPath:"/q/iq__2EnYCsx2wn4dpbXDJAk137n9RPU6/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "FOX - Weather All Access"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                TubiPage(
                                    bgImage: "TUBI launch screen - Entertainment - no buttons",
                                    bundleImage: "FOX Entertainment Bundle Thumbnail",
                                    //For DEMO force minting
                                    bundleLink: CreateMintLink(
                                        contract:"0x78e3e96ed9be5cab65ee1aa937ac816f6fdfbaf7",
                                        marketplace: "iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82",
                                        sku:"NUwRFs3huWmSJQJryHcELP"
                                    ),
                                    playImage: "FOX Example VOD Thumbnail",
                                    playOutPath:"/q/iq__2D4nVMqCEEEr3xaaxzZFXq9mKXr8/rep/playout/default/hls-aes128/playlist.m3u8",
                                    playButtonText: "Play",
                                    bundleButtonText: "Activate"
                                )
                        ) {
                            Text(
                                "FOX - Entertainment"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        Divider().frame(width:CONTENT_WIDTH).padding()
                        
                        // THE FLASH
                        
                        NavigationLink(
                            destination:
                                MaxPage(
                                    bgImage: "Max Launch Screen - no buttons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0x896409ad1da7f3f48749d15602eabac3578694b4",
                                        marketplace:"iq__3YdURECX5V1rhE84vREnXfavwn5s",
                                        sku:"S9rrmcKoQdAma1346pSZwy"
                                    ),
                                    playUrl: "",
                                    playLink: CreatePlayLink(
                                        contract:"0x896409ad1da7f3f48749d15602eabac3578694b4"
                                    )
                                )
                        ) {
                            Text(
                                "The Flash - MAX"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        NavigationLink(
                            destination:
                                MaxPage(
                                    bgImage: "Max Launch Screen LOTR - no buttons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xb97c464a16d7f3c2d64f9009da39cc76178c7fd5",
                                        marketplace:"iq__3YdURECX5V1rhE84vREnXfavwn5s",
                                        sku:""
                                    ),
                                    playUrl: "",
                                    playLink: CreatePlayLink(
                                        contract:"0xb97c464a16d7f3c2d64f9009da39cc76178c7fd5"
                                    )
                                )
                        ) {
                            Text(
                                "LOTR: Extended Edition Epic - MAX"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                        
                        
                        // UEFA //
                        
                        NavigationLink(
                            destination:
                                UEFAPage(
                                    bgImage: "UEFA Launch Screen - no buttons",
                                    bundleLink: CreateBundleLink(
                                        contract:"0xeca0c98159392ea41c4b0c8136da3ea387b1bd37",
                                        marketplace:"",
                                        sku:"2DgqQquXtXoyWmRHuRTmss"
                                    ),
                                    playOutPath:"/q/iq__2HUxmn3xLv1vJMU8YLL7vmoKvqvY/rep/playout/default/hls-clear/playlist.m3u8"
                                )
                        ) {
                            Text(
                                "UEFA EURO2024"
                            )
                            .frame(
                                width:CONTENT_WIDTH
                            )
                        }
                    }
                    .padding(
                        .top,
                        40
                    )
                    
                    Spacer()
                }
                .padding()
            }
            .scrollClipDisabled()
        }
        .environmentObject(
            fabric
        )
        .task {
            do {
                try await fabric.connect(
                    configUrl: "https://main.net955305.contentfabric.io/config"
                )
            }catch{
                print(
                    "Error connecting to the fabric: ",
                    error
                )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
