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
                MediaCard(image:property.image ?? "", isFocused:focused, title:property.title ?? "")
            }
            .buttonStyle(TitleButtonStyle(focused: focused))
            .focused($focused)
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
                CreateTestPropertyModel(title:"Movieverse", image:"wbmovieverse", parentId:"iten_warner", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Dollyverse", image:"dollyverse", parentId:"iten_dolly", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Moonsault", image:"moonsault", parentId:"iten_moon", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Fox Sports", image:"fox", parentId:"iten_fox", nfts:fabric.playable)
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
