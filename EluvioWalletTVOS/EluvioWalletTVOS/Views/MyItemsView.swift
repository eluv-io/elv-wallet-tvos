//
//  MyItemsView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-15.
//

import SwiftUI
import SwiftyJSON
import Combine

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
                nfts = try await eluvio.fabric.getNFTs(address:address, name:searchString)
            }catch{
                print("Error searching properties: ", error.localizedDescription)
            }
        }
    }
    
    @State private var cancellable: AnyCancellable? = nil
    
    var body: some View {
        ScrollView{
            VStack{
                /*
                SearchBar(searchString:$searchString, logo:"", action:{_ in
                    search()
                })
                 
                 */
                //SearchBar2()
                 
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
                                        searchString = ""
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
                .padding(.leading, 0)

                NFTGrid(nfts:nfts, drops:drops)
                    .edgesIgnoringSafeArea(.all)
                    .focusSection()
                    .padding(.top,40)
            }
        }
        .scrollClipDisabled()
        .searchable(text: $searchString,prompt: "Search My Items")
        .onChange(of: searchString) {
            search()
        }
        .onAppear(){
            Task{
                do {
                    debugPrint("My Items getting properties")
                    let props = try await eluvio.fabric.getProperties(includePublic:false, newFetch:true)
                    
                    var properties: [MediaPropertyViewModel] = []
                    
                    for property in props {
                        
                        let mediaProperty = await MediaPropertyViewModel.create(mediaProperty:property, fabric: eluvio.fabric)
                        if mediaProperty.title.isEmpty {
                            debugPrint("Property without a title: \(property.slug ?? "").")
                        }else{
                            properties.append(mediaProperty)
                        }
                        
                    }
                    
                    self.properties = properties
                }catch(FabricError.apiError(let code, let response, let error)){
                    eluvio.handleApiError(code: code, response: response, error: error)
                }catch {
                    //eluvio.pathState.path.append(.errorView("A problem occured."))
                    return
                }
            }
            
            Task {
                do {
                    nfts = try await eluvio.fabric.getNFTs(address:address, propertyId:propertyId)
                }catch(FabricError.apiError(let code, let response, let error)){
                    eluvio.handleApiError(code: code, response: response, error: error)
                }catch {
                    //eluvio.pathState.path.append(.errorView("A problem occured."))
                }
            }
            
            self.cancellable = eluvio.accountManager.$currentAccount.sink { val in
                if val == nil {
                    nfts = []
                    properties = []
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
