//
//  QRView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-14.
//

import SwiftUI
import SwiftyJSON

struct QRView: View {
    @EnvironmentObject var fabric: Fabric
    @Binding var url: String
    
    var body: some View {
            VStack(alignment: .center, spacing:20){
                Text("Point your camera to the QR Code below for content").font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width:1000)
                Image(uiImage: GenerateQRCode(from: url))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400)
            }
            .onAppear(){
                print("Experience URL \(url)")
            }
    }
}

struct QRView_Previews: PreviewProvider {
    @State static var url = "https://eluv.io"
    static var previews: some View {
        QRView(url:$url)
            .environmentObject(Fabric())
    }
}
