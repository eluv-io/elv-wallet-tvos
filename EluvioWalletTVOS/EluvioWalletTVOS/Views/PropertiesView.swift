//
//  PropertiesPage.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-17.
//

import SwiftUI

struct PropertyView : View {
    @Environment(\.colorScheme) var colorScheme
    var property: PropertyModel
    @FocusState private var focused : Bool
    
    var items : [NFTModel] {

        if property.contents.isEmpty || property.contents.count > 1{
            return []
        }
        //print("Property contents \(property)")
        return property.contents[0].contents
    }
    
    var drops : [ProjectModel] {
        
        //XXX: Demo only. If we have multiple projects, we want to display it. Otherwise default project has nothing
        if property.contents.count > 1 {
            return property.contents
        }
        
        return []
    }
    
    var body: some View {
        VStack(spacing:40) {
            NavigationLink(destination:MyMediaView(featured: property.featured,
                                                   library: property.media,
                                                   albums: property.albums,
                                                   items: items,
                                                   drops: drops,
                                                   liveStreams: property.live_streams,
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
    var properties: [PropertyModel] = []
    
    let columns = [
        GridItem(.flexible()),GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment:.leading) {
            ScrollView() {
                LazyVGrid(columns: columns, alignment: .leading, spacing:40) {
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
