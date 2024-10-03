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
                    .padding(.bottom, 40)
                    .frame(width:1000)
                
                HStack{
                    // Latest design, does not want item
                    /*
                    if let mediaItem = mediaItem {
                        VStack{
                            SectionMediaItemView(item:mediaItem, propertyId: propertyId)
                                .disabled(true)
                        }
                    }else if let item = sectionItem{
                        VStack{
                            SectionItemView(item:item, sectionId:sectionId, pageId:pageId, propertyId: propertyId)
                                .disabled(true)
                        }
                    }
                     */
                    
                    Image(uiImage: GenerateQRCode(from: url))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 400)
                    
                }
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .edgesIgnoringSafeArea(.all)
        .background(.thinMaterial)
        .onAppear(){
            debugPrint("Purchase URL \(url)")

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
