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
    var property : JSON
    var nfts : [NFTModel] = []
    
    var body: some View {
        ScrollView{
            NFTList(title: property["contents"][0]["title"].stringValue, nfts:nfts)
        }
        .introspectScrollView { view in
            view.clipsToBounds = false
        }
    }
}


struct MyItemsView_Previews: PreviewProvider {
    static var previews: some View {
        MyItemsView(property: CreateTestProperty(num: 2))
    }
}
