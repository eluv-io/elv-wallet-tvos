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
            self.fabricCancellable = eluvio.fabric.$mediaProperties
                .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                .sink { val in
                    //debugPrint("onMediaProperties changed count: ", val.contents.count )
                    var properties: [MediaPropertyViewModel] = []
                    if val.contents.isEmpty {
                        return
                    }
                    
                    for property in val.contents {
                        let mediaProperty = MediaPropertyViewModel.create(mediaProperty:property, fabric: eluvio.fabric)
                        //debugPrint("\(mediaProperty.title) ---> created")
                        if mediaProperty.image.isEmpty {
                            
                        }else{
                            //debugPrint("image: \(mediaProperty.image)")
                            properties.append(mediaProperty)
                        }
                    }
                    self.properties = properties
                }
            
            if eluvio.fabric.mediaProperties.contents.isEmpty {
                Task{
                    do {
                        try await self.eluvio.fabric.connect(network:"main")
                        await self.eluvio.fabric.refresh()
                    }catch{}
                }
            }
            
            self.fabricCancellable2 = eluvio.fabric.$isLoggedOut
                .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                .sink { val in
                    debugPrint("Discoverview on isLoggedOut ", val)
                    if val == true && !eluvio.fabric.isRefreshing {
                        Task {
                            debugPrint("Discover View refreshing fabric")
                            try await self.eluvio.fabric.connect(network:"main")
                            await eluvio.fabric.refresh()
                        }
                    }
                }
        }
    }
}
