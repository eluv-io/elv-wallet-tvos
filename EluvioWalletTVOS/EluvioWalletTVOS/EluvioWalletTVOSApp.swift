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
    var authToken = ""
    var address = ""
    
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
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject
    var fabric = Fabric()
    @StateObject
    var viewState = ViewState()
    
    @State var showApp = true
    
    var opacity : CGFloat {
        showApp ? 1.0 : 0.0
    }
    
    init(){
        print("App Init")
    }
    
    func handleLink(url:URL){
        if let host = url.host()?.lowercased() {
            debugPrint("handleLink ", host)
            viewState.reset()
            
            if let backlink = url.valueOf("back_link")?.removingPercentEncoding {
                viewState.backLink = backlink
            }
            debugPrint("backlink: ", viewState.backLink)
            
            if let authToken = url.valueOf("authorization")?.removingPercentEncoding {
                if let address = url.valueOf("address")?.removingPercentEncoding {
                    viewState.authToken = authToken
                    viewState.address = address
                    debugPrint("Deeplink with auth and address: ", address)
                    Task {
                        if IsDemoMode() {
                            try await fabric.connect(network:"demo")
                        }else {
                            try await fabric.connect(network:"main")
                        }
                        
                        let login = LoginResponse(addr:address, eth:"", token:authToken)
                        fabric.setLogin(login: login, isMetamask: true)
                        setViewState(host: host, url: url)
                    }
                }else{
                    setViewState(host:host, url:url)
                }
            }else{
                setViewState(host:host, url:url)
            }
        }
    }
    
    @MainActor
    func setViewState(host:String, url:URL){
       switch(host){
       case "items":
           viewState.itemContract = url.valueOf("contract")?.lowercased() ?? ""
           viewState.itemTokenStr = url.valueOf("token") ?? ""
           viewState.marketplaceId = url.valueOf("marketplace") ?? ""
           viewState.itemSKU = url.valueOf("sku") ?? ""
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
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.edgesIgnoringSafeArea(.all)
                ContentView()
                    .environmentObject(fabric)
                    .environmentObject(viewState)
                    .preferredColorScheme(.dark)
                    .opacity(opacity)
                    .onAppear(){
                        Task {
                            do {
                                try await fabric.connect(network:"")
                            }catch{
                                print("Error connecting to the fabric: ", error)
                            }
                        }
                    }
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .inactive {
                            print("Inactive")
                            showApp = false
                        } else if newPhase == .active {
                            print("Active ")
                            Task {
                                await MainActor.run {
                                    showApp = true
                                }
                            }
                        } else if newPhase == .background {
                            print("Background")
                            showApp = false
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
}
   
