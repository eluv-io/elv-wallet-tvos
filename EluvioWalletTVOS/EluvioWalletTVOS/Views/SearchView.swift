//
//  SearchView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-16.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var searchString : String = ""
    var logo = "e_logo"
    var logoUrl = ""
    var name = "Eluvio Wallet"
    
    var body: some View {
        ScrollView{
            VStack(alignment:.leading) {
                HeaderView(logo:logo, logoUrl: logoUrl, name:name)
                HStack{
                    Image(systemName: "magnifyingglass").resizable().frame(width:40,height:40)
                    TextField("Search...", text: $searchString)
                        .frame(alignment: .leading)
                }
                Divider().overlay(Color.gray).padding()
                PropertiesView()
                Spacer()
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
