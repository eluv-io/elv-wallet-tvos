//
//  ItemDetailView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-15.
//

import SwiftUI


struct ItemDetailView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var pathState: PathState
    
    var item : NFTModel
    var name : String {
        item.meta.name ?? ""
    }
    
    var description : String {
        item.meta.description ?? ""
    }
    
    var edition : String {
        item.meta.editionName ?? ""
    }
    
    var tokenId : String {
        "#" + (item.token_id_str ?? "")
    }
    
    var tokenDisplay : String {
        if tokenId.isEmpty {
            return ""
        }
        
        if tokenId.hasPrefix("#") {
            return tokenId
        }
        
        return "#\(tokenId)"
    }
    
    var subtitle : String {
        return edition + " " + tokenDisplay
    }
    
    var imageUrl : String {
        item.meta.image ?? ""
    }
    
    var propertyId : String {
        item.nft_template?["bundled_property_id"].stringValue ?? ""
    }
    
    @State var selection: Int = 0
    @FocusState var descriptionFocused
    @FocusState var mintFocused
    @FocusState var contractFocused
    
    @State private var mintInfo: [LabelValuePair] = []
    private var hash: String {
        if let versionHash = FindContentHash(uri: item.token_uri ?? "") {
            return versionHash
        }
        
        return ""
    }
    
    var body: some View {
            ZStack{
                VStack(){
                    HStack(alignment:.top, spacing:80){
                        VStack{
                            NFTView2(nft:item)
                                .disabled(true)
                            
                            if !propertyId.isEmpty {
                                Button(action: {
                                    debugPrint("Go To Property ", propertyId)
                                    Task {
                                        if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                            debugPrint("Found property")
                                        
                                            
                                            let page = property.main_page

                                            await MainActor.run {
                                                debugPrint("Found sub property page")
                                                eluvio.pathState.property = property
                                                eluvio.pathState.propertyPage = page
                                                let params = PropertyParam(property:property, pageId: page?.id ?? "main")
                                                eluvio.pathState.path.append(.property(params))
                                            }
                                            
                                        }else{
                                            debugPrint("Could not find property")
                                            //eluvio.pathState.path.append(.errorView("Could not find property."))
                                        }
    
                                    }
                                }) {
                                    Text("Go To Property")
                                }
                                .padding()
                            }
                            Spacer()
                        }
                        .frame(maxHeight:.infinity)
                        .padding(.top,80)
                        .focusSection()
                        
                        VStack(alignment:.leading){
                            HStack(spacing:10){
                                Button(action:{
                                    selection = 0
                                    debugPrint("selection ", selection)
                                }){
                                    Text("Description")
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(TextButtonStyle(focused: descriptionFocused, selected: selection == 0))
                                .focused($descriptionFocused)
                                
                                Button(action:{
                                    selection = 1
                                    debugPrint("selection ", selection)
                                }){
                                    Text("Mint Info")
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(TextButtonStyle(focused: mintFocused, selected: selection == 1))
                                .focused($mintFocused)
                                
                                Button(action:{
                                    selection = 2
                                    debugPrint("selection ", selection)
                                }){
                                    Text("Contract & Version")
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(TextButtonStyle(focused: contractFocused, selected: selection == 2))
                                .focused($contractFocused)
                                //Spacer()
                            }
                            .padding(.top,80)
                            .padding(.bottom, 40)
                            
                            ZStack{
                                if selection == 0 {
                                    ItemDescriptionView(name:name, subtitle: subtitle, description: description)
                                }
                                
                                if selection == 1 {
                                    MintInfoView(mintInfo:mintInfo)
                                }
                                
                                if selection == 2 {
                                    ItemContractInfoView(address:item.contract_addr ?? "", hash: hash)
                                }
                            }
                            .frame(maxWidth:650, alignment:.leading)
                            .padding(.leading, 20)
                            Spacer()
                        }
                        .frame(maxHeight:.infinity)
                        .focusSection()
                    }
                    .padding(50)
                }
                .ignoresSafeArea()
                .frame( maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
            }
            .onChange(of:descriptionFocused) {
                if descriptionFocused {
                    selection = 0
                }
            }
            .onChange(of:mintFocused) {
                if mintFocused {
                    selection = 1
                }
            }
            .onChange(of:contractFocused) {
                if contractFocused {
                    selection = 2
                }
            }
            .background(.thinMaterial)
            .onAppear(){
                descriptionFocused = true
                debugPrint("Item \(item.meta)")
                
                Task{
                    do {
                        if let response = try await eluvio.fabric.signer?.getNftInfo(nftAddress: item.contract_addr ?? "", accessCode: eluvio.fabric.fabricToken) {
                        
                            debugPrint("get Nft info ", response)
                            
                            var info : [LabelValuePair] = []
                            
                            var cap = response["cap"].intValue
                            var burned = response["burned"].intValue
                            var maxPossible = cap - burned
                            var supply = response["total_supply"].intValue
                            var minted = response["minted"].intValue
                            
                            //debugPrint("Mint Info: ", item.mintInfo)
                            info.append(LabelValuePair(label:"Edition", info:item.meta.editionName ?? ""))
                            info.append(LabelValuePair(label:"Number Minted", info:String(minted)))
                            info.append(LabelValuePair(label:"Number in Circulation", info:String(supply)))
                            info.append(LabelValuePair(label:"Number Burned", info:String(burned)))
                            info.append(LabelValuePair(label:"Maximum Possible in Circulation", info:String(maxPossible)))
                            info.append(LabelValuePair(label:"Cap", info:String(cap)))
                            
                            mintInfo = info
                            
                        }
                    }catch(FabricError.apiError(let code, let response, let error)){
                        eluvio.handleApiError(code: code, response: response, error: error)
                    }catch {
                        //eluvio.pathState.path.append(.errorView("A problem occured."))
                        print("Could not get mint info ", error.localizedDescription)
                        return
                    }
                }
            }
        }
    }


struct ItemDescriptionView: View {
    var name: String
    var subtitle: String = ""
    var description: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !name.isEmpty {
                Text(name)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
            }
            Text(description)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding(.bottom,40)
                .lineLimit(20)
        }
    }
}

struct LabelValuePair : Identifiable, Hashable {
    var id: String = UUID().uuidString
    var label: String
    var info: String
}

struct MintInfoView: View {
    //Array of tuples label, info
    var mintInfo : [LabelValuePair] = []
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ForEach(mintInfo, id:\.self) { mint in
                VStack(alignment:.leading, spacing:10) {
                    Text(mint.label)
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.6))
                    Text(mint.info)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct ItemContractInfoView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    var address: String
    var hash: String = ""
    var url: String {
        return "https://explorer.contentfabric.io/address/\(address)/transactions"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment:.leading, spacing:10) {
                Text("Contract Address")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.6))
                Text(address)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
                
            VStack(alignment:.leading, spacing:10) {
                Text("Hash")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.6))
                Text(hash)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
                
            Button(action:{
                let params = HtmlParams(url:url, title:"See More Info on Eluvio Lookout")
                eluvio.pathState.path.append(.html(params))
            }){
                Text("See More Info on Eluvio Lookout")
            }
        }
    }
}
