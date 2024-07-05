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
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var pathState: PathState
    @State private var properties : [MediaPropertyViewModel] = []
    @State private var fabricCancellable: AnyCancellable? = nil
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
                        .environmentObject(self.pathState)
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
                }/*else if (!properties.isEmpty) {
                    WebImage(url: URL(string:properties[0].backgroundImage))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                }*/
            }
        )
        .scrollClipDisabled()
        .onAppear(){
            self.fabricCancellable = fabric.$mediaProperties
                .receive(on: DispatchQueue.main)  //Delays the sink closure to get called after didSet
                .sink { val in
                    var properties: [MediaPropertyViewModel] = []
                    if val.contents.isEmpty {
                        return
                    }
                    
                    for property in val.contents {
                        let mediaProperty = MediaPropertyViewModel.create(mediaProperty:property, fabric: fabric)
                        //debugPrint("MediaProperty Created ", mediaProperty.image)
                        properties.append(mediaProperty)
                    }
                    self.properties = properties
                }
        }
    }
}
