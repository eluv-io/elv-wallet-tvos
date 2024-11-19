//
//  PurchaseView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-11-19.
//

import SwiftUI
import SDWebImageSwiftUI

//This is a simple view without a QR Code to purchase since it's against Apple's policy's
struct PurchaseView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @State var customDomain: String = "Eluvio Media Wallet"

    var backgroundImage: String = ""
    var propertyId: String = ""

    
    var body: some View {
        ZStack{
            if !backgroundImage.isEmpty{
                WebImage(url:URL(string:backgroundImage))
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(alignment: .center, spacing:20){
                Text("Sign In On Browser to Purchase").font(.title)
                    .padding()
                    .padding(.bottom, 20)
                
                Text("To watch this content, visit the \(customDomain)\nweb site on your mobile device or computer to\nadd the corresponding access pass.").font(.description)
                    .multilineTextAlignment(.center)
                    .padding()
                    .padding(.bottom, 20)
                
                Button(action:{
                    eluvio.needsRefresh()
                    _ = eluvio.pathState.path.popLast()
                },label:{
                    Text("Back")
                })
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .edgesIgnoringSafeArea(.all)
        .background(.thinMaterial)
        .onAppear(){
            Task {
                if let property = try await eluvio.fabric.getProperty(property: propertyId)  {
                    
                    if let domain = property.domain?["custom_domain"].stringValue {
                        if !domain.isEmpty {
                            self.customDomain = domain
                        }
                    }
                }
            }
        }
    }
}
