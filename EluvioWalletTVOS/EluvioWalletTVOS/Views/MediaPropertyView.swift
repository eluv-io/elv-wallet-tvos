//
//  MediaPropertyView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.
//

import SwiftUI
import SDWebImageSwiftUI

struct MediaPropertyView : View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var pathState : PathState
    var property: MediaPropertyViewModel
    @FocusState private var focused : Bool
    @Binding var selected : MediaPropertyViewModel

    var body: some View {
        VStack(spacing:10) {
            NavigationLink(destination:MediaPropertyDetailView(property:property)
                .environmentObject(self.pathState)
                .preferredColorScheme(colorScheme)) {
                    WebImage(url: URL(string: property.image))
                        .resizable()
                        .indicator(.activity) // Activity Indicator
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                        .frame( width: 330, height: 470)
                        .cornerRadius(3)
            }
            .buttonStyle(TitleButtonStyle(focused: focused))
            .focused($focused)
        }
        .onChange(of:selected) {old, new in
            //debugPrint("on selected", new.title)
            if (new.id == property.id){
                //debugPrint("Setting focus", property.title)
                focused = true
            }
        }
        .onChange(of:focused) {old, new in
            if (new){
                selected = property
            }
        }
    }
}

struct MediaPropertiesView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var pathState: PathState
    
    var properties: [MediaPropertyViewModel] = []
    @Binding var selected : MediaPropertyViewModel
    
    private let columns = [
        GridItem(.fixed(340), spacing: 10),
        GridItem(.fixed(340), spacing: 10),
        GridItem(.fixed(340), spacing: 10),
        GridItem(.fixed(340), spacing: 10),
        GridItem(.fixed(340), spacing: 10)
    ]
    
    var body: some View {
        VStack(alignment:.leading) {
            LazyVGrid(columns: columns, alignment: .center, spacing:20) {
                ForEach(properties) { property in
                    MediaPropertyView(property: property, selected: $selected)
                        .environmentObject(self.pathState)
                }
            }
        }
        .frame(alignment: .center)
        .onChange(of: properties) { old, new in
            if properties.count > 0 {
                selected = properties[0]
            }
        }
    }
}
