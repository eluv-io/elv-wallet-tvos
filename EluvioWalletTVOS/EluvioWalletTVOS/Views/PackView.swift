//
//  PackView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-12-14.
//

import SwiftUI
import SDWebImageSwiftUI
import AVFoundation
import SwiftyJSON

struct PackView: View {
    @EnvironmentObject var fabric: Fabric
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewState: ViewState
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.square
    @State var isRedeeming: Bool = false
    
    @State var result : (isComplete:Bool, status:String, transactionId:String, contractAddress:String, tokenId:String)?
    
    @State var isRedeemed = false
    @State var showNft = false
    @State var nft = NFTModel()
    var backLink: String = ""
    var backLinkIcon: String = ""
    @State var isError = false
    
    private var hasImage :  Bool {
        true
    }
    
    private var imageUrl : String {
        return nft.meta.image ?? ""
    }
    
    private var name : String {
        return nft.meta.displayName ?? ""
    }
    
    private var edition : String {
        return nft.meta.editionName ?? ""
    }
    
    private var description : String {
        if let desc = nft.meta_full?["short_description"].stringValue {
            if (desc != ""){
                return desc
            }
        }
        
        if let desc = nft.meta.description {
            if (desc != ""){
                return desc
            }
        }
        
        return ""
    }
    private var contractAddress : String {
        return nft.contract_addr ?? ""
    }
    
    var body: some View {
        if showNft {
            NFTDetail(nft: self.nft, backLink: backLink, backLinkIcon: backLinkIcon)
        }else {
            ZStack(alignment:.top){
                VStack{
                    HStack(alignment:.top, spacing:100){
                        Spacer()
                        if hasImage{
                            NFTView<NFTDetail>(image: imageUrl, title: name, subtitle: edition, destination: NFTDetail(nft: NFTModel()))
                                .disabled(true)
                        }
                        VStack(alignment: hasImage ? .leading : .center, spacing: 30) {
                            VStack(alignment: .leading, spacing: 20){
                                Text(name).font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            Text(description)
                                .font(.headline)
                                .lineLimit(3)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.bottom,40)
                            
                            HStack {
                                Button(action: {
                                    if self.isRedeemed{
                                        if let result = self.result {
                                            if let _nft = fabric.getNFT(contract: result.contractAddress) {
                                                self.nft = _nft
                                                self.showNft = true
                                                return
                                            }
                                        }
                                        return
                                    }
                                    
                                    if self.isRedeeming {
                                        print("already redeeming")
                                        return
                                    }
                                    
                                    Task{
                                        await MainActor.run {
                                            self.isRedeeming = true
                                        }
                                        
                                        do {
                                            let result = try await fabric.packOpen(nft: self.nft)
                                            
                                            debugPrint("PackOpen result", result)
                                            
                                            if result.contractAddress != "" {
                                                await MainActor.run {
                                                    self.result = result
                                                    self.isRedeemed = true
                                                    self.isRedeeming = false
                                                    
                                                    if  (result.contractAddress == "" || result.tokenId == ""){
                                                        self.isError = true
                                                    }else{
                                                        if let _nft = fabric.getNFT(contract: result.contractAddress) {
                                                            self.nft = _nft
                                                        }
                                                    }
                                                }
                                            }
                                            
                                        } catch {
                                            print("Failed to redeemOffer", error)
                                        }
                                    }
                                    
                                }) {
                                    if (isRedeemed){
                                        Text("Enjoy")
                                    } else if (isRedeeming) {
                                        HStack(spacing:10){
                                            ProgressView()
                                            Text("Opening...")
                                        }
                                    }else{
                                        Text("Open")
                                    }
                                }
                                .padding(.leading, 20)
                                .disabled(isRedeeming)
                                
                                if (isError){
                                    Text("Sorry something went wrong. Please try again")
                                        .font(.subheadline)
                                        .foregroundColor(.red.opacity(0.6))
                                } else if (isRedeeming) {
                                    Text("This may take up to one minute.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray.opacity(0.6))
                                } else if (isRedeemed){
                                    Text("Congratulations! You now own this item.")
                                        .font(.subheadline)
                                        .foregroundColor(.blue.opacity(0.6))
                                }
                                
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
        }
    }
}
