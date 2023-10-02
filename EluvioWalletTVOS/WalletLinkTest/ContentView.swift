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

let urls = [
    "FOX - Weather All Access":"elvwallet://items?contract=0xeb65174e4ed37a0b99b2f8d130ef84c7cc740264&token=2&sku=RzVfTVinSpRh1jde2uS5b8&marketplace=iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82",
    "FOX - Sports All Access":"elvwallet://items?contract=0x91eaf3bfa0e26cd94f035950e9b79ef3bfa0b1f8&token=1&sku=3HVqSTXa4N1seLkL3sYnSL&marketplace=iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82",
    //"FOX - Entertainment": "elvwallet://items?contract=0x78e3e96ed9be5cab65ee1aa937ac816f6fdfbaf7&token=1&sku=NUwRFs3huWmSJQJryHcELP&marketplace=iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82",
    "The Flash":"elvwallet://items?contract=0x896409ad1da7f3f48749d15602eabac3578694b4&token=630&sku=S9rrmcKoQdAma1346pSZwy&marketplace=iq__3YdURECX5V1rhE84vREnXfavwn5s&media=8REEVKxKhLdvAyC2UQxTHs",
    "One Love":"elvwallet://items?contract=0xfe6eca032ff865731c280d1f10f641a573b3ffb6&token=2&sku=UaZHyXZnXEb1EVqawpwFG7&marketplace=iq__2JfsLkPskQ4wBFqL6FaXxnicU8XU&media=3pmffSGd1U6u7pD6AYyzrV",
    //"UEFA":"elvwallet://items?contract=0xeca0c98159392ea41c4b0c8136da3ea387b1bd37&token=924&sku=2DgqQquXtXoyWmRHuRTmss&media=9UE8eCZmWhNvT8LDPGEhzE",
]

//Auth Stuff
let clientId = "ed20064a-a4b9-4ec9-bc89-df559eb983a3"
let clientSecret = "5bUz_D~uWnZ~_ic_sjGYIhQV64"
let oauthEndpoint = "https://eloquent-carson-yt726m2tf6.projects.oryapis.com/oauth2/token"
let wltJwtEndpoint = "https://wlt.stg.svc.eluv.io/as/wlt/login/jwt"

let bundleBaseURL = "elvwallet://items"
let playBaseURL = "elvwallet://play"

func CreateBundleLink(contract:String, token: String, marketplace: String, sku: String) -> String {
    return bundleBaseURL + "?" + "contract=\(contract)" + "&token=\(token)" + "&marketplace=\(marketplace)"
        + "&sku=\(sku)"
}

