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
    @State var timer = Timer.publish(every: 1, on: .main, in: .common)
    @State var isChecking = false
    @State var title: String = "Sign In On Browser to Purchase"
    
    var body: some View {
        ZStack{
            if !backgroundImage.isEmpty{
                WebImage(url:URL(string:backgroundImage))
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
            
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
        .onWillDisappear {
            debugPrint("PurchaseQRView onWillDisappear ")
            Task{
                //Trigger to clear the cache on the backend
                _ = try await eluvio.fabric.getProperty(property:propertyId,noCache: true)
            }
        }
        .onReceive(timer) { _ in
            checkPurchase()
        }
    }
    
    func checkPurchase(){
        Task {
            if self.isChecking {
                return
            }
            
            self.isChecking = true
            do {
                let result = try await eluvio.fabric.getPropertyPermissions(propertyId:propertyId)
                
                debugPrint("checkPurchase ", result)
                
            }catch{
                print("Check purchase error ", error)
            }
        }
    }
}
