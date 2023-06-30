//
//  OfferView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-06-22.
//

import SwiftUI
import SDWebImageSwiftUI
import AVFoundation

struct OfferView: View {
    @EnvironmentObject var fabric: Fabric
    @State var redeemable: RedeemableViewModel
    @State private var playerItem: AVPlayerItem? = nil
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.square
    @State var imageUrl: String = ""
    @State var showPlayer: Bool = false
    @State var showResult: Bool = false
    @State var url: String = ""
    @State var playerFinished: Bool = false
    @State var isRedeeming: Bool = false
    
    private var isRedeemed : Bool {
        return redeemable.status.isRedeemed
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
                    }else {
                        WebImage(url:URL(string:redeemable.imageUrl))
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFit()
                            .frame(width:400)
                    }
                    VStack(alignment: .leading, spacing: 30) {
                        Text(redeemable.name).font(.title)
                            .foregroundColor(.white)
                        HStack(spacing:10){
                            Text("OFFER VALID").foregroundColor(Color(red:243/255, green:192/255, blue:66/255))
                                .font(.fine)
                            Text(redeemable.availableAtFormatted)
                                .foregroundColor(.white)
                                .font(.fine)
                            Text("-")
                                .foregroundColor(.white)
                                .font(.fine)
                            Text(redeemable.expiresAtFormatted)
                                .foregroundColor(.white)
                                .font(.fine)
                        }
                        
                        VStack(alignment: .leading, spacing: 20){
                            Text(redeemable.description.html2Attributed(font:.description))
                                .lineLimit(3)
                                .padding(.bottom,20)
                            Button(action: {
                                if (self.isRedeeming ){
                                    return
                                }
                                if !self.isRedeemed {
                                    self.isRedeeming = true
                                    /*
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
                                        
                                        //var isRedeemed = false
                                        print("Redeeming...", redeemable.id)
                                        var redeemed = false
                                        do {
                                            if let offerId = redeemable.id {
                                                print("Redeeming... offer Id ", offerId)
                                                let result = try await fabric.redeemOffer(offerId: offerId, nft: redeemable.nft)
                                                
                                                print("Redeem result", result)
                                                for _ in 0...1 {
                                                    try await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
                                                    /*if(try await fabric.isRedeemed(offerId: offerId, nft: redeemable.nft)){
                                                        isRedeemed = true
                                                        break;
                                                    }*/
                                                }
                                                
                                                //DEMO ONLY
                                                redeemed = true
                                            }
                                        }catch {
                                            print("Failed to redeemOffer", error)
                                        }
                                        await MainActor.run {
                                            self.isRedeeming = false
                                            self.redeemable.status.isRedeemed = redeemed
                                            self.showResult = true
                                        }
                                    }*/
                                    
                                }
                                else{
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
                        
                        //var isRedeemed = false
                        print("Redeeming...", redeemable.id)
                        var redeemed = false
                        do {
                            if let offerId = redeemable.id {
                                print("Redeeming... offer Id ", offerId)
                                let result = try await fabric.redeemOffer(offerId: offerId, nft: redeemable.nft)
                                
                                print("Redeem result", result)
                                for _ in 0...1 {
                                    try await Task.sleep(nanoseconds: UInt64(2 * Double(NSEC_PER_SEC)))
                                    /*if(try await fabric.isRedeemed(offerId: offerId, nft: redeemable.nft)){
                                     isRedeemed = true
                                     break;
                                     }*/
                                }
                                
                                //DEMO ONLY
                                redeemed = true
                            }
                        }catch {
                            print("Failed to redeemOffer", error)
                        }
                        await MainActor.run {
                            self.isRedeeming = false
                            self.redeemable.status.isRedeemed = redeemed
                            self.showResult = true
                        }
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
            OfferResultView(url:$url, title: "Success", description: "Present this QR code on your next visit.", isRedeeming:$isRedeeming)
        }
        
    }
}


struct OfferResultView: View {
    @EnvironmentObject var fabric: Fabric
    @Binding var url: String
    @State var title: String = "Point your camera to the QR Code below for content"
    @State var description: String = ""
    @Binding var isRedeeming: Bool
    @FocusState var appleWalletFocused
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        if isRedeeming {
            VStack(alignment: .center, spacing:50){
                Spacer()
                Text("Redeeming In Progress...").font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                ProgressView()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.8))
            .background(.thinMaterial)
        }else{
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
                
                HStack(alignment: .center){
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
                print("Experience URL \(url)")
            }
        }
    }
}
