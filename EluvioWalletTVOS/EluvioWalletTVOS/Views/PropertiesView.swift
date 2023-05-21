//
//  PropertiesPage.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-17.
//

import SwiftUI

struct PropertyView : View {
    @Environment(\.colorScheme) var colorScheme
    @State var property: PropertyModel
    @FocusState private var focused : Bool
    var body: some View {
        VStack(spacing:40) {
            NavigationLink(destination:MyMediaView(featured: property.featured,
                                                   library: property.media,
                                                   albums: property.albums,
                                                   heroImage: property.heroImage
                                                  )
                .preferredColorScheme(colorScheme)) {
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
    @State var properties: [PropertyModel] = []
    
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
    }
}

struct PropertiesView_Previews: PreviewProvider {
    static var previews: some View {
        PropertiesView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
