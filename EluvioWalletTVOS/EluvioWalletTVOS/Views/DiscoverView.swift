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
    @Namespace private var DiscoverViewNamespace
    @State private var properties : [MediaPropertyViewModel] = []
    @State private var fabricCancellable: AnyCancellable? = nil
    @State private var fabricCancellable2: AnyCancellable? = nil
    
    @FocusState var headerFocused
    var topId = "top"
    
    @State var backgroundImageURL = ""

    
    @State private var selected: MediaPropertyViewModel = MediaPropertyViewModel()
    @State private var position: Int?
    let timer = Timer.publish(every: 3*60, on: .main, in: .common).autoconnect()
    @State var isRefreshing = false
    @State private var opacity: Double = 0.0
    @State private var showHiddenMenu = false
    @State private var network = "main"
    let networkList = ["main", "demo"]
    
    static var refreshId = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            if eluvio.isCustomApp() {
                VStack(alignment:.center, spacing:40){
                    Spacer()
                    if properties.count == 1 {
                        WebImage(url: URL(string: properties[0].startScreenImage))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width:900, height:400, alignment:.leading)
                            .id(topId)

                        MediaPropertyView(property:properties[0], selected: $selected, isSimple: true)
                            .environmentObject(self.eluvio.pathState)
                            .prefersDefaultFocus(in: DiscoverViewNamespace)

                    }
                    Spacer()
                }
            }else {
                ScrollView() {
                    VStack(alignment:.leading, spacing:0){
                        if !properties.isEmpty {
                            HStack(){
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
                            
                            MediaPropertiesView(properties:$properties, selected: $selected)
                                .environmentObject(self.eluvio.pathState)
                                .transition(.opacity)
                        }
                    }
                }
            }
        }
        .opacity(opacity)
        .onChange(of:selected){ old, new in
            // Use the already loaded MediaPropertyViewModel data instead of fetching again
            withAnimation(.easeIn(duration:1)){
                if eluvio.isCustomApp() {
                    backgroundImageURL = new.startScreenBackground
                }else {
                    backgroundImageURL = new.backgroundImage
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
                        .frame(width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height)
                }
            }
            .opacity(opacity)
            
        )
        .scrollClipDisabled()
        .task(id:eluvio.refreshId){
            debugPrint("DiscoverView onAppear()")
            
            Task {
                withAnimation(.easeInOut(duration: 1)) {
                  opacity = 1.0
                }
            }
            if properties.count == 0{
                refresh()
            }
        }
        .onDisappear(){
            debugPrint("DiscoverView onDisappear")
            opacity = 0.0
            refresh()
        }
    }
    
    func refresh() {

        if isRefreshing{
            return
        }
        
        isRefreshing = true
        self.backgroundImageURL = ""

        debugPrint("DiscoverView refresh()")
        Task{
            defer {
                self.isRefreshing = false
            }

            for _ in 1...2 {
                var retry = false
                do {
                    try await eluvio.fabric.connect(token:eluvio.accountManager.currentAccount?.fabricToken ?? "")
                    
                    var noAuth = true
                    if eluvio.accountManager.currentAccount != nil {
                        noAuth = false
                    }
                    
                    let props = try await eluvio.fabric.getProperties(includePublic: true, noAuth:noAuth, newFetch:true, devMode: eluvio.getDevMode(), properties: APP_CONFIG.allowed_properties)
                    
                    //debugPrint("Got properties ", props.count)
                    
                    var newProperties: [MediaPropertyViewModel] = []
                    
                    for property in props{
                        let mediaProperty = await MediaPropertyViewModel.create(mediaProperty:property, fabric: eluvio.fabric)
                        if mediaProperty.image.isEmpty && !eluvio.isCustomApp(){
                            debugPrint("image is empty")
                        }else{
                            newProperties.append(mediaProperty)
                            //debugPrint("Added property ", mediaProperty.id)
                        }
                        
                        if newProperties.count > 16 {
                            self.properties = newProperties
                        }
                    }
                    
                    if eluvio.isCustomApp() && newProperties.count == 1 {
                        selected = newProperties[0]
                        withAnimation(.easeIn(duration: 1)){
                            backgroundImageURL = newProperties[0].startScreenBackground
                            debugPrint("Setting backgroundImageURL ", backgroundImageURL)
                        }
                    }else if newProperties.count > 1 {
                        selected = newProperties[0]
                        withAnimation(.easeIn(duration: 1)){
                            backgroundImageURL = newProperties[0].backgroundImage
                        }
                    }
                    self.properties = newProperties
                    debugPrint("Finished setting properties")
                }catch(FabricError.apiError(let code, let response, let error)){
                    eluvio.handleApiError(code: code, response: response, error: error)
                    if code == 401 {
                        await eluvio.refreshFabricToken()
                        retry = true
                    }
                }catch {
                    print("Could not refresh properties ", error)
                }
                if !retry {
                    break;
                }
            }
        }
    }
}
