//
//  ContentView.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-09-13.
//

import SwiftUI

/*
let urls = [
    "FOX - Sports All Access":"elvwallet://items?contract=0x91eaf3bfa0e26cd94f035950e9b79ef3bfa0b1f8&token=1",
    "FOX - Weather All Access":"elvwallet://items?contract=0xeb65174e4ed37a0b99b2f8d130ef84c7cc740264&token=2",
    "FOX - Entertainment All Access":"elvwallet://items?contract=0x78e3e96ed9be5cab65ee1aa937ac816f6fdfbaf7&token=1",
    "UEFA - EURO 2024":"elvwallet://items?contract=0xeca0c98159392ea41c4b0c8136da3ea387b1bd37&token=924",
    "The Flash":"elvwallet://items?contract=0x896409ad1da7f3f48749d15602eabac3578694b4&token=630",
    "Superman: The Movie - Hope":"elvwallet://items?contract=0x2dfaeb165ebad738e9952c347d0abfc22f1ac36d&token=337",
    "LOTR: The Shire":"elvwallet://items?contract=0x5bb99da3722c0464c8958ce5c4d92f87a87a99b9&token=4126",
    "LOTR: Epic":"elvwallet://items?contract=0xb97c464a16d7f3c2d64f9009da39cc76178c7fd5&token=438",
]
 */

let appStoreUrl = "https://apps.apple.com/in/app/eluvio-media-wallet/id1591550411"

let urls = [
    "FOX - Weather All Access":"elvwallet://items?contract=0xeb65174e4ed37a0b99b2f8d130ef84c7cc740264&token=2",
    "FOX - Sports All Access":"elvwallet://items?contract=0x91eaf3bfa0e26cd94f035950e9b79ef3bfa0b1f8&token=1",
    "The Flash":"elvwallet://items?contract=0x896409ad1da7f3f48749d15602eabac3578694b4&token=630",
    "One Love":"elvwallet://items"
]

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
                    ForEach(urls.sorted(by: <) , id:\.key) { key,value in
                        NavigationLink(destination:LaunchPage(image: key, link:value)) {
                            Text(key)
                                .frame(width:700)
                        }
                    }
                    /*
                    ForEach(urls.sorted(by: >) , id:\.key) { key,value in
                        Button {
                            if let url = URL(string: value) {
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
                            Text("\(key)")
                        }
                    }
                    */
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
