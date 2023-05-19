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
    
    var body: some View {
        VStack(alignment:.leading) {
            HStack{
                Image(systemName: "magnifyingglass").resizable().frame(width:40,height:40)
                TextField("Search...", text: $searchString)
                    .frame(alignment: .leading)
            }
            Divider().overlay(Color.gray).padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight:.infinity, alignment: .leading)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
