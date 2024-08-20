//
//  NFTList.swift
//  NFTList
//
//  Created by Wayne Tran on 2021-09-27.
//

import SwiftUI
import QGrid

struct NFTGrid: View {

    var title: String = ""
    var nfts : [NFTModel]
    var drops : [ProjectModel] = []
    
    @State private var editMode = EditMode.inactive
    let columns = [
        GridItem(.fixed(420),spacing: 0),
        GridItem(.fixed(420),spacing: 0),
        GridItem(.fixed(420),spacing: 0),
        GridItem(.fixed(420),spacing: 0)
    ]
    
    let column = [GridItem(.flexible())]

    @State var search = false
    @State var searchText = ""
    @State var gridOption = false
    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing:0) {
            ForEach(nfts) { nft in
                /*
                    NFTView<NFTDetail>(
                        image: nft.meta.image ?? "",
                        title: nft.meta.displayName ?? "",
                        subtitle: nft.meta.editionName ?? "",
                        propertyLogo: nft.property?.logo ?? "",
                        propertyName: nft.property?.title ?? "",
                        tokenId: "#" + (nft.token_id_str ?? ""),
                        destination: NFTDetail(nft: nft)
                    )
                    .padding(.bottom,70)
                    .disabled(true)
                 */
                
                NFTView2(
                    nft:nft,
                    scale: 0.75
                )
                .padding(.bottom,70)
            }
            
            ForEach(drops) { drop in
                NFTView<DropDetail>(
                    image: drop.image ?? "",
                    title: drop.title ?? "",
                    propertyLogo: drop.property?.logo ?? "",
                    propertyName: drop.property?.title ?? "",
                    destination: DropDetail(drop:drop)
                )
                .padding(.bottom,70)
            }
        }
    }
}


struct NFTList: View {

    var title: String = ""
    var nfts : [NFTModel]
    @State private var editMode = EditMode.inactive
    let columns = [
        GridItem(.flexible()),GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let column = [GridItem(.flexible())]

    @State var search = false
    @State var searchText = ""
    @State var gridOption = false
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(.title3).bold()
            }

            Spacer()
        }.padding(.horizontal)
        ScrollView (.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(nfts) { nft in
                        NFTView<NFTDetail>(
                            image: nft.meta.image ?? "",
                            title: nft.meta.displayName ?? "",
                            subtitle: nft.meta.editionName ?? "",
                            propertyLogo: nft.property?.logo ?? "",
                            propertyName: nft.property?.title ?? "",
                            tokenId: "#" + (nft.token_id_str ?? ""),
                            destination: NFTDetail(nft: nft)
                        )
                        .frame(width:500, height: 500)
                        .padding()
                    }
                }
            }
            .padding(50)
    }
}

struct NFTList_Previews: PreviewProvider {
    static var previews: some View {
        NFTList(title:"Wallet", nfts: CreateTestNFTs(num: 10))
    }
}
