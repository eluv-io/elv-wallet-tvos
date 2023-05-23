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
    var name = ""
    
    var body: some View {
        ScrollView{
            VStack(alignment:.leading) {
                HeaderView(logo:logo, logoUrl: logoUrl)
                    .padding(.top,50)
                    .padding(.leading,80)
                    .padding(.bottom,40)
                
                VStack{
                    HStack{
                        Image(systemName: "magnifyingglass").resizable().frame(width:40,height:40)
                        TextField("Search...", text: $searchString)
                            .frame(alignment: .leading)
                    }
                    Divider().overlay(Color.gray).padding()
                    PropertiesView(properties:fabric.properties)
                        .focusSection()
                    Spacer()
                }
                .padding([.leading,.trailing,.bottom],80)
            }
        }
        .ignoresSafeArea()
        .introspectScrollView { view in
            view.clipsToBounds = false
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
