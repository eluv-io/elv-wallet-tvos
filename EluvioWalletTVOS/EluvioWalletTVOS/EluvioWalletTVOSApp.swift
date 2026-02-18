//
//  EluvioWalletTVOSApp.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-23.
//

import SwiftUI
import SDWebImage

/*
@main
struct EluvioWalletTVOSApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject
    var fabric = Fabric()
    @StateObject
    var viewState = ViewState()
    
    @State var showApp = false
    
    @State var opacity : CGFloat = 0.0
    
    init(){
        print("App Init")
    }
    
    var body: some Scene {
        WindowGroup {
            WalletApp(isBranded: false)
        }
    }
}
   
*/

@main
struct EluvioWalletTVOSApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var eluvio = EluvioAPI()
    
    @State var showLoader: Bool = false
    
    @State var opacity : CGFloat = 0.0
    
    init(){
        print("App Init")

        // Configure SDWebImage to strip the "authorization" query parameter from cache keys.
        // Image URLs embed the current fabricToken as ?authorization=<token>. When the token
        // changes (e.g. after sign-in), SDWebImage would treat identical images as different
        // cache entries because the full URL differs. By stripping "authorization" from the
        // cache key, the same image always hits the same cache entry regardless of token.
        SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter { url in
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return url.absoluteString
            }
            components.queryItems = components.queryItems?.filter { $0.name != "authorization" }
            if components.queryItems?.isEmpty == true {
                components.queryItems = nil
            }
            return components.url?.absoluteString ?? url.absoluteString
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.edgesIgnoringSafeArea(.all)
                if showLoader {
                        ZStack{
                            Color.black.edgesIgnoringSafeArea(.all)
                            ProgressView()
                        }
                        .frame(minWidth: 0, maxWidth: .infinity , minHeight: 0, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                }else {
                    ContentView()
                        .opacity(opacity)
                        .environmentObject(eluvio)
                        .preferredColorScheme(.dark)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive {
                    self.opacity = 0.0
                } else if newPhase == .active {
                    Task {
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 3)) {
                                self.opacity = 1.0
                            }
                        }
                    }
                } else if newPhase == .background {
                    self.opacity = 0.0
                }
            }
            .onOpenURL { url in
                Task {
                    self.showLoader = true
                    await eluvio.viewState.handleLink(url:url, fabric:eluvio.fabric)
                    self.showLoader = false
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}