func CreatePlayLink(contract:String, token: String, marketplace: String, sku: String, mediaId: String) -> String {
    return bundleBaseURL + "?" + "&contract=\(contract)" + "&token=\(token)" + "&marketplace=\(marketplace)"
        + "&sku=\(sku)" + "&media=\(mediaId)"
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationView {
            VStack(alignment:.center) {
                HStack(alignment:.center, spacing:20){
                    Image("e_logo")
                        .resizable()
                        .frame(width:120, height:120)
                    Text("Eluvio Wallet Link Demo").font(.title)
                    
                }
                
                Divider()
                
                VStack(alignment:.center){
                    
                    NavigationLink(destination:
                                    TubiPage(bgImage: "TUBI launch screen - Sports - no buttons",
                                             bundleImage: "FOX Sports Bundle Thumbnail",
                                             bundleLink: CreateBundleLink(contract: "0x91eaf3bfa0e26cd94f035950e9b79ef3bfa0b1f8", token: "1", marketplace: "iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82", sku: "3HVqSTXa4N1seLkL3sYnSL"),
                                             playImage: "Live Fox Sports Thumbnail",
                                             playUrl: CreatePlayLink(contract: "0x91eaf3bfa0e26cd94f035950e9b79ef3bfa0b1f8", token: "1", marketplace: "iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82", sku: "3HVqSTXa4N1seLkL3sYnSL", mediaId: "XJT6Xp6mVUzFT76yJHDkPg")
                                            )) {
                        Text("FOX - Sports All Access")
                            .frame(width:700)
                    }
                    
                    NavigationLink(destination:
                                    TubiPage(bgImage: "TUBI launch screen - Weather - no buttons",
                                             bundleImage: "FOX Weather Bundle Thumbnail",
                                             bundleLink: CreateBundleLink(contract:"0xeb65174e4ed37a0b99b2f8d130ef84c7cc740264", token:"2", marketplace:"iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82", sku:"RzVfTVinSpRh1jde2uS5b8"),
                                             playImage: "Live Fox Weather Thumbnail",
                                             playUrl: CreatePlayLink(contract:"0xeb65174e4ed37a0b99b2f8d130ef84c7cc740264", token:"2", marketplace:"iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82", sku:"RzVfTVinSpRh1jde2uS5b8", mediaId:"Pkw7Kp7xgaseNCnyDFuprP")
                                            )) {
                        Text("FOX - Weather All Access")
                            .frame(width:700)
                    }
                    
                    NavigationLink(destination:
                                    TubiPage(bgImage: "TUBI launch screen - Entertainment - no buttons",
                                             bundleImage: "FOX Entertainment Bundle Thumbnail",
                                             bundleLink: CreateBundleLink(contract:"0x78e3e96ed9be5cab65ee1aa937ac816f6fdfbaf7", token:"1", marketplace: "iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82", sku:"NUwRFs3huWmSJQJryHcELP"),
                                             playImage: "FOX Example VOD Thumbnail",
                                             playUrl: CreatePlayLink(contract:"0x78e3e96ed9be5cab65ee1aa937ac816f6fdfbaf7", token:"1", marketplace: "iq__3W16Qeiksnbd4GFwwXEfhiZ89Y82", sku:"NUwRFs3huWmSJQJryHcELP", mediaId: "SCsC5xsZskBSEPLePN9fcc"),
                                             playButtonText: "Play"
                                            )) {
                        Text("FOX - Entertainment")
                            .frame(width:700)
                    }
                    
                    NavigationLink(destination:
                                    BluePage(bgImage: "SWISS BLUE App Launch - no buttons",
                                             bundleLink: CreateBundleLink(contract:"0xfe6eca032ff865731c280d1f10f641a573b3ffb6",token:"2",marketplace:"iq__2JfsLkPskQ4wBFqL6FaXxnicU8XU", sku:"UaZHyXZnXEb1EVqawpwFG7"),
                                             playUrl: CreatePlayLink(contract:"0xfe6eca032ff865731c280d1f10f641a573b3ffb6",token:"2",marketplace:"iq__2JfsLkPskQ4wBFqL6FaXxnicU8XU", sku:"UaZHyXZnXEb1EVqawpwFG7", mediaId:"3pmffSGd1U6u7pD6AYyzrV")
                                            )) {
                        Text("One Love")
                            .frame(width:700)
                    }
                    
                    NavigationLink(destination:
                                    MaxPage(bgImage: "Max Launch Screen - no buttons",
                                             bundleLink: CreateBundleLink(contract:"0x896409ad1da7f3f48749d15602eabac3578694b4",token:"630",marketplace:"iq__3YdURECX5V1rhE84vREnXfavwn5s", sku:"S9rrmcKoQdAma1346pSZwy"),
                                             playUrl: CreatePlayLink(contract:"0x896409ad1da7f3f48749d15602eabac3578694b4",token:"630",marketplace:"iq__3YdURECX5V1rhE84vREnXfavwn5s", sku:"S9rrmcKoQdAma1346pSZwy", mediaId:"8REEVKxKhLdvAyC2UQxTHs")
                                            )) {
                        Text("The Flash")
                            .frame(width:700)
                    }
                    
                    NavigationLink(destination:
                                    UEFAPage(bgImage: "UEFA Launch Screen - no buttons",
                                             bundleLink: CreateBundleLink(contract:"0xeca0c98159392ea41c4b0c8136da3ea387b1bd37",token:"924",marketplace:"", sku:"2DgqQquXtXoyWmRHuRTmss"),
                                             playUrl: CreatePlayLink(contract:"0xeca0c98159392ea41c4b0c8136da3ea387b1bd37",token:"924",marketplace:"", sku:"2DgqQquXtXoyWmRHuRTmss", mediaId:"9UE8eCZmWhNvT8LDPGEhzE")
                                            )) {
                        Text("UEFA EURO2024")
                            .frame(width:700)
                    }
                }
                .padding(.top,40)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
