//
//  MyItemsView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-15.
//

import SwiftUI
import SwiftyJSON
import Introspect

struct MyItemsView: View {
    //
    @State var searchText = ""
    var nfts : [NFTModel] = []
    var drops : [ProjectModel] = []
    var logo = "e_logo"
    var logoUrl = ""
    var name = ""
    
    var body: some View {
        ScrollView{
            VStack{
                HeaderView(logo:logo, logoUrl: logoUrl)
                    .padding(.top,50)
                    .padding(.leading,80)
                    .padding(.bottom,80)
                NFTGrid(nfts:nfts, drops:drops)
            }
        }
        .onAppear(){
            print("DROPS: ", drops)
        }
        .ignoresSafeArea()
        .introspectScrollView { view in
            view.clipsToBounds = false
        }
    }
}


struct MyItemsView_Previews: PreviewProvider {
    static var previews: some View {
        MyItemsView(nfts: CreateTestNFTs(num: 2))
    }
}
