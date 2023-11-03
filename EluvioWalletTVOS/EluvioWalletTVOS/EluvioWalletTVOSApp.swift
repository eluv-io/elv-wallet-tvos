//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI

enum LinkOp {
    case item, play, mint, property, none
}

class ViewState: ObservableObject {
    @Published var op: LinkOp  = .none
    var itemContract = ""
    var itemTokenStr = ""
    var marketplaceId = ""
    var itemSKU = ""
    var mediaId = ""
    var backLink = ""
    
    func reset() {
        itemContract = ""
        itemTokenStr = ""
        marketplaceId = ""
        itemSKU = ""
        mediaId = ""
        backLink = ""
        if op == .none {
            return
        }
        op = .none
    }
}

@main
struct EluvioWalletTVOSApp: App {
    @StateObject
    var fabric = Fabric()
    @StateObject
    var viewState = ViewState()
    
    init(){
        print("App Init")
    }
    
    func handleLink(url:URL){
        if let host = url.host()?.lowercased() {
            debugPrint("handleLink ", host)
            viewState.reset()
             
            switch(host){
            case "items":
                viewState.itemContract = url.valueOf("contract")?.lowercased() ?? ""
                viewState.itemTokenStr = url.valueOf("token") ?? ""
                viewState.marketplaceId = url.valueOf("marketplace") ?? ""
                viewState.itemSKU = url.valueOf("sku") ?? ""
                
                if var backlink = url.valueOf("back_link")?.removingPercentEncoding {
                    viewState.backLink = backlink
                }
                debugPrint("backlink: ", viewState.backLink)
                viewState.op = .item
                debugPrint("handleLink viewState changed")
            case "play":
                viewState.itemContract = url.valueOf("contract")?.lowercased() ?? ""
                viewState.itemTokenStr = url.valueOf("token") ?? ""
                viewState.mediaId = url.valueOf("media") ?? ""
                viewState.op = .play
            case "mint":
                viewState.marketplaceId = url.valueOf("marketplace") ?? ""
                viewState.itemSKU = url.valueOf("sku") ?? ""
                viewState.op = .mint
            case "property":
                viewState.marketplaceId = url.lastPathComponent
                viewState.op = .property
            default:
                return
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fabric)
                .environmentObject(viewState)
                .preferredColorScheme(.dark)
                .onAppear(){
                    Task {
                        do {
                            try await fabric.connect(network:"")
                        }catch{
                            print("Error connecting to the fabric: ", error)
                        }
                    }
                }
                .onOpenURL { url in
                    debugPrint("url opened: ", url)
                    
                    handleLink(url:url)
                }
                .edgesIgnoringSafeArea(.all)
        }
    }
}
   
