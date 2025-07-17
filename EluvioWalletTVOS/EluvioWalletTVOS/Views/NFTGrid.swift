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
    
    private var columns: [GridItem] {
        return [
            .init(.adaptive(minimum: 260, maximum: 280))
        ]
    }
    

    @State var search = false
    @State var searchText = ""
    @State var gridOption = false
    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing:0) {
            ForEach(nfts) { nft in
                NFTView(
                    nft:nft,
                    scale: 0.5
                )
                .padding(.bottom,70)
            }
        }
    }
}

