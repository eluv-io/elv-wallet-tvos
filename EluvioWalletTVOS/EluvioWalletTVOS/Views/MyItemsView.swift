//
//  MyItemsView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-15.
//

import SwiftUI
import SwiftyJSON

struct MyItemsView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @State var searchString = ""
    @State var nfts : [NFTModel] = []
    var propertyId = ""
    var drops : [ProjectModel] = []
    var logo = "e_logo"
    var logoUrl = ""
    var name = ""
    @State var properties : [MediaPropertyViewModel] = []
    var address: String {
        if let account = eluvio.accountManager.currentAccount {
            return account.getAccountAddress()
        }
        
        return ""
    }
    
    func search(){
        Task{
            do{
                nfts = try await eluvio.fabric.getNFTs(address:address, description:searchString)
            }catch{
                print("Error searching properties: ", error.localizedDescription)
            }
        }
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
                                        searchString = ""
                                        nfts = try await eluvio.fabric.getNFTs(address:address)
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
                                        nfts = try await eluvio.fabric.getNFTs(address: address, propertyId:property.id ?? "")
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
                    .edgesIgnoringSafeArea(.all)
                    .focusSection()
                    .padding(.top,40)
            }
        }
        .scrollClipDisabled()
        .onAppear(){
            Task{
                do {
                    let props = try await eluvio.fabric.getProperties(includePublic:false)
                    
                    var properties: [MediaPropertyViewModel] = []
                    
                    for property in props {

                        let mediaProperty = MediaPropertyViewModel.create(mediaProperty:property, fabric: eluvio.fabric)
                        if mediaProperty.title.isEmpty {
                            debugPrint("Property without a title: \(property.slug ?? "").")
                        }else{
                            properties.append(mediaProperty)
                        }
                        
                    }
                    
                    self.properties = properties
                }catch{
                    print("Could not get properties code", error)
                    eluvio.signOut()
                }
            }
            
            Task {
                do {
                    nfts = try await eluvio.fabric.getNFTs(address:address, propertyId:propertyId)
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
