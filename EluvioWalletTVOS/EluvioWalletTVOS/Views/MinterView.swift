//
//  MinterDialog.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-10-05.
//

import SwiftUI
import SDWebImageSwiftUI
import AVFoundation
import SwiftyJSON

struct MinterView: View {
    @EnvironmentObject var fabric: Fabric
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewState: ViewState
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.square
    @State var isRedeeming: Bool = false
    
    @Binding var marketItem: JSON
    @Binding var mintInfo: MintInfo
    
    @State var result :  (isRedeemed:Bool, contractAddress:String, tokenId:String)?
    
    @State var isRedeemed = false
    @State var showNft = false
    @State var nft = NFTModel()
    var backLink: String = ""
    var backLinkIcon: String = ""
    private var hasImage :  Bool {
        return marketItem["nft_template"]["nft"]["image"].stringValue != ""
    }
    
    private var imageUrl : String {
        return marketItem["nft_template"]["nft"]["image"].stringValue
    }
    
    private var name : String {
        return marketItem["nft_template"]["nft"]["display_name"].stringValue
    }
    
    private var edition : String {
        return marketItem["nft_template"]["nft"]["edition_name"].stringValue
    }
    
    private var description : String {
        return marketItem["nft_template"]["nft"]["description"].stringValue
    }
    private var contractAddress : String {
        return marketItem["nft_template"]["nft"]["address"].stringValue
    }
    
    var body: some View {
        if showNft {
            NFTDetail(nft: self.nft, backLink: backLink, backLinkIcon: backLinkIcon)
        }else {
            ZStack{
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
                                .lineLimit(3)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.bottom,40)
                            
                            if (isRedeemed){
                                Text("Congratulations! You now own this item.")
                                    .font(.subheadline)
                                    .foregroundColor(.blue.opacity(0.6))
                                    .padding(.bottom,40)
                            }
                            
                            Button(action: {
                                if self.isRedeemed{
                                    if let result = self.result {
                                        if let _nft = fabric.getNFT(contract: result.contractAddress) {
                                            self.nft = _nft
                                            self.showNft = true
                                            return
                                        }
                                    }
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
                                        debugPrint("Minting... \(self.marketItem["sku"])")
                                        let result = try await fabric.mintItem(tenantId:mintInfo.tenantId, marketplaceId: mintInfo.marketplaceId, sku:mintInfo.sku, contract: contractAddress)
                                        print("Redeem result", result)
                                        if result.contractAddress != ""{
                                            await MainActor.run {
                                                self.result = result
                                                self.isRedeemed = true
                                            }
                                            await fabric.refresh()
                                        }
                                        
                                        //
                                    } catch {
                                        print("Failed to redeemOffer", error)
                                    }
                                    
                                    await MainActor.run {
                                        debugPrint("MainActor.run isRedeeming=\(isRedeeming)")
                                        if self.isRedeeming {
                                            self.isRedeeming = false
                                        }
                                    }
                                }
                                
                            }) {
                                if (isRedeemed){
                                    Text("Enjoy")
                                } else if (isRedeeming) {
                                    HStack(spacing:10){
                                        ProgressView()
                                        Text("Activating...")
                                    }
                                }else{
                                    Text("Activate")
                                }
                            }
                            .padding(.leading, 20)
                            .disabled(isRedeeming)
                            
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
