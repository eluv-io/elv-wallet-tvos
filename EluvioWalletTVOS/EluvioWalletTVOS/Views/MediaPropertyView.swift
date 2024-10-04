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
                                debugPrint("propertyID clicked: ", propertyId)
                                //debugPrint("property: ", property)
                                
                                await MainActor.run {
                                    eluvio.pathState.property = property
                                }

                                var skipLogin = false
                                
                                if let currentAccount = eluvio.accountManager.currentAccount {
                                    if currentAccount.type == .DEBUG {
                                        skipLogin = true
                                        eluvio.fabric.fabricToken = currentAccount.fabricToken
                                    }
                                }
                                    
                                
                                if !skipLogin {
                                    if let login = property.login {
                                        //debugPrint("property: ", login)
                                        
                                        let provider = login["settings"]["provider"].stringValue
                                        if !provider.isEmpty {
                                            if provider == "auth0" {
                                                debugPrint("Auth0 login.")
                                                if eluvio.accountManager.currentAccount?.type != .Auth0 {
                                                    eluvio.pathState.path.append(.login(LoginParam(type:.auth0, property:property)))
                                                    return
                                                }
                                            }else if provider == "ory" {
                                                debugPrint("Ory login.")
                                                if eluvio.accountManager.currentAccount?.type != .Ory {                                                        eluvio.pathState.path.append(.login(LoginParam(type:.ory, property:property)))
                                                    return
                                                }
                                            }else {
                                                debugPrint("Other login type not supported yet.")
                                                eluvio.pathState.path.append(.errorView("Login type not supported."))
                                                return
                                            }
                                        }
                                    }
                                }
                                
                                await MainActor.run {
                                    eluvio.pathState.propertyPage = property.main_page
                                }

                                await MainActor.run {
                                    let param = PropertyParam(property:property)
                                    eluvio.pathState.path.append(.property(param))
                                }

                            }else{
                                //eluvio.pathState.path.append(.errorView("Error finding property."))
                            }
                        }
                    }catch{
                        debugPrint("Error finding property ", error.localizedDescription)
                    }
                }
            }){
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
        VStack(alignment:.leading, spacing:20) {
                ForEach(propertiesGroups, id: \.self) {groups in
                    HStack(alignment:.center, spacing:20) {
                        ForEach(groups, id: \.self) { property in
                            MediaPropertyView(property: property, selected: $selected)
                                    .environmentObject(self.eluvio)
                        }
                        
                    }
                    .frame(maxWidth:.infinity, alignment:.leading)
                }
        }
        .frame(maxWidth:.infinity, maxHeight: .infinity)
        .onChange(of: properties) { old, new in
            if properties.count > 0 {
                selected = properties[0]
            }
        }
    }
}


