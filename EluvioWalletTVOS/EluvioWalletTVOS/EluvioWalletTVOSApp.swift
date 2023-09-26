//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI

enum LinkOp {
    case item, media, none
}

class ViewState: ObservableObject {
    @Published var op: LinkOp  = .none
    var itemContract = ""
    var itemTokenStr = ""
    var mediaId = ""
    
    func reset() {
        itemContract = ""
        itemTokenStr = ""
        mediaId = ""
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
             
            switch(host){
            case "items":
                viewState.itemContract = url.valueOf("contract")?.lowercased() ?? ""
                viewState.itemTokenStr = url.valueOf("token") ?? ""
                viewState.op = .item
                debugPrint("handleLink viewState changed")
            case "media":
                viewState.mediaId = url.valueOf("id") ?? ""
                viewState.op = .media
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
   
