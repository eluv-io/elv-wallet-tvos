//
//  PackView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-12-14.
//
/*
import SwiftUI
import SDWebImageSwiftUI
import AVFoundation
import SwiftyJSON

struct PackView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @Environment(\.presentationMode) var presentationMode
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.square
    @State var isRedeeming: Bool = false
    
    @State var result : (isComplete:Bool, status:String, transactionId:String, contractAddress:String, tokenId:String)?
    
    @State var isRedeemed = false
    @State var showNft = false
    @State var nft = NFTModel()
    @State var mintedNft : NFTModel?
    
    var backLink: String = ""
    var backLinkIcon: String = ""
    @State var isError = false
    
    private var hasImage :  Bool {
        true
    }
    
    private var imageUrl : String {
        if isRedeemed {
            return mintedNft?.meta.image ?? ""
        }else {
            return nft.meta.image ?? ""
        }
    }
    
    private var name : String {
        if isRedeemed {
            return mintedNft?.meta.displayName ?? ""
        }else {
            return nft.meta.displayName ?? ""
        }
    }
    
    private var edition : String {
        if isRedeemed {
            return mintedNft?.meta.editionName ?? ""
        }else {
            return nft.meta.editionName ?? ""
        }
    }
    
    private var tokenId : String {
        if isRedeemed {
            return mintedNft?.token_id_str ?? ""
        }else {
            return nft.token_id_str ?? ""
        }
    }
    
    private var description : String {
        var _nft = nft
        if(isRedeemed && mintedNft != nil){
            if let minted = mintedNft {
                _nft = minted
            }
        }
        
        if let desc = _nft.meta_full?["short_description"].stringValue {
            if (desc != ""){
                return desc
            }
        }
        
        if let desc = _nft.meta.description {
            if (desc != ""){
                return desc
            }
        }
        
        return ""
    }
    
    var body: some View {
        if showNft && self.mintedNft != nil{
            NFTDetail(nft: self.mintedNft!, backLink: backLink, backLinkIcon: backLinkIcon)
        }else {
            ZStack(alignment:.top){
                VStack(alignment:.leading){
                    HStack(alignment:.center, spacing:100){
                        if hasImage{
                            NFTView<NFTDetail>(image: imageUrl, title: name, subtitle: edition, tokenId: tokenId, destination: NFTDetail(nft: NFTModel()))
                                .disabled(true)
                        }
                        VStack(alignment: hasImage ? .leading : .center, spacing: 20) {
                            Text(name).font(.title2)
                                .foregroundColor(.white)
                                .padding(.bottom,25)
                        
                            
                            Text(description)
                                .font(.system(size: 35, weight:.light))
                                .lineLimit(5)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.bottom,25)
                            
                            Text("Open this item to reveal its contents into your wallet.")
                                .font(.system(size: 35))
                                .lineLimit(8)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.bottom,10)
                        
                            
                            HStack {
                                Button(action: {
                                    if self.isRedeemed{
                                        debugPrint("Button pressed isRedeemed", isRedeemed)
                                        if self.mintedNft == nil {
                                            if let result = self.result {
                                                Task {
                                                    debugPrint("Refreshing")
                                                    await eluvio.fabric.refresh()
                                                    
                                                    debugPrint("Getting nft")
                                                    if let _nft = eluvio.fabric.getNFT(contract: result.contractAddress,
                                                                                token:result.tokenId) {
                                                        await MainActor.run {
                                                            debugPrint("Showing NFT")
                                                            self.mintedNft = _nft
                                                            self.showNft = true
                                                            return
                                                        }
                                                    }else{
                                                        await MainActor.run {
                                                            self.isError = true
                                                        }
                                                    }
                                                }
                                            }else{
                                                debugPrint("No result but isRedeemed == true")
                                                self.isError = true
                                            }
                                        }else {
                                            debugPrint("Showing NFT")
                                            self.showNft = true
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
                                            let result = try await eluvio.fabric.packOpen(nft: self.nft)
                                            debugPrint("PackOpen result", result)
                                            
                                            if result.contractAddress != "" {
                                                await eluvio.fabric.refresh()
                                                
                                                await MainActor.run {
                                                    self.result = result
                                                    self.isRedeemed = true
                                                    self.isRedeeming = false
                                                    
                                                    if  (result.contractAddress == "" || result.tokenId == ""){
                                                        self.isError = true
                                                    }else{
                                                        if let _nft = eluvio.fabric.getNFT(contract: result.contractAddress,
                                                                                    token:tokenId) {
                                                            self.mintedNft = _nft
                                                        }else{
                                                            self.isError = true
                                                        }
                                                    }
                                                }
                                            }else{
                                                self.isError = true
                                            }
                                        } catch {
                                            print("Failed to redeemOffer", error)
                                            self.isError = true
                                        }
                                    }
                                    
                                }) {
                                    if (isRedeemed){
                                        Text("View")
                                            .frame(minWidth:200)
                                    } else if (isRedeeming) {
                                        HStack(spacing:10){
                                            ProgressView()
                                            Text("Opening...")
                                        }
                                        .frame(minWidth:200)
                                    }else{
                                        Text("Open")
                                            .frame(minWidth:200)
                                    }
                                }
                                .padding(.leading, (isRedeeming ? 0 : 20 ))
                                .disabled(isRedeeming)
                                
                                if (isError){
                                    Text("Sorry something went wrong. Please try again")
                                        .font(.subheadline)
                                        .foregroundColor(.red.opacity(0.6))
                                } else if (isRedeeming) {
                                    Text("This may take up to one minute.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                                
                            }
                            
                        }
                        Spacer()
                    }
                    .padding(200)
                }
                .ignoresSafeArea()
                .frame( maxWidth: .infinity, maxHeight:.infinity)
                .background(Color.black.opacity(0.8))
            }
            .background(.thinMaterial)
        }
    }
}
*/
