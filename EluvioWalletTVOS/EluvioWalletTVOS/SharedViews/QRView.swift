//
//  QRView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import SwiftUI
import SwiftyJSON
import SDWebImageSwiftUI

struct QRView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    var url: String
    @State var title: String = "Point your camera to the QR Code below for content"
    @State var description: String = ""
    
    var body: some View {
            VStack(alignment: .center, spacing:20){
                Text(title).font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width:1000)
                if description != "" {
                    Text(description).font(.description)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width:1000)
                }
                Image(uiImage: GenerateQRCode(from: url))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .edgesIgnoringSafeArea(.all)
            .background(.thinMaterial)
            .onAppear(){
                print("Experience URL \(url)")
            }
    }
}

struct PurchaseQRView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    var url: String
    var sectionItem: MediaPropertySectionItem?
    var sectionId : String = ""
    var pageId : String = ""
    var propertyId: String = ""
    
    @State var title: String = "Sign In On Browser to Purchase"
    
    var body: some View {
        VStack(alignment: .center, spacing:20){
            Text(title).font(.title)
                .multilineTextAlignment(.center)
                .padding()
                .padding(.bottom, 40)
                .frame(width:1000)
            
            HStack{
                if let item = sectionItem{
                    VStack{
                        SectionItemView(item:item, sectionId:sectionId, pageId:pageId, propertyId: propertyId)
                            .disabled(true)
                    }
                }
                
                Image(uiImage: GenerateQRCode(from: url))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 264, height: 264)

            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .edgesIgnoringSafeArea(.all)
        .background(.thinMaterial)
        .onAppear(){
            debugPrint("Purchase URL \(url)")
        }
    }
}

struct QRView_Previews: PreviewProvider {
    @State static var url = "https://eluv.io"
    static var previews: some View {
        QRView(url:url)
            .environmentObject(Fabric())
    }
}
