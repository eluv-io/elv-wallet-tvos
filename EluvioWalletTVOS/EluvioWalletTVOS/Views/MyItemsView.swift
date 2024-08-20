//
//  MyItemsView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-15.
//

import SwiftUI
import SwiftyJSON

struct MyItemsView: View {
    @EnvironmentObject var fabric: Fabric
    @State var searchString = ""
    @State var nfts : [NFTModel] = []
    var propertyId = ""
    var drops : [ProjectModel] = []
    var logo = "e_logo"
    var logoUrl = ""
    var name = ""
    @State var properties : [MediaPropertyViewModel] = []
    
    func search(){
        
    }
    
    var body: some View {
        ScrollView{
            VStack{
                SearchBar(searchString:$searchString, logo:"", action:{_ in
                    search()
                })
                ScrollView(.horizontal) {
                    LazyHStack(spacing:10){
                        if !properties.isEmpty {
                            SecondaryFilterView(title:"All", action:{
                                Task {
                                    do {
                                        nfts = try await fabric.getNFTs()
                                    }catch{
                                        print("Could not get nfts ", error.localizedDescription)
                                    }
                                }
                            })
                        }
                        ForEach(properties) { property in
                            SecondaryFilterView(title:property.title, action:{
                                debugPrint("Property \(property.id ) pressed.")
                                Task {
                                    do {
                                        nfts = try await fabric.getNFTs(propertyId:property.id ?? "")
                                    }catch{
                                        print("Could not get nfts ", error.localizedDescription)
                                    }
                                }
                            })
                        }
                    }
                }
                .scrollClipDisabled()
                .padding(.leading, 80)
                NFTGrid(nfts:nfts, drops:drops)
                    .padding(.top,40)
            }
        }
        .scrollClipDisabled()
        .onAppear(){
            Task{
                do {
                    let props = try await fabric.getProperties(includePublic:false)
                    
                    var properties: [MediaPropertyViewModel] = []
                    
                    for property in props {

                        let mediaProperty = MediaPropertyViewModel.create(mediaProperty:property, fabric: fabric)
                        if mediaProperty.title.isEmpty {
                            debugPrint("Property without a title: \(property.slug ?? "").")
                        }else{
                            properties.append(mediaProperty)
                        }
                        
                    }
                    
                    self.properties = properties
                }catch{
                    print("Could not get properties ", error.localizedDescription)
                }
                
                
            }
            
            Task {
                do {
                    nfts = try await fabric.getNFTs(propertyId:propertyId)
                }catch{
                    print("Could not get nfts ", error.localizedDescription)
                }
            }
        }
    }
}


struct MyItemsView_Previews: PreviewProvider {
    static var previews: some View {
        MyItemsView(nfts: CreateTestNFTs(num: 2))
    }
}
