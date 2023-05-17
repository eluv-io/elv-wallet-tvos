//
//  SignInView.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-08-10.
//

import SwiftUI
import AuthenticationServices
import SwiftEventBus
import CoreImage.CIFilterBuiltins

class Subscriber {
    var view : Any
    init(view: Any){
        self.view = view
    }
}

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    
    var subscriber : Subscriber?
    @State var url :String = ""
    @State var code :String = ""
    @State var showDeviceFlow = false

    enum Networks: String, CaseIterable, Identifiable {
        case main="main", demo="demo"
        var name: String {
            get { return String(describing: self) }
        }
        var id: Self { self }
    }
    
    @State private var networkSelection: Networks = .main
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    init(){
        print("SignInView init()")
        self.subscriber = Subscriber(view:self)
    }


    var body: some View {
        if !showDeviceFlow {
            ZStack {
                Color.mainBackground.edgesIgnoringSafeArea(.all)
                VStack(alignment: .center, spacing: 30){
                    VStack(alignment: .center, spacing:20){
                        Image("e_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width:200)
                        HStack(spacing:5){
                            Text("ELUV.IO")
                                .font(.custom("Helvetica Neue", size: 80))
                                .fontWeight(.thin)
                            Text("Wallet")
                                .font(.custom("Helvetica Neue", size: 80))
                                .fontWeight(.bold)
                        }
                        Picker("Networks", selection: $networkSelection) {
                            ForEach(Networks.allCases) { network in
                                Text("\(network.name.uppercased())")
                            }
                        }
                        .frame(width:400)
                    }
                    
                    Spacer()
                        .frame(height: 10.0)
                    
                    if fabric.signingIn {
                        ProgressView()
                    }else {
                        Button(action: {
                            self.showDeviceFlow = true
                            Task {
                                do {
                                    try await fabric.connect(network:networkSelection.name)
                                } catch {
                                    print("Request failed with error: \(error)")
                                }
                            }
                        }) {
                            Text("SIGN IN")
                        }
                    }
                }
            }
        } else {
            DeviceFlowView(showDeviceFlow:$showDeviceFlow)
                .preferredColorScheme(colorScheme)
        }
            /*
        .fullScreenCover(isPresented: $showDeviceFlow) {
            DeviceFlowView()
                .preferredColorScheme(colorScheme)
        }
        .onAppear {
            print("SignInView onAppear \(self.fabric.isLoggedOut)")
            if(!self.fabric.isLoggedOut){
                self.presentationMode.wrappedValue.dismiss()
            }
        }*/
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
