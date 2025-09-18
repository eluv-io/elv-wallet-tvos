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
    @State var opacity : CGFloat = 0.0
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
                        opacity = 0
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
        .opacity(opacity)
        .onAppear(perform: {
            debugPrint("OryDeviceFlowView pathState ", eluvio.pathState.path)
            Task{
                await self.regenerateCode()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 2)) {
                        self.opacity = 1.0
                    }
                }
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
            
            let url = "https://wallet.contentfabric.io/login?pid=\(self.propertyId)&ory=true&action=login&mode=login&response=code&source=code&refresh=true&ttl=336"
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
                return
            }
            debugPrint("Ory Result ", result)
            
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
            let email = json["email"].stringValue
            let expiresAt = json["expiresAt"].int64Value
            let clusterToken = json["clusterToken"].stringValue
            debugPrint("EMAIL: ", email)

            do {
                let login = LoginResponse(type: type, addr:addr, eth:eth, token: token)
                debugPrint("Ory signing in ")
                await MainActor.run {
                    eluvio.pathState.path.append(.progress)
                }

                let account = Account()
                account.type = .Ory
                account.login = login
                
                if expiresAt > 0 {
                    account.expiresAt = expiresAt
                }else {
                    let duration: Int64 = 1 * 24 * 60 * 60 * 1000
                    account.expiresAt = Date().now + duration
                }

                account.email = email
                account.fabricToken = token
                account.login = login
                account.clusterToken = clusterToken
                
                try await eluvio.signIn(account:account, property: property?.id ?? "")
                eluvio.needsRefresh()
                debugPrint("Ory Signing in done!")
            }catch {
                print("could not sign in: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                debugPrint("Sign in finished.")

                eluvio.pathState.path.removeAll()
                debugPrint("Popped the path state.")
                let params = PropertyParam(property:property)
                eluvio.pathState.path.append(.property(params))

                self.isChecking = false
            }

            self.timerCancellable!.cancel()
        } catch {
            await MainActor.run {
                print("checkDeviceVerification error", error)
                self.errorMessage =  error.localizedDescription
                showError = true
            }
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
