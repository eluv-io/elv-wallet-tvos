//
//  OfferView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-06-22.
//

import SwiftUI
import SDWebImageSwiftUI
import AVFoundation
import SwiftyJSON

struct OfferView: View {
    @EnvironmentObject var fabric: Fabric
    @StateObject var redeemable: RedeemableViewModel
    @State private var playerItem: AVPlayerItem? = nil
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.square
    @State var imageUrl: String = ""
    @State var showPlayer: Bool = false
    @State var showResult: Bool = false
    @State var playerFinished: Bool = false
    @State var isRedeeming: Bool = false
    
    private var isRedeemed : Bool {
        return redeemable.status.isRedeemed
    }
    
    private var isActive : Bool {
        return redeemable.status.isActive
    }
    
    private var hasImage :  Bool {
        return redeemable.posterUrl != "" || redeemable.imageUrl != ""
    }
    
    var body: some View {
        ZStack{
            VStack{
                HStack(alignment:.top, spacing:100){
                    Spacer()
                    if redeemable.posterUrl != "" {
                        WebImage(url:URL(string:redeemable.posterUrl))
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFit()
                            .frame(width:400)
                    }else if (redeemable.imageUrl != ""){
                        WebImage(url:URL(string:redeemable.imageUrl))
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFit()
                            .frame(width:400)
                    }
                    VStack(alignment: hasImage ? .leading : .center, spacing: 30) {
                        Text(redeemable.name).font(.title)
                            .foregroundColor(.white)
                        HStack(spacing:10){
                            if (redeemable.availableAtFormatted != "") {
                                Text("OFFER VALID").foregroundColor(Color(red:243/255, green:192/255, blue:66/255))
                                    .font(.fine)
                                Text(redeemable.availableAtFormatted)
                                    .foregroundColor(.white)
                                    .font(.fine)
                                Text("-")
                                    .foregroundColor(.white)
                                    .font(.fine)
                            }else if (redeemable.expiresAtFormatted != ""){
                                Text("OFFER VALID UNTIL").foregroundColor(Color(red:243/255, green:192/255, blue:66/255))
                                    .font(.fine)
                            }
                            Text(redeemable.expiresAtFormatted)
                                .foregroundColor(.white)
                                .font(.fine)
                        }
                        
                        VStack(alignment: .leading, spacing: 20){
                            Text(redeemable.description.html2Attributed(font:.description))
                                .lineLimit(3)
                                .padding(.bottom,20)
                            Button(action: {
                                if self.isRedeeming {
                                    print("already isRedeeming")
                                    return
                                }
                                if !self.isRedeemed {
                                    self.isRedeeming = true

                                    Task{
                                        if redeemable.redeemAnimationLink != nil {
                                            do{
                                                print("Found animation")
                                                let playerItem = try await MakePlayerItemFromLink(fabric: fabric, link: redeemable.redeemAnimationLink)
                                                await MainActor.run {
                                                    self.playerItem = playerItem
                                                    showPlayer = true
                                                }
                                            }catch{
                                                print("Error creating playerItem for redeem animation: ", error)
                                            }
                                        }
                                        
                                        var status = RedeemStatus()
                                        var redeemed = false
                                        var transactionId = ""
                                        var transactionHash = ""
                                        do {
                                            print("Redeeming... \(redeemable.id ?? "<no-id>") offerId \(redeemable.offerId)")
                                            
                                            // we want to refresh here
                                            self.isRedeeming = true
                                            
                                            let result = try await fabric.redeemOffer(offerId: redeemable.offerId, nft: redeemable.nft)
                                            redeemed = result.isRedeemed
                                            transactionId = result.transactionId
                                            transactionHash = result.transactionHash
                                            
                                            print("Redeem result", result)
                                        } catch {
                                            print("Failed to redeemOffer", error)
                                        }

                                        await MainActor.run {
                                            print("MainActor.run isRedeeming=\(isRedeeming)")
                                            if self.isRedeeming {
                                                self.isRedeeming = false
                                            }
                                            self.redeemable.status.isRedeemed = redeemed
                                            self.redeemable.status.transactionId = transactionId
                                            self.redeemable.status.transactionHash = transactionHash
                                            self.showResult = true
                                            Task{
                                                await fabric.refresh()
                                                debugPrint ("OfferView refresh")
                                            }
                                        }
                                    }
                                    
                                } else {
                                    self.showResult = true
                                }
                            }) {
                                Text(self.isRedeeming ? "Redeeming..." : (isRedeemed ? "View" : "Redeem Now"))
                            }
                            .disabled(self.isRedeeming)
                        }
                    }
                    Spacer()
                }
                .padding(50)
            }
            .ignoresSafeArea()
            .frame( maxWidth: .infinity, maxHeight:.infinity)
            .background(Color.black.opacity(0.8))
        }
        .background(.thinMaterial)
        .onChange(of:isRedeeming) { value in
            print("onChange of:isRedeeming")
            if isRedeeming == true {
                if !self.isRedeemed {
                   
                    Task{
                        if redeemable.redeemAnimationLink != nil {
                            do{
                                print("Found animation")
                                let playerItem = try await MakePlayerItemFromLink(fabric: fabric, link: redeemable.redeemAnimationLink)
                                await MainActor.run {
                                    self.playerItem = playerItem
                                    showPlayer = true
                                }
                            }catch{
                                print("Error creating playerItem for redeem animation: ", error)
                            }
                        }else{
                            self.showResult = true
                        }
                        /*
                        print("Redeeming...", redeemable.offerId)
                        var redeemed = false
                        var transactionId: String? = nil
                        do {
                            let offerId = redeemable.offerId
                            print("Redeeming... offer Id ", offerId)
                            let redeemResult = try await fabric.redeemOffer(offerId: offerId, nft: redeemable.nft)
                            if (!redeemResult.isEmpty) {
                                redeemed = true
                                print ("REDEEMED!", redeemResult)
                            }
                        }catch {
                            print("Failed to redeemOffer", error)
                        }
                        
                        self.isRedeeming = false
                        if (redeemed) {
                            do {
                                self.redeemable.status = try await self.redeemable.checkOfferStatus(fabric: fabric)
                                self.showResult = true
                            }catch{
                                print("Error checking status")
                                self.showResult = false
                            }
                        }
                         */
                    }
                }
            }
        }
        .onChange(of:showPlayer) { value in
            if showPlayer == false {
                self.showResult = true
            }
        }
        .onChange(of:playerFinished) { value in
            if playerFinished {
                print("FINISHED IN OFFERVIEW")
                self.showPlayer = false
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView(playerItem:$playerItem, finished:$playerFinished)
        }
        .fullScreenCover(isPresented: $showResult) {
            OfferResultView(redeemable: redeemable, isRedeeming:$isRedeeming)
        }
        
    }
}


struct OfferResultView: View {
    @EnvironmentObject var fabric: Fabric
    @StateObject var redeemable: RedeemableViewModel
    
