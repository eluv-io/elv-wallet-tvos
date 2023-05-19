//
//  PropertiesPage.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-17.
//

import SwiftUI

struct PropertyView : View {
    @State var property: PropertyModel
    @FocusState private var focused : Bool
    var body: some View {
        VStack(spacing:40) {
            Button {
            } label: {
                Image(property.image ?? "")
                    .resizable()
                    .frame(width:300,height:300)
                    .cornerRadius(10)
            }
            .buttonStyle(TitleButtonStyle(focused: focused))
            .focused($focused)
            
            Text(property.title ?? "")
                .foregroundColor(Color.white)
                .font(.subheadline)
            
        }
    }
}

struct PropertiesView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State private var properties: [PropertyModel] = []
    
    private var threeColumnGrid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(alignment:.leading) {
            ScrollView() {
                LazyVGrid(columns: threeColumnGrid) {
                    ForEach(properties) { property in
                        PropertyView(property: property)
                    }
                }
            }
            .introspectScrollView { view in
                view.clipsToBounds = false
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 60)
        .onAppear(){
            //XXX: Demo only
            properties = [
                CreateTestPropertyModel(title:"All Media", image:"e_logo", parentId:"iten_eluvio", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Movieverse", image:"WarnerBrothersLogo", parentId:"iten_warner", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Dollyverse", image:"DollyverseLogo", parentId:"iten_dolly", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Moonsault", image:"MoonSaultLogo", parentId:"iten_moon", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Fox Sports", image:"FoxSportsLogo", parentId:"iten_fox", nfts:fabric.playable)
            ]
        }
    }
}

struct PropertiesView_Previews: PreviewProvider {
    static var previews: some View {
        PropertiesView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
