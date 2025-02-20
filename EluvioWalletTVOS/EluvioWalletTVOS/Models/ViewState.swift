//
//  self.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-02-15.
//

import SwiftUI

enum LinkOp {
    case item, play, mint, property, gallery, none
}

class ViewState: ObservableObject {
    @Published var op: LinkOp  = .none
    var itemContract = ""
    var itemTokenStr = ""
    var marketplaceId = ""
    var itemSKU = ""
    var mediaId = ""
    var backLink = ""
    var authToken = ""
    var address = ""
    var entitlement = ""
    
    //App states
    var isBranded = false
    var signInBackground : RadialGradient
    
    init(isBranded: Bool = false, signInBackground: RadialGradient = Color.mainBackground){
        self.isBranded = isBranded
        self.signInBackground = signInBackground
    }
    
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
    
    func handleLink(url:URL, fabric: Fabric) async{
        if let host = url.host()?.lowercased() {
            debugPrint("handleLink ", host)
            reset()
            
            if let backlink = url.valueOf("back_link")?.removingPercentEncoding {
                backLink = backlink
            }
            debugPrint("backlink: ", backLink)
            
            if let authToken = url.valueOf("authorization")?.removingPercentEncoding {
                self.authToken = authToken
                debugPrint("Deeplink with auth", authToken)
                    do {
                        try await fabric.connect(network:"main", signIn: false)
                        var signInResponse = SignInResponse()
                        signInResponse.idToken = authToken
                        //try await fabric.signIn(signInResponse: signInResponse, external: true)
                        
                        debugPrint("Signed In!")
                        
                        
                        await MainActor.run {
                            setViewState(host: host, url: url)
                        }
                    }catch {
                        print("Could not login from deeplink: \(error.localizedDescription)")
                    }
            }else{
                await MainActor.run {
                    setViewState(host:host, url:url)
                }
            }
        }
    }
    
    //@MainActor
    func setViewState(host:String, url:URL){
       switch(host){
       case "items":
           debugPrint("viewStateProperty items")
           self.itemContract = url.valueOf("contract")?.lowercased() ?? ""
           self.itemTokenStr = url.valueOf("token") ?? ""
           self.marketplaceId = url.valueOf("marketplace") ?? ""
           self.itemSKU = url.valueOf("sku") ?? ""
           debugPrint("backlink: ", self.backLink)
           self.op = .item
       case "play":
           debugPrint("viewStateProperty play")
           self.itemContract = url.valueOf("contract")?.lowercased() ?? ""
           self.itemTokenStr = url.valueOf("token") ?? ""
           self.mediaId = url.valueOf("media") ?? ""
           self.marketplaceId = url.valueOf("marketplace") ?? ""
           self.itemSKU = url.valueOf("sku") ?? ""
           self.op = .play
       case "mint":
           debugPrint("viewStateProperty mint")
           self.marketplaceId = url.valueOf("marketplace") ?? ""
           self.itemSKU = url.valueOf("sku") ?? ""
           self.entitlement = url.valueOf("entitlement") ?? ""
           self.op = .mint
       case "property":
           debugPrint("viewStateProperty property ",self.marketplaceId)
           self.marketplaceId = url.lastPathComponent
           self.op = .property
       default:
           return
       }
    }
    
    func setViewState(state: ViewState){
        self.itemContract = state.itemContract
        self.itemTokenStr = state.itemTokenStr
        self.marketplaceId = state.marketplaceId
        self.itemSKU = state.itemSKU
        self.mediaId = state.mediaId
        self.op = state.op
    }
}
