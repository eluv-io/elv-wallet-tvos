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
            TextField("Search...", text: $searchString)
                .frame(width:600, alignment: .leading)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
