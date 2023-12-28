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
    @FocusState private var signInFocus: Bool

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
        //print("SignInView init()")
        self.subscriber = Subscriber(view:self)
        UISegmentedControl.appearance().setTitleTextAttributes([.font : UIFont.preferredFont(forTextStyle: .body)], for: .normal)
    }


    var body: some View {
        if !showDeviceFlow {
            ZStack {
                Color.mainBackground.edgesIgnoringSafeArea(.all)
                VStack(alignment: .center, spacing: 30){
                    VStack(alignment: .center, spacing:10){
                        Image("SignIn_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width:700)
                            .padding(.bottom, 80)

                        if IsDemoMode() {
                            Picker("Networks", selection: $networkSelection) {
                                ForEach(Networks.allCases) { network in
                                    Text("\(network.name.capitalizingFirstLetter())")
                                        .font(.custom("Helvetica Neue", size: 10))
                                }
                            }
                            .frame(width:300)
                        }

                    }
                    
                    if fabric.signingIn {
                        ProgressView()
                    }else {
                        Button(action: {
                            self.showDeviceFlow = true
                            Task {
                                do {
                                    //ONLY MAIN FOR PROD
                                    //if IsDemoMode() {
                                        try await fabric.connect(network:networkSelection.name)
                                    /*}else {
                                        try await fabric.connect(network:"main")
                                    }*/
                                } catch {
                                    print("Request failed with error: \(error)")
                                }
                            }
                        }) {
                            Text("Sign In")
                        }
                        .focused($signInFocus)
                        
                    }
                }
            }.onAppear(){
                DispatchQueue.main.asyncAfter(deadline: .now()+0.7) {
                    signInFocus = true
                }
            }
        } else {
            DeviceFlowView(showDeviceFlow:$showDeviceFlow)
                .preferredColorScheme(colorScheme)
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
