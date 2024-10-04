//
//  OryDeviceFlowView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-24.
//

import SwiftUI
import AuthenticationServices
import CoreImage.CIFilterBuiltins
import Alamofire
import Combine
import SwiftyJSON
import SDWebImageSwiftUI

struct OryDeviceFlowView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio : EluvioAPI
    @State var url = ""
    @State var statusUrl: String = ""
    @State var code = ""
    @State var deviceCode = ""
    @State var timer = Timer.publish(every: 1, on: .main, in: .common)
    @State var timerCancellable: Cancellable? = nil
    @State var showError = false
    @State var errorMessage = ""
    @State private var response = JSON()
    
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
    
    var propertyId : String {
        if let id = eluvio.pathState.property?.id{
            return id
        }
        
        return ""
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
                    if (url != ""){
                        Image(uiImage: GenerateQRCode(from: url))
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
                
                HStack(alignment: .center, spacing:40){
                    Button(action: {
                        Task{
                            await self.regenerateCode()
                        }
                    }) {
                        Text("Request New Code")
                    }
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Back")
                    }
                }
                .focusSection()
                .padding(.bottom,40)
                
            }
        }
        .frame(maxWidth:.infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .background(.thickMaterial)
        .onAppear(perform: {
            /*if(!eluvio.accountManager.isLoggedOut){
                self.presentationMode.wrappedValue.dismiss()
            }else{
                Task{
                    await self.regenerateCode()
                }
            }*/
            
            Task{
                await self.regenerateCode()
            }
        })
        .onReceive(timer) { _ in
            Task {
                await checkDeviceVerification(statusUrl: statusUrl)
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
        do {
            guard let signer = self.eluvio.fabric.signer else {
                print("MetaMaskFlowView regenerateCode() called without a signer.")
                return
            }
            
            let url = "https://wallet.contentfabric.io/login?pid=\(self.propertyId)&ory=true&action=login&mode=login&response=code&source=code"
            let json = try await signer.createAuthLogin(redirectUrl: url)
            
            self.response = json
            
            print("createAuthLogin completed");
            
            
            debugPrint("Create response: ",json)

            var _url = json["url"].stringValue
            if (!_url.hasPrefix("https") && !_url.hasPrefix("http")){
                _url = "https://".appending(_url)
            }
            
            debugPrint("URL: ", self.url)
            self.url = try await signer.shortenUrl(url: _url)
            debugPrint("Ory shortened URL: ", _url)
            
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
                                    
    
    func checkDeviceVerification(statusUrl: String) async {
        print("checkDeviceVerification \(self.code)");
        if self.isChecking {
            return
        }
        
        self.isChecking = true
        
        defer {
            self.isChecking = false
        }
        
        do {
            guard let result = try await self.eluvio.fabric.signer?.checkAuthLogin(createResponse: response) else{
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
            
            let type = json["type"].stringValue
            let token = json["token"].stringValue
            let addr = json["addr"].stringValue
            let eth = json["eth"].stringValue


            var newProperty : MediaProperty? = nil
            do {
                //var signInResponse = SignInResponse()
                //signInResponse.idToken = token
                let login = LoginResponse(type: type, addr:addr, eth:eth, token: token)
                debugPrint("Ory signing in ")
                eluvio.pathState.path.append(.progress)

                let account = Account()
                account.type = .Ory
                account.fabricToken = token
                account.login = login
                try await eluvio.signIn(account:account, property: property?.id ?? "")
                try await eluvio.fabric.getProperties(includePublic: true, newFetch: true)
                
                newProperty = try await eluvio.fabric.getProperty(property: property?.id ?? "")
                debugPrint("Ory Signing in done!")
            }catch {
                print("could not sign in: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                debugPrint("Sign in finished.")
                eluvio.pathState.path.removeAll()
                debugPrint("Popped the path state.")
                let params = PropertyParam(property:newProperty)
                eluvio.pathState.path.append(.property(params))
                self.isChecking = false
            }

            self.timerCancellable!.cancel()
        } catch {
            print("checkDeviceVerification error", error)
            self.errorMessage =  error.localizedDescription
            showError = true
        }
    }
}

/*
struct DeviceFlowView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceFlowView()
    }
}
*/
