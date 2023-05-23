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
import Alamofire
import Combine

struct DeviceFlowView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric

    @State var url = ""
    @State var urlComplete = ""
    @State var code = ""
    @State var deviceCode = ""
    @State var timer = Timer.publish(every: 1, on: .main, in: .common)
    @State var timerCancellable: Cancellable? = nil
    @Binding var showDeviceFlow: Bool
    var countDown:Timer!
    var expired = false
    var ClientId = ""
    var Domain = ""
    var GrantType = ""
    
    init(showDeviceFlow: Binding<Bool>){
        print("SignInView init()")
        self.ClientId = "O1trRaT8nCpLke9e37P98Cs9Y8NLpoar"
        self.Domain = "prod-elv.us.auth0.com"
        self.GrantType = "urn:ietf:params:oauth:grant-type:device_code"
        _showDeviceFlow = showDeviceFlow
    }


    var body: some View {
        ZStack {
            Color.mainBackground.edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 30){
                VStack(alignment: .center, spacing:20){
                    VStack(alignment: .center, spacing:10){
                        Image("e_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width:200)
                        Text("Media Wallet")
                            .font(.custom("Helvetica Neue", size: 90))
                            .padding(.bottom,40)
                    }
                    

                    Text("Scan QR Code")
                        .font(.custom("Helvetica Neue", size: 50))
                        .fontWeight(.semibold)
                    Text("Scan the QR Code with your camera app or a QR code reader on your device.")
                        .font(.custom("Helvetica Neue", size: 30))
                        .fontWeight(.thin)
                        .frame(width: 600)
                        .multilineTextAlignment(.center)
                    
                    Image(uiImage: GenerateQRCode(from: urlComplete))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                }
                .frame(width: 700)
                
                Spacer()
                    .frame(height: 10.0)
                
                HStack(alignment: .center){
                    Button(action: {
                        self.regenerateCode()
                    }) {
                        Text("Request New Code")
                    }
                    Button(action: {
                        //self.fabric.isLoggedOut = false
                        //self.presentationMode.wrappedValue.dismiss()
                        showDeviceFlow = false
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
        .onAppear(perform: {
            if(!self.fabric.isLoggedOut){
                self.presentationMode.wrappedValue.dismiss()
            }else{
                self.regenerateCode()
            }
        })
        .onReceive(timer) { _ in
            checkDeviceVerification()
        }
    }
    
    func regenerateCode() {
        self.fabric.startDeviceCodeFlow(completion: {
            json,err in
            
            print("startDeviceCodeFlow completed");
            
            guard err == nil else {
                print(err)
                return
                
            }
            guard json?["error"] == nil else {
                
                print((json?["error_description"] as? String)!)
                return
            }
            
            //print(json)
            //self.url = json?["verification_uri"] as! String
            self.url = "https://elv.lv/activate"
            
            self.urlComplete = json?["verification_uri_complete"] as! String
            self.code = json?["user_code"] as! String
            self.deviceCode = json?["device_code"] as! String
            
            var interval = json?["interval"] as! Double + 1.0
            let validFor = json?["expires_in"] as! Int
            self.timer = Timer.publish(every: interval, on: .main, in: .common)
            self.timerCancellable = self.timer.connect()
            /*self.countDown = Timer.scheduledTimer(timeInterval: TimeInterval(validFor), target: self, selector: #selector(self.onTimerFires), userInfo: nil, repeats: true)*/

            //self.expired = false

        })
    }
                                    
    
    func checkDeviceVerification(){
        print("checkDeviceVerification \(self.code)");
        let oAuthEndpoint: String = "https://".appending(self.Domain).appending("/oauth/token");
        
        let authRequest = ["grant_type":self.GrantType,"device_code": self.deviceCode, "client_id":self.ClientId] as! Dictionary<String,String>
        AF.request(oAuthEndpoint , method: .post, parameters: authRequest, encoding: JSONEncoding.default)
            .responseJSON { response in
                debugPrint("Response: \(response)")
   
                switch (response.result) {
                    case .success( _):
                        if let json = response.value as? [String: AnyObject] {
                            guard json["error"] == nil else {
                                print(json["error_description"] as? String ?? "");
                                
                                if(json["error"] as? String != "authorization_pending"){
                                    self.timerCancellable!.cancel()
                                    print(json["error"]?.localizedDescription ?? "Error \(json)")
                                }
                                return
                            }
                            
                            fabric.signIn(credentials: json)
                            
                            for (key, value) in json {
                                print("key \(key) value2 \(value)")
                                UserDefaults.standard.set(value as? String, forKey: key)
                            }
                            
                            self.timerCancellable!.cancel()
                        }else{
                            print("didn't get response yet!")
                        }
                     case .failure(let error):
                        print("Request error: \(error.localizedDescription)")

                 }
            return
        }
    }
}

struct DeviceFlowView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
