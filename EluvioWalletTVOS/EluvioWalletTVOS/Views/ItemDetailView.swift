//
//  ItemDetailView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-15.
//

import SwiftUI


struct ItemDetailView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var pathState: PathState
    
    var item : NFTModel
    var name : String {
        item.meta.name ?? ""
    }
    
    var description : String {
        item.meta.description ?? ""
    }
    
    var edition : String {
        item.meta.editionName ?? ""
    }
    
    var tokenId : String {
        "#" + (item.token_id_str ?? "")
    }
    
    var tokenDisplay : String {
        if tokenId.isEmpty {
            return ""
        }
        
        if tokenId.hasPrefix("#") {
            return tokenId
        }
        
        return "#\(tokenId)"
    }
    
    var subtitle : String {
        return edition + " " + tokenDisplay
    }
    
    var imageUrl : String {
        item.meta.image ?? ""
    }
    
    var propertyId : String {
        item.nft_template?["bundled_property_id"].stringValue ?? ""
    }
    
    var body: some View {
            ZStack{
                VStack{
                    HStack(alignment:.top, spacing:100){
                        VStack{
                            NFTView2(nft:item)
                                .disabled(true)
                            
                            if !propertyId.isEmpty {
                                Button(action: {
                                    debugPrint("Go To Property")
                                    Task {
                                        if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                            debugPrint("Found Sub property", property)
                                            
                                            await MainActor.run {
                                                eluvio.pathState.property = property
                                            }
                                            
                                            if let pageId = property.main_page?.id{
                                                if let page = try await eluvio.fabric.getPropertyPage(property: propertyId, page: pageId) {
                                                    await MainActor.run {
                                                        eluvio.pathState.propertyPage = page
                                                    }
                                                }
                                            }
                                            
                                            await MainActor.run {
                                                eluvio.pathState.path.append(.property)
                                            }
                                        }
    
                                    }
                                }) {
                                    Text("Go To Property")
                                }
                                .padding()
                            }
                        }
                        VStack(alignment: .leading, spacing: 30) {
                            VStack(alignment: .leading, spacing: 20){
                                Text(name)
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(subtitle)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.bottom,40)
                                    .textCase(.uppercase)
                            }
                            
                            Text(description)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(.bottom,40)
                        }
                        .frame(maxWidth:800, alignment:.leading)
                    }
                    .padding(50)
                }
                .ignoresSafeArea()
                .frame( maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
            }
            .background(.thinMaterial)
        }
    }

