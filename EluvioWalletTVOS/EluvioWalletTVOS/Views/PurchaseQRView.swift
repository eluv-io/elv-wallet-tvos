//
//  PurchaseQRView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-10-02.
//

import SwiftUI
import SDWebImageSwiftUI

struct PurchaseQRView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    var url: String
    @State var shortenedUrl: String = ""
    var cleanUrl : String {
        return shortenedUrl.replaceFirst(of: "https://", with: "")
            .replaceFirst(of: "http://", with: "")
    }
    var backgroundImage: String = ""
    var thumbnailImage: String = ""
    var sectionItem: MediaPropertySectionItem?
    var mediaItem: MediaPropertySectionMediaItem?
    var sectionId : String = ""
    var pageId : String = ""
    var propertyId: String = ""
    @State var timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @State var isChecking = false
    @State var title: String = "Sign In On Browser to Purchase"
    @State var success: Bool = false
    
    //XXX:
    //@State var count = 0
    
    var body: some View {
        ZStack{
            if !backgroundImage.isEmpty{
                WebImage(url:URL(string:backgroundImage))
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
            if success {
                VStack(alignment: .center, spacing:20){
                    Text("Success").font(.title)
                        .padding()
                        .padding(.bottom, 20)
                    
                    Text("Return to the property to enjoy your media.").font(.description)
                        .multilineTextAlignment(.center)
                        .padding()
                        .padding(.bottom, 20)
                    
                    Button(action:{
                        //eluvio.fabric.TESTING = true
                        eluvio.needsRefresh()
                        eluvio.pathState.path.popLast()
                    },label:{
                        Text("Continue to Property")
                    })
                }
            }else {
                VStack(alignment: .center, spacing:20){
                    Text(title).font(.title)
                        .multilineTextAlignment(.center)
                        .padding()
                        .padding(.bottom, 20)
                        .frame(width:1400)
                    
                    HStack{
                        if !shortenedUrl.isEmpty {
                            VStack(alignment: .center, spacing:40) {
                                Text("or visit \(cleanUrl)").font(.description)
                                Image(uiImage: GenerateQRCode(from: shortenedUrl))
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 400, height: 400)
                            }
                        }else{
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: 400, height: 400)
                        }
                        
                    }
                    .padding(.bottom, 40)
                    
                    Button(action:{
                        eluvio.pathState.path.popLast()
                    },label:{
                        Text("Back")
                    })
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .edgesIgnoringSafeArea(.all)
        .background(.thinMaterial)
        .onAppear(){
            debugPrint("Purchase URL \(url)")
            Task {
                do {
                    self.shortenedUrl = try await eluvio.fabric.signer?.shortenUrl(url: url) ?? ""
                }catch{}
            }

        }
        .onReceive(timer) { _ in
            checkPurchase()
        }
    }
    
    func checkPurchase(){
        debugPrint("Check purchase")
        Task {
            if self.isChecking || self.success{
                return
            }
            
            self.isChecking = true
            do {
                //Should always be no_cache
                let result = try await eluvio.fabric.getPropertyPermissions(propertyId:propertyId)
                debugPrint("getPropertyPermissions result ", result)
                let authState = result["permission_auth_state"]
                
                if authState.isEmpty {
                    return
                }
                
                var permissions = ResolvedPermission()
                
                if let sectionItemId = sectionItem?.id {
                    if let mediaItemId = mediaItem?.id {
                        debugPrint("has mediaItem ", mediaItemId)
                        permissions = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId,
                                                                                        pageId: pageId,
                                                                                        sectionId: sectionId,
                                                                                        sectionItemId: sectionItemId,
                                                                                        mediaItemId: mediaItemId,
                                                                                       permissionAuthState: authState)
                    }else {
                        permissions = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId,
                                                                                        pageId: pageId,
                                                                                        sectionId: sectionId,
                                                                                        sectionItemId: sectionItemId,
                                                                                       permissionAuthState: authState)
                    }
                    
                    debugPrint("Permissions: ", permissions)
                    
                    if permissions.authorized/* || count == 3*/{
                        debugPrint("Authorized!")
                        self.success = true
                    }
            
                }
                
               // count+=1
            }catch{
                print("Check purchase error ", error)
            }
            
            self.isChecking = false
        }
    }
}
