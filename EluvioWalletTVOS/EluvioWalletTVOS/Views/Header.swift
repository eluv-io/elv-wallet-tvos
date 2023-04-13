//
//  Header.swift
//  Header
//
//  Created by Wayne Tran on 2021-09-29.
//

import SwiftUI

struct Header: View {
    @State var search = false
    @State var searchText = ""
    var title = ""
    
    var body: some View {
        HStack() {
                HStack{
                    Image("wallet_logo").resizable().aspectRatio(contentMode:.fit).frame(width:24)
                    Text(title).font(.title2).bold().foregroundColor(.headerForeground)

                }
            }
            .foregroundColor(.gray)
    }
        
}



struct Header_Previews: PreviewProvider {
    static var previews: some View {
        Header(title: "Wallet")
    }
}

