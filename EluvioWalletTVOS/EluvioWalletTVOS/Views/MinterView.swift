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
    @FocusState var isFocused
    var display: MediaDisplay = MediaDisplay.square
    @State var isRedeeming: Bool = false
    
    @Binding var marketItem: JSON
    
    //TODO:
    private var isRedeemed : Bool {
        return true
    }

    
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
    
    var body: some View {
        ZStack{
            VStack{
                HStack(alignment:.top, spacing:100){
                    Spacer()
                    if hasImage{
                        /*
                        WebImage(url:URL(string:imageUrl))
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFit()
                            .frame(width:400)
                         */
                        NFTView<NFTDetail>(image: imageUrl, title: name, subtitle: edition, destination: NFTDetail(nft: NFTModel()))
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
                    
                        Button(action: {
                            if self.isRedeeming {
                                print("already isRedeeming")
                                return
                            }

                            Task{
                                await MainActor.run {
                                    self.isRedeeming = true
                                }

                                do {
                                    debugPrint("Minting... \(self.marketItem["sku"])")
                                    let result = try await fabric.mintItem(itemJSON: self.marketItem)
                                    print("Redeem result", result)
                                } catch {
                                    print("Failed to redeemOffer", error)
                                }

                                await MainActor.run {
                                    debugPrint("MainActor.run isRedeeming=\(isRedeeming)")
                                    if self.isRedeeming {
                                        self.isRedeeming = false
                                    }
                                    Task{
                                        await fabric.refresh()
                                        debugPrint ("OfferView refresh")
                                    }
                                }
                            }

                        }) {
                            Text("CLAIM NOW")
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
