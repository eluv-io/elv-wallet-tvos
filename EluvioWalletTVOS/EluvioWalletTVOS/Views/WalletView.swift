//
//  WalletView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-30.
//

import SwiftUI

struct WalletView: View {
    var nfts : [NFTModel]
    @State var searchText = ""
    
    var body: some View {
        ZStack() {
            ScrollView {
                Spacer(minLength:20)
                NFTList(title: "", nfts:nfts)
            }
        }
    }
}


struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView(nfts: CreateTestNFTs(num: 10))
    }
}
