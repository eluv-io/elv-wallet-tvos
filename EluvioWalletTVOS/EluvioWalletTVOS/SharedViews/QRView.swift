//
//  QRView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import SwiftUI
import SwiftyJSON

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

struct QRView_Previews: PreviewProvider {
    @State static var url = "https://eluv.io"
    static var previews: some View {
        QRView(url:url)
            .environmentObject(Fabric())
    }
}
