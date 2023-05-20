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
    var logo = "e_logo"
    var logoUrl = ""
    var name = "Eluvio Wallet"
    
    var body: some View {
        ScrollView{
            VStack{
                HeaderView(logo:logo, logoUrl: logoUrl, name:name)
                NFTGrid(nfts:nfts)
            }
        }
        .introspectScrollView { view in
            view.clipsToBounds = false
        }
    }
}


struct MyItemsView_Previews: PreviewProvider {
    static var previews: some View {
        MyItemsView()
    }
}
