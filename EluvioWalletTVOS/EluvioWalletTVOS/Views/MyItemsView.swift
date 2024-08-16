//
//  MyItemsView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-15.
//

import SwiftUI
import SwiftyJSON

struct MyItemsView: View {
    @EnvironmentObject var fabric: Fabric
    @State var searchText = ""
    var nfts : [NFTModel] = []
    var drops : [ProjectModel] = []
    var logo = "e_logo"
    var logoUrl = ""
    var name = ""
    
    var body: some View {
        ScrollView{
            VStack{
                NFTGrid(nfts:nfts, drops:drops)
                    .padding(.top,40)
            }
        }
        .scrollClipDisabled()
    }
}


struct MyItemsView_Previews: PreviewProvider {
    static var previews: some View {
        MyItemsView(nfts: CreateTestNFTs(num: 2))
    }
}
