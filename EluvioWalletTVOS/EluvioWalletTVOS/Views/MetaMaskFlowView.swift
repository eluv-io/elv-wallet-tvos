//
//  MetaMaskFlowView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-07-12.
//

import SwiftUI
import AuthenticationServices
import SwiftEventBus
import CoreImage.CIFilterBuiltins
import Alamofire
import Combine
import SwiftyJSON

struct MetaMaskFlowView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric

    @State var url = ""
    @State var code = ""
    @State var deviceCode = ""
    @State var timer = Timer.publish(every: 1, on: .main, in: .common)
    @State var timerCancellable: Cancellable? = nil
    @State var showError = false
    @State var errorMessage = ""
    @FocusState private var metaMaskFocus: Bool
    @State var showMetaMaskFlow = false
    
    var countDown:Timer!
    var expired = false
    var Domain = ""
    
    @State private var response = JSON()
    
    init(show: Binding<Bool>){
        self.Domain = "prod-elv.us.auth0.com"
    }


    var body: some View {
        ZStack {
            Color.mainBackground.edgesIgnoringSafeArea(.all)
            VStack{
                HeaderView()
                    .padding(.top,50)
                    .padding(.leading,80)
                    .padding(.bottom,80)
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 30){
                VStack(alignment: .center, spacing:20){
                    /*
                     VStack(alignment: .center, spacing:10){
                     Image("e_logo")
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(width:200)
                     Text("Media Wallet")
                     .font(.custom("Helvetica Neue", size: 90))
                     .padding(.bottom,40)
                     }*/
                    
                    
                    Text("Sign On with MetaMask")
                        .font(.custom("Helvetica Neue", size: 50))
                        .fontWeight(.semibold)
                    
                    Image("metamask_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:150)
                    
                    Text(code)
                        .font(.custom("Helvetica Neue", size: 50))
                        .fontWeight(.semibold)

                    if (url != ""){
                        Image(uiImage: GenerateQRCode(from: url))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 400)
                    }else{
                        ProgressView()
                            .frame(width: 400, height: 450)
                    }
                }
                .frame(width: 700)
                
                Spacer()
                    .frame(height: 10.0)
                
                Button(action: {
                    Task{
                        await self.regenerateCode()
                    }
                }) {
                    Text("Request New Code")
                        //.frame(width:400)
                }
        
            }
        }
        .onAppear(perform: {
            if(!self.fabric.isLoggedOut){
                self.presentationMode.wrappedValue.dismiss()
            }else{
                Task{
                    await self.regenerateCode()
                }
            }
        })
        .onReceive(timer) { _ in
            Task{
                await checkDeviceVerification()
            }
        }
        .fullScreenCover(isPresented: $showError) {
            VStack{
                Spacer()
                Text("Error connecting to the Network. Please try again later.")
                Spacer()
            }
            .background(Color.black.opacity(0.8))
            .background(.thickMaterial)
        }
    }
    
    func regenerateCode() async {
        self.errorMessage = ""
        
        do {
            guard let signer = self.fabric.signer else {
                print("MetaMaskFlowView regenerateCode() called without a signer.")
                return
            }
            
            let json = try await signer.createMetaMaskLogin()
            
            self.response = json
            
            print("createMetaMaskLogin completed");
            
            
            debugPrint("MetaMask create response: ",json)
            //self.url = json?["verification_uri"] as! String
            self.url = json["metamask_url"].stringValue
            if (!self.url.hasPrefix("https") && !self.url.hasPrefix("http")){
                self.url = "https://".appending(self.url)
            }

            //Tried the metamask:// prefix but doesn't work either
            //self.url = self.url.replacingOccurrences(of: "metamask.app.link", with: "metamask:/")
            
            debugPrint("METAMASK URL: ", self.url)
            
            self.code = json["id"].stringValue
            self.deviceCode = json["passcode"].stringValue
            
            let interval = 5.0
            self.timer = Timer.publish(every: interval, on: .main, in: .common)
            self.timerCancellable = self.timer.connect()
            /*self.countDown = Timer.scheduledTimer(timeInterval: TimeInterval(validFor), target: self, selector: #selector(self.onTimerFires), userInfo: nil, repeats: true)*/
            
            //self.expired = false
            
        }catch{
            print("Could not get code for MetaMask login", error)
        }
    }
                                    
    
    func checkDeviceVerification() async{
        print("Metamask checkDeviceVerification \(self.code)");
        do {
            guard let result = try await self.fabric.signer?.checkMetaMaskLogin(createResponse: response) else{
                print("MetaMaskFlowView checkDeviceVerification() checkMetaMaskLogin returned nil")
                return
            }
            

            let status = result["status"].intValue
            
            if(status != 200){
                print("Check value \(result)")
                /*
                self.timerCancellable!.cancel()
                print("Error \(json)")
                self.errorMessage = json["error"].stringValue
                showError = true
                 */
                return
            }
            
            debugPrint("Result ", result)
            
            let json = JSON.init(parseJSON:result["payload"].stringValue)
            
            if json.isEmpty {
                print("MetaMaskFlowView checkDeviceVerification() json payload is empty.")
                showError = true
                return
            }
            
            let token = json["token"].stringValue
            let addr = json["addr"].stringValue
            let eth = json["eth"].stringValue
            
            let login = LoginResponse(addr:addr, eth:eth, token:token)
            fabric.setLogin(login: login, isMetamask: true)
            
            self.timerCancellable!.cancel()
            
        } catch {
            print("checkDeviceVerification error", error)
        }
        
        /*
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
                                //print("key \(key) value2 \(value)")
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
         */
    }
}

struct MetaMaskFlowView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
