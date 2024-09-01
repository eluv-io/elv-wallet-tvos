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
                        .frame(width:700)
                        .padding(.top, 80)
                        .padding(.bottom, 40)
                        .padding(.leading, 15)
                        .id(topId)
                    Spacer()
                }
                .frame(maxWidth:.infinity)
                MediaPropertiesView(properties:properties, selected: $selected)
                    .environmentObject(self.eluvio.pathState)
            }
        }
        .onChange(of:selected){ old, new in
            if !new.backgroundImage.isEmpty {
                withAnimation(.easeIn(duration: 2)){
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
                        
                        let mediaProperty = MediaPropertyViewModel.create(mediaProperty:property, fabric: eluvio.fabric)
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
                }catch{
                    print("Could not get properties code: ", error)
                    eluvio.accountManager.signOut()
                }
            }

            /*
            if eluvio.fabric.mediaProperties.contents.isEmpty {
                Task{
                    do {
                        try await self.eluvio.fabric.connect(network:"main", token:eluvio.accountManager.currentAccount?.fabricToken ?? "")
                        await self.eluvio.fabric.refresh()
                    }catch{}
                }
            }
             */
            
            self.fabricCancellable2 = eluvio.accountManager.$currentAccount
                .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                .sink { val in
                    debugPrint("Discoverview on isLoggedOut ", val)
                    if val == nil && !eluvio.fabric.isRefreshing {
                        Task {
                            debugPrint("Discover View refreshing fabric")
                            try await self.eluvio.fabric.connect(network:"main", token:val?.fabricToken ?? "")
                            await eluvio.fabric.refresh()
                        }
                    }
                }
        }
    }
}
