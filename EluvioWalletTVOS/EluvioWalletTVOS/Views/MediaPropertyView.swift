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
    var width : CGFloat {
        if landscape {
            return 417 * MediaPropertyView.factor
        }else {
            return 330 * MediaPropertyView.factor
        }
    }
    var height : CGFloat {
        if landscape {
            return 235 * MediaPropertyView.factor
        }else {
            return 470 * MediaPropertyView.factor
        }
    }
    
    var cornerRadius : CGFloat {
        if landscape {
            return 16
        }else {
            return 3
        }
    }
    
    @State var disabled = true
    var landscape: Bool = false
    
    //Returns true if we can load the page
    func login(_ _property: MediaProperty? = nil){
        
        var prop = _property
        
        if prop == nil {
            prop = self.property.model
        }
        
        guard let property = prop else {
            return
        }
        
        if let login = property.login {
            //debugPrint("login: ", login)
            
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
                

                if let currentAccount = eluvio.accountManager.currentAccount {
                    debugPrint("Setting current account and going to page.")
                    eluvio.fabric.fabricToken = currentAccount.fabricToken
                    eluvio.pathState.propertyPage = property.main_page
                    let param = PropertyParam(property:property)
                    eluvio.pathState.path.append(.property(param))
                }
            }
        }
    }

    var body: some View {
        VStack(spacing:10) {
            Button(action: {
                Task {
                    do {
                        let propertyId = property.id
                            if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                debugPrint("propertyID clicked: ", propertyId)

                                await MainActor.run {
                                    eluvio.pathState.property = property
                                }

                                var skipLogin = false
                                
                                if let requireLogin = property.require_login {
                                    if !requireLogin {
                                        skipLogin = true
                                        debugPrint("require_login ", requireLogin)
                                    }
                                }
                                
                                if let currentAccount = eluvio.accountManager.currentAccount {
                                    if currentAccount.type == .DEBUG{
                                        skipLogin = true
                                        eluvio.fabric.fabricToken = currentAccount.fabricToken
                                    }
                                }

                                //debugPrint("skipLogin: ", property)
                                
                                if !skipLogin {
                                   login()
                                }else{
                                    debugPrint("Going to property page ", property.id)
                                    eluvio.pathState.propertyPage = property.main_page
                                    let param = PropertyParam(property:property)
                                    eluvio.pathState.path.append(.property(param))
                                }
                            }else{
                                //eluvio.pathState.path.append(.errorView("Error finding property."))
                            }
                        
                    }catch(FabricError.apiError(let code, let response, let error)){
                        eluvio.handleApiError(code: code, response: response, error: error)
                        login()
                    }catch{
                        debugPrint("Error finding property ", error.localizedDescription)
                    }
                }
            }){
                if property.image != "" {
                    WebImage(url: URL(string: property.image))
                        .resizable()
                        .onSuccess { image, data, cacheType in
                            self.disabled = false
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .cornerRadius(cornerRadius)
                }else{
                    ZStack{
                        if property.backgroundImage != "" {
                            WebImage(url: URL(string: property.backgroundImage))
                                .resizable()
                                .onSuccess { image, data, cacheType in
                                    self.disabled = false
                                }
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
            .opacity(self.disabled ? 0 : 1)
            .buttonStyle(TitleButtonStyle(focused: focused, bordered : true, borderRadius: cornerRadius))
            .focused($focused)
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
    @Binding var properties: [MediaPropertyViewModel]
    var propertiesGroups : [[MediaPropertyViewModel]] {
        properties.dividedIntoGroups(of: numColumns)
    }
    
    @Binding var selected : MediaPropertyViewModel
    
    let columns = [
        GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment:.leading, spacing:20) {
            ForEach(propertiesGroups, id: \.self) {groups in
                HStack(alignment:.center, spacing:20) {
                    ForEach(groups, id: \.self) { property in
                        MediaPropertyView(property: property, selected: $selected)
                                .environmentObject(self.eluvio)
                                .fixedSize()
                    }
                    
                }
                .frame(maxWidth:.infinity, alignment:.leading)
            }
        }
        .frame(maxWidth:.infinity, maxHeight: .infinity)
    }
}


