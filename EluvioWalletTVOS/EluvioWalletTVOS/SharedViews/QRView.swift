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
    var backgroundImage: String = ""
    @State var shortenedUrl: String = ""
    @State var title: String = "Point your camera to the QR Code below for content"
    @State var description: String = ""
    
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
                    .frame(width:1000)
                if description != "" {
                    Text(description).font(.description)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width:1000)
                }
                if !shortenedUrl.isEmpty {
                    Image(uiImage: GenerateQRCode(from: shortenedUrl))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 400)
                }else{
                    Rectangle()
                        .background(.clear)
                        .frame(width: 400, height: 400)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .edgesIgnoringSafeArea(.all)
        .background(
            .thinMaterial
        )
        .onAppear(){
            debugPrint("QRView URL \(url)")
            Task {
                do {
                    self.shortenedUrl = try await eluvio.fabric.signer?.shortenUrl(url: url) ?? ""
                }catch{}
            }

        }
    }
}

