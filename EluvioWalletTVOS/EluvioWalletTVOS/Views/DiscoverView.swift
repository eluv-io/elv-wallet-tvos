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
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State var isRefreshing = false
    @State private var opacity: Double = 0.0
    @State private var showHiddenMenu = false
    @State private var network = "main"
    let networkList = ["main", "demo"]
    
    static var refreshId = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            ScrollView() {
                VStack(alignment:.leading, spacing:0){
                    if !properties.isEmpty {
                        HStack(){
                            Image("start-screen-logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width:801, height:240, alignment:.leading)
                                .id(topId)
                                //.focusable()
                                .onLongPressGesture(minimumDuration: 5) {
                                    print("Secret Long Press Action!")
                                    //FIXME: This does not work
                                    //showHiddenMenu = true
                                }
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
        .opacity(opacity)
        .sheet(isPresented: $showHiddenMenu) {
            HStack{
                Text("Network Selection: ")
                
                Button("Main") {
                    Task{
                        network = "main"
                        eluvio.needsRefresh()
                        showHiddenMenu = false
                        eluvio.accountManager.signOut()
                        refresh()

                    }
                }
                Button("Demo") {
                    Task{
                        network = "demo"
                        eluvio.needsRefresh()
                        showHiddenMenu = false
                        eluvio.accountManager.signOut()
                        refresh()
                    }
                }
            }
        }
        .onChange(of:selected){ old, new in
            if !new.backgroundImage.isEmpty {
                withAnimation(.easeIn(duration: 1)){
                    backgroundImageURL = new.backgroundImage
                }
            }else{
                Task {
                    do {
                        if let mediaProperty = try await eluvio.fabric.getProperty(property:new.id ?? "") {
                            //debugPrint("Fetched new property ", mediaProperty.id)
                            let viewItem = await MediaPropertyViewModel.create(mediaProperty: mediaProperty, fabric: eluvio.fabric)
                            withAnimation(.easeIn(duration:1)){
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
                        .frame(width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height)
                }
            }
            .opacity(opacity)
        )
        .scrollClipDisabled()
        .task(){
            refresh()
        }
        .onReceive(timer) { time in
            if properties.isEmpty {
                debugPrint("on discover timer ", properties)
                refresh()
           }
        }
        .onWillDisappear {
            eluvio.needsRefresh()
        }
        .onDisappear(){
            debugPrint("DiscoverView onDisappear")
            opacity = 0.0
        }
    }
    
    func refresh() {
        
        if DiscoverView.refreshId != eluvio.refreshId {
            debugPrint("Resetting properties back to empty")
            properties = []
        }

        if !properties.isEmpty {
            return
        }
    
        if isRefreshing{
            return
        }
        
        isRefreshing = true
        self.backgroundImageURL = ""
        
        Task {
            withAnimation(.easeInOut(duration: 2)) {
              opacity = 1.0
            }
        }
            
        debugPrint("DiscoverView refresh()")
        Task{
            defer {
                self.isRefreshing = false
            }

            do {
                try await eluvio.fabric.connect(network:network, token:eluvio.accountManager.currentAccount?.fabricToken ?? "")
                
                var noAuth = true
                if eluvio.accountManager.currentAccount != nil {
                    noAuth = false
                }
                
                let props = try await eluvio.fabric.getProperties(includePublic: true, noAuth:noAuth, newFetch:true, devMode: eluvio.getDevMode())
                
                debugPrint("Got properties ", props.count)
                
                var newProperties: [MediaPropertyViewModel] = []
                
                for property in props{
                    let mediaProperty = await MediaPropertyViewModel.create(mediaProperty:property, fabric: eluvio.fabric)
                    if mediaProperty.image.isEmpty {
                        debugPrint("image is empty")
                    }else{
                        newProperties.append(mediaProperty)
                        //debugPrint("Finished setting properties ", mediaProperty.image);
                    }
                    
                    if newProperties.count > 16 {
                        self.properties = newProperties
                    }
                }
                
                await MainActor.run {
                    if newProperties.count > 0 {
                        selected = newProperties[0]
                        withAnimation(.easeIn(duration: 1)){
                            backgroundImageURL = selected.backgroundImage
                        }
                    }
                    self.properties = newProperties
                    debugPrint("Finished setting properties")
                }
            }catch(FabricError.apiError(let code, let response, let error)){
                eluvio.handleApiError(code: code, response: response, error: error)
            }catch {
                print("Could not refresh properties ", error.localizedDescription)
            }
        }
    }
}