    @State var url: String = ""
    @State var title: String = ""
    @State var error: Bool = true
    @State var description: String = ""
    @State var code: String = ""
    @Binding var isRedeeming: Bool
    @FocusState var appleWalletFocused
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        if isRedeeming {
            VStack(alignment: .center, spacing:50){
                Spacer()
                Text("Redeeming In Progress. Please Wait...").font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                ProgressView()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.8))
            .background(.thinMaterial)
            .onAppear(){
                print("isRedeeming: showing Redeeming In Progress. Pleaes Wait...")
            }
        }else{
            VStack(alignment: .center, spacing:20){
                Text(title).font(.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width:1000)
                if description != "" {
                    Text(description).font(.description)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width:1000)
                    if (!error && code != ""){
                        Text(code)
                            .font(.custom("Helvetica Neue", size: 50))
                            .fontWeight(.semibold)
                    }
                }
                
                if (!error){
                    Image(uiImage: GenerateQRCode(from: url))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 400)
                }
                Spacer()
                    .frame(height: 10.0)
                HStack(alignment: .center){
                    /*
                    if (!error){
                        Button(action:{
                            print("Add to Apple Wallet Pressed")
                        }){
                            Image("add_to_apple_wallet")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                        }
                        .padding()
                        .buttonStyle(IconButtonStyle(focused:appleWalletFocused))
                        .focused($appleWalletFocused)
                    }
                     */
                    
                    Button(action:{
                        presentationMode.wrappedValue.dismiss()
                    }){
                        Text("Back")
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.8))
            .background(.thinMaterial)
            .onAppear(){
                print("OfferResultView OnAppear URL \(url) redeemable \(redeemable.status)")
                if let fulfillment = redeemable.status.fulfillment {
                    setFulfillment(fulfillment: fulfillment)
                } else {
                    title = "Loading..."
                    Task{
                        do {
                            var fulfillment: JSON? = nil
                            let transactionHash = self.redeemable.status.transactionHash
                            if (transactionHash != ""){
                                fulfillment = try await fabric.redeemFulfillment(transactionHash:transactionHash)
                                setFulfillment(fulfillment: fulfillment)
                            }else{
                                print("TransactionHash is empty for offer ", self.redeemable)
                                setError(cause: "no transactionHash")
                            }
                        }catch{
                            setError(cause: "caught in getting fullfillment")
                        }
                    }
                }
            }
        }
    }
    
    @MainActor
    func setFulfillment(fulfillment: JSON?){
        if let fulfill = fulfillment {
            print("setFulfillment got json:", fulfill)
            title = "Success"
            code = fulfill["fulfillment_data"]["code"].stringValue
            url = fulfill["fulfillment_data"]["url"].stringValue
            if (code != "" && url != ""){
                description = "Scan the QR Code with your camera app or a QR code reader on your device to claim your reward."
                error = false
                return
            }
            
            // for dry_run
            if fulfill["err"]["request"]["transaction"].stringValue.contains("tx-test-") {
                code = "dry-run complete"
                url = "https://eluv.io/"
                description = "Scan the QR Code with your camera app or a QR code reader on your device to claim your reward."
                error = false
                return
            }
            
            // for no more codes
            if fulfill["err"]["op"].stringValue == "no more redemption codes available" {
                code = ""
                description = "No more redemption codes available.  Please contact your merchant."
                return
            }
            setError(cause: "setFullfillment completed with no code or url" + fulfill.stringValue)
        } else {
            setError(cause: "setFullfillment completed with no fulfillment data")
        }
    }
    
    @MainActor
    func setError(cause: String) {
        print("calling setError from", cause)
        title = "Error"
        description = "Sorry...something went wrong. Please try again."
        self.error = true
    }
}
