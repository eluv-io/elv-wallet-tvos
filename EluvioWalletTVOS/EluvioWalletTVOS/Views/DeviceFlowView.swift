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
import SDWebImageSwiftUI

struct DeviceFlowView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI

    @State var url = ""
    @State var urlComplete = ""
    @State var code = ""
    @State var deviceCode = ""
    @State var timer = Timer.publish(every: 1, on: .main, in: .common)
    @State var timerCancellable: Cancellable? = nil
    @State var showError = false
    @FocusState private var metaMaskFocus: Bool
    @State var showMetaMaskFlow = false
    
    var countDown:Timer!
    var expired = false
    var ClientId = ""
    var Domain = ""
    var GrantType = ""
    
    @State var isChecking = false
    
    var property : MediaProperty? = nil
    
    var logo: String {
        if let logo = eluvio.pathState.property?.login?["styling"]["logo_tv"] {
            do {
                return try eluvio.fabric.getUrlFromLink(link: logo)
            }catch{}
        }

        return ""
    }
    
    var backgroundImage: String {
        if let image = eluvio.pathState.property?.login?["styling"]["background_image_tv"] {
            do {
                return try eluvio.fabric.getUrlFromLink(link: image)
            }catch{}
        }
        
        if let image = eluvio.pathState.property?.login?["styling"]["background_image_desktop"] {
            do {
                return try eluvio.fabric.getUrlFromLink(link: image)
            }catch{}
        }
        
        return ""
    }
    
    init(property: MediaProperty?){
        //print("SignInView init()")
        self.ClientId = "O1trRaT8nCpLke9e37P98Cs9Y8NLpoar"
        self.Domain = "prod-elv.us.auth0.com"
        self.GrantType = "urn:ietf:params:oauth:grant-type:device_code"
        self.property = property
    }


    var body: some View {
        ZStack {
            Color.mainBackground.edgesIgnoringSafeArea(.all)
            WebImage(url:URL(string:backgroundImage))
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 30){
                VStack(alignment: .center, spacing:20){

                    Text("Sign In")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding()
 
                    Text(code)
                        .font(.custom("Helvetica Neue", size: 50))
                        .fontWeight(.semibold)
                    
                    if (urlComplete != ""){
                        Image(uiImage: GenerateQRCode(from: urlComplete))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 400)
                    }else{
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 400, height: 450)
                    }
                }
                .frame(width: 700)
                
                Spacer()
                    .frame(height: 10.0)
                
                VStack(alignment:.center){
                    HStack(alignment: .center, spacing:20){
                    Button(action: {
                        self.regenerateCode()
                    }) {
                        Text("Request New Code")
                            .frame(maxWidth:.infinity)
                    }
                    Button(action: {
                        //self.fabric.isLoggedOut = false
                        self.presentationMode.wrappedValue.dismiss()
                        _ = self.eluvio.pathState.path.popLast()
                    }) {
                        Text("Back")
                    }
                }
                .frame(maxWidth:.infinity)
                .focusSection()
                
                Button(action: {
                    self.showMetaMaskFlow = true
                }) {

                    Text("-Or- Sign On With Metamask")
                        .foregroundColor(metaMaskFocus ? .black : .gray)
                        .frame(width:600)
                        
                }
                .buttonStyle(.plain)
                .focused($metaMaskFocus)


            }
            .frame(width: 675)
            }
        }
        .onAppear(perform: {
            /*if(!self.eluvio.accountManager.isLoggedOut){
                self.presentationMode.wrappedValue.dismiss()
            }else{
                self.regenerateCode()
            }*/
            self.regenerateCode()
        })
        .onReceive(timer) { _ in
            checkDeviceVerification()
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
        .fullScreenCover(isPresented: $showMetaMaskFlow){
            MetaMaskFlowView(show: $showMetaMaskFlow)
        }
        
    }
    
    func regenerateCode() {
        self.eluvio.fabric.startDeviceCodeFlow(completion: {
            json,err in
            
            Task{
                do {
                    guard let signer = self.eluvio.fabric.signer else {
                        print("MetaMaskFlowView regenerateCode() called without a signer.")
                        return
                    }
                    
                    print("startDeviceCodeFlow completed");
                    
                    guard err == nil else {
                        print(err)
                        return
                        
                    }
                    guard json?["error"] == nil else {
                        
                        print((json?["error_description"] as? String)!)
                        return
                    }
                    
                    self.url = "https://elv.lv/activate"
                    
                    self.urlComplete = json?["verification_uri_complete"] as! String

                    debugPrint("Shortened URL: ", json)
                    
                    self.code = json?["user_code"] as! String
                    self.deviceCode = json?["device_code"] as! String
                    
                    debugPrint("Shortened URL: ", urlComplete)
                    
                    var interval = json?["interval"] as! Double + 2.0
                    debugPrint(interval)
                    
                    if interval < 7.0 {
                        interval = 7.0
                    }
                    
                    let validFor = json?["expires_in"] as! Int
                    self.timer = Timer.publish(every: interval, on: .main, in: .common)
                    self.timerCancellable = self.timer.connect()
                    /*self.countDown = Timer.scheduledTimer(timeInterval: TimeInterval(validFor), target: self, selector: #selector(self.onTimerFires), userInfo: nil, repeats: true)*/
                    
                    //self.expired = false
                }catch{
                    print("Error regenerating code for sign in: ", error)
                }
            }

        })
    }
                                    
    
    func checkDeviceVerification(){
        if self.isChecking {
            return
        }
        
        self.isChecking = true
        print("checkDeviceVerification \(self.code)");
        let oAuthEndpoint: String = "https://".appending(self.Domain).appending("/oauth/token");
        
        let authRequest = ["grant_type":self.GrantType,"device_code": self.deviceCode, "client_id":self.ClientId] as! Dictionary<String,String>
        AF.request(oAuthEndpoint , method: .post, parameters: authRequest, encoding: JSONEncoding.default)
            .responseJSON { response in
                debugPrint("Response: \(response)")
                
                defer {
                    self.isChecking = false
                }
   
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
                            
                            var newProperty : MediaProperty? = nil
                            
                            Task {
                                do {
                                    debugPrint("verification result: ", json)
                                    //try await eluvio.fabric.signIn(credentials: json)
                                    guard let idToken: String = json["id_token"] as? String else {
                                        print("Could not retrieve id_token")
                                        return
                                    }
                                    
                                    eluvio.pathState.path.append(.progress)
                                    
                                    //We do not get the refresh token with device sign in for some reason
                                    let refreshToken: String = json["refresh_token"] as? String ?? ""
                                    let accessToken: String = json["access_token"] as? String ?? ""

                                    var signInResponse = SignInResponse()
                                    signInResponse.idToken = idToken
                                    signInResponse.refreshToken = refreshToken
                                    signInResponse.accessToken = accessToken
                                    
                                    let login = try await eluvio.fabric.login(idToken: idToken)
                                    
                                    let account = Account()
                                    account.type = .Auth0
                                    account.fabricToken = try await eluvio.fabric.createFabricToken(login:login)
                                    account.signInResponse = signInResponse
                                    account.login = login
                                    try await eluvio.signIn(account:account, property: property?.id ?? "")
                                    try await eluvio.fabric.getProperties(includePublic: true, newFetch: true)
                                    newProperty = try await eluvio.fabric.getProperty(property: property?.id ?? "")
                                }catch {
                                    print("could not sign in: \(error.localizedDescription)")
                                }
                                
                                await MainActor.run {
                                    debugPrint("Sign in finished.")
                                    eluvio.pathState.path.removeAll()
                                    debugPrint("current Account ", eluvio.accountManager.currentAccount?.getAccountAddress() ?? "")
                                    
                                    let params = PropertyParam(property:newProperty)
                                    eluvio.pathState.path.append(.property(params))
                                    self.isChecking = false
                                }
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
