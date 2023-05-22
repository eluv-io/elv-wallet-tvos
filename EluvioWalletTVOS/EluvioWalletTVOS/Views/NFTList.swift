//
//  NFTList.swift
//  NFTList
//
//  Created by Wayne Tran on 2021-09-27.
//

import SwiftUI
import QGrid

/*
struct NFTList: View {

    var title: String
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
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(title).font(.subheadline)
                }
                Spacer()
            }
            .padding(.bottom, 20)
            ScrollView (.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(nfts) { nft in
                        NFTView(nft: nft)
                            .frame(width:400, height: 400)
                    }
                }
            }
            .introspectScrollView { view in
                view.clipsToBounds = false
            }
        }
        .focusSection()
    }
}
*/

struct NFTGrid: View {

    var title: String = ""
    var nfts : [NFTModel]
    @State private var editMode = EditMode.inactive
    let columns = [
        GridItem(.fixed(520),spacing: 0),GridItem(.fixed(520),spacing: 0),
        GridItem(.fixed(520),spacing: 0)
    ]
    
    let column = [GridItem(.flexible())]

    @State var search = false
    @State var searchText = ""
    @State var gridOption = false
    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing:0) {
            ForEach(nfts) { nft in
                    NFTView(nft: nft)
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
                        NFTView(nft: nft)
                        .frame(width:500, height: 500)
                        .padding()
                }
            }
            .padding(50)
        }
    }
}

struct NFTList_Previews: PreviewProvider {
    static var previews: some View {
        NFTList(title:"Wallet", nfts: CreateTestNFTs(num: 10))
    }
}
