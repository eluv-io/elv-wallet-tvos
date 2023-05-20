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
                MediaCard(display: MediaDisplay.property, image:property.image ?? "", isFocused:focused, title:property.title ?? "")
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
    
    let columns = [
        GridItem(.flexible()),GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment:.leading) {
            ScrollView() {
                LazyVGrid(columns: columns, alignment: .leading, spacing:0) {
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
                CreateTestPropertyModel(title:"Movieverse", image:"WarnerBrothers_TopImage", parentId:"iten_warner", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Dollyverse", image:"DollyVerse_TopImage", parentId:"iten_dolly", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Moonsault", image:"WWEMoonSault_TopImage", parentId:"iten_moon", nfts:fabric.playable),
                CreateTestPropertyModel(title:"Fox Sports", image:"FoxSports_TopImage", parentId:"iten_fox", nfts:fabric.playable)
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
