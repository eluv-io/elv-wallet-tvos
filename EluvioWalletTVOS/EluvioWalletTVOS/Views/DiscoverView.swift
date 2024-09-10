//
//  DiscoverView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.


import SwiftUI
import SwiftyJSON
import Combine
import SDWebImageSwiftUI

struct DiscoverView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @State private var properties : [MediaPropertyViewModel] = []
    @State private var fabricCancellable: AnyCancellable? = nil
    @State private var fabricCancellable2: AnyCancellable? = nil
    
    @FocusState var headerFocused
    var topId = "top"
    
    @State var backgroundImageURL = ""

    
    @State private var selected: MediaPropertyViewModel = MediaPropertyViewModel()
    @State private var position: Int?
    
    var body: some View {
        ScrollView() {
            VStack(alignment: .leading, spacing: 0){
                HStack{
                    Image("start-screen-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:801, height:240, alignment:.leading)
                        .id(topId)
                    Spacer()
                }
                .frame(maxWidth:.infinity)
                .padding(.top, 60)
                .padding(.bottom, 40)
                MediaPropertiesView(properties:properties, selected: $selected)
                    .environmentObject(self.eluvio.pathState)
            }
        }
        .onChange(of:selected){ old, new in
            if !new.backgroundImage.isEmpty {
                withAnimation(.easeIn(duration: 2)){
                    backgroundImageURL = new.backgroundImage
                }
            }else{
                Task {
                    
                    do {
                        if let mediaProperty = try await eluvio.fabric.getProperty(property:new.id ?? "") {
                            //debugPrint("Fetched new property ", mediaProperty.id)
                            
                            let viewItem = await MediaPropertyViewModel.create(mediaProperty: mediaProperty, fabric: eluvio.fabric)
                            
                            withAnimation(.easeIn(duration: 2)){
                                backgroundImageURL = viewItem.backgroundImage
                            }
                        }
                    }catch{
                        debugPrint("Could not fetch new property ",error.localizedDescription)
                    }
                }
                
            }
        }
        .background(
            Group{
                if (!backgroundImageURL.isEmpty){
                    WebImage(url: URL(string:backgroundImageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .scrollClipDisabled()
        .onAppear(){
            Task{
                do {
                    try await self.eluvio.fabric.connect(network:"main", token:eluvio.accountManager.currentAccount?.fabricToken ?? "")
   
                    let props = try await eluvio.fabric.getProperties(includePublic: true)
                    
                    var properties: [MediaPropertyViewModel] = []
                    
                    for property in props{
                        //debugPrint("PROPERTY: \(property.title)")
                        
                        let mediaProperty = await MediaPropertyViewModel.create(mediaProperty:property, fabric: eluvio.fabric)
                        //debugPrint("\(mediaProperty.title) ---> created")
                        if mediaProperty.image.isEmpty {
                            
                        }else{
                            //debugPrint("image: \(mediaProperty.image)")
                            properties.append(mediaProperty)
                        }
                    }
                    
                    await MainActor.run {
                        self.properties = properties
                    }
                }catch(FabricError.apiError(let code, let response, let error)){
                    print("Could not get properties ", error.localizedDescription)
                    let errors = response["errors"].arrayValue
                    if errors.isEmpty{
                        eluvio.pathState.path.append(.errorView("A problem occured."))
                        return
                    }else if errors[0]["cause"]["reason"].stringValue.contains("token expired"){
                        eluvio.pathState.path = []
                        eluvio.signOut()
                        eluvio.pathState.path.append(.errorView("Your session has expired."))
                        return
                    }else {
                        eluvio.pathState.path.append(.errorView("A problem occured."))
                        return
                    }
                }catch {
                    eluvio.pathState.path.append(.errorView("A problem occured."))
                }
            }
            

            self.fabricCancellable2 = eluvio.accountManager.$currentAccount
                .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                .sink { val in
                    if val == nil {
                        properties = []
                    }
                }
        }
    }
}
