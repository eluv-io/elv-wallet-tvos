//
//  MediaPropertyView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.
//

import SwiftUI
import SDWebImageSwiftUI
import Foundation

struct MediaPropertyView : View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio : EluvioAPI
    var property: MediaPropertyViewModel
    @FocusState private var focused : Bool
    @Binding var selected : MediaPropertyViewModel
    static var factor = 1.0
    var width : CGFloat = 330 * factor
    var height : CGFloat = 470 * factor

    var body: some View {
        VStack(spacing:10) {
            Button(action: {
                Task {
                    do {
                        if let propertyId = property.id {
                            if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                debugPrint("Found Sub property", property)
                                
                                await MainActor.run {
                                    eluvio.pathState.property = property
                                }
                                
                                if eluvio.fabric.isLoggedOut {
                                    debugPrint("Property clicked, is logged out. Go to alternate page.")
                                    if let login = property.login {
                                        debugPrint("Login: ", login)
                                        
                                        let provider = login["settings"]["provider"].stringValue
                                        if !provider.isEmpty {
                                            if provider == "auth0" {
                                                debugPrint("Auth0 login.")
                                                /*await MainActor.run {
                                                    eluvio.pathState.path.append(.html)
                                                }*/
                                                eluvio.pathState.path.append(.login(LoginParam(type:.auth0)))
                                            }else if provider == "ory" {
                                                debugPrint("Ory login.")
                                                eluvio.pathState.path.append(.login(LoginParam(type:.ory)))
                                            }else {
                                                debugPrint("Other login type not supported yet.")
                                                eluvio.pathState.path.append(.errorView("Login type not supported."))
                                            }
                                        }
                                    }
                                }else {
                                    if let pageId = property.main_page?.id{
                                        if let page = try await eluvio.fabric.getPropertyPage(property: propertyId, page: pageId) {
                                            await MainActor.run {
                                                eluvio.pathState.propertyPage = page
                                            }
                                        }
                                    }
                                    
                                    await MainActor.run {
                                        eluvio.pathState.path.append(.property)
                                    }
                                }
                                
                                
                            }
                        }
                    }catch{
                        debugPrint("Error finding property ", error.localizedDescription)
                    }
                }
            }){
                //NavigationLink(destination:MediaPropertyDetailView(property:property)
                //    .environmentObject(self.pathState)
                //    .preferredColorScheme(colorScheme)) {
                if property.image != "" {
                    WebImage(url: URL(string: property.image))
                        .resizable()
                        .indicator(.activity) // Activity Indicator
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .cornerRadius(3)
                }else{
                    ZStack{
                        if property.backgroundImage != "" {
                            WebImage(url: URL(string: property.backgroundImage))
                                .resizable()
                                .indicator(.activity) // Activity Indicator
                                .transition(.fade(duration: 0.5))
                                .aspectRatio(contentMode: .fill)
                                .frame(width: width, height: height)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(Color.black)
                                .opacity(focused ? 0.7 : 0.5)
                                .frame(width: width, height: height)
                                .cornerRadius(3)
                        }else{
                            Rectangle()
                                .fill(Color.secondaryBackground)
                                .frame(width: width, height: height)
                                .cornerRadius(3)
                        }
                        if property.title.isEmpty {
                            //Text("Untitled").font(.largeTitle)
                        }else{
                            Text(property.title).font(.largeTitle.bold())
                        }
                    }
                }
            }
            .buttonStyle(TitleButtonStyle(focused: focused, bordered : true))
            .focused($focused)
        }
        .onChange(of:selected) {old, new in
            //debugPrint("on selected", new.title)
            if (new.id == property.id){
                //debugPrint("Setting focus", property.title)
               // focused = true
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
    @EnvironmentObject var eluvio: EluvioAPI
    
    var numColumns = 5
    var properties: [MediaPropertyViewModel] = []
    var propertiesGroups : [[MediaPropertyViewModel]] {
        return properties.dividedIntoGroups(of: numColumns)
    }
    
    @Binding var selected : MediaPropertyViewModel

    var body: some View {
        VStack(alignment:.leading) {
            Grid(alignment:.center, horizontalSpacing: 10, verticalSpacing: 20) {
                ForEach(propertiesGroups, id: \.self) {groups in
                    GridRow(alignment:.center) {
                        ForEach(groups, id: \.self) { property in
                                MediaPropertyView(property: property, selected: $selected)
                                    .environmentObject(self.eluvio)
                        }
                    }
                    .frame(maxWidth:.infinity)
                }
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
        }
        .frame(maxWidth:.infinity, maxHeight: .infinity)
        .onChange(of: properties) { old, new in
            if properties.count > 0 {
                selected = properties[0]
            }
        }
    }
}


