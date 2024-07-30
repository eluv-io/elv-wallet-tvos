//
//  SearchView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-16.
//

import SwiftUI
import SDWebImageSwiftUI

struct PrimaryFilterView: View {
    var filter : PrimaryFilterViewModel
    var imageUrl : String {
        filter.imageURL
    }
    var title: String {
        filter.id == "" ? "All" : filter.id
    }
    var action : ()->()
    
    @FocusState var isFocused
    
    var body: some View {
        VStack(alignment:.center){
            Button(action:action)
            {
                MediaCard(image: imageUrl,
                          isFocused:isFocused,
                          title: title,
                          showFocusedTitle: false
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .padding()
            
            Text(title.uppercased()).font(.itemTitle.bold())
        }
    }
}

struct SearchView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var pathState: PathState
    @State var searchString : String = ""
    var propertyId : String = ""
    var logo = "e_logo"
    @State var logoUrl = ""
    @State var name = ""
    
    @State var sections : [MediaPropertySection] = []
    @State var primaryFilters : [PrimaryFilterViewModel] = []
    @State var currentPrimaryFilter : PrimaryFilterViewModel? = nil
    @State var currentSecondaryFilter = ""
    @State var secondaryFilters : [String] = []
    
    private let squareColumns = [
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    var body: some View {
        ScrollView{
            VStack(alignment:.leading) {
                HStack(alignment:.center, spacing:20){
                    if logoUrl.isEmpty {
                        Image(logo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height:100)
                    }else{
                        WebImage(url:URL(string:logoUrl))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height:100)
                    }
                    HStack (spacing:15){
                            Image(systemName: "magnifyingglass")
                            .resizable()
                            .frame(width:40,height:40)
                            .padding()
                            TextField("Search \(name)", text: $searchString)
                                .frame(alignment: .leading)
                                .font(.rowTitle)
                                .onSubmit {
                                    print("Search submit…", searchString)
                                    Task {
                                        if !propertyId.isEmpty {
                                            do {
                                                var tags : [String] = []
                                                var attributes : [String : Any] = [:]
                                                if let primary = currentPrimaryFilter {
                                                    attributes[primary.attribute] = primary.id
                                                    if !currentSecondaryFilter.isEmpty {
                                                        attributes[primary.seconaryAttribute] = currentSecondaryFilter
                                                    }
                                                }
                                                
                                                var groupBy = ""
                                                
                                                self.sections = try await fabric.searchProperty(property: propertyId, tags: tags, attributes: attributes, searchTerm: searchString)
                                                //debugPrint(result)
                                            }catch{
                                                print("Could not do search ", error.localizedDescription)
                                                //TODO: Send to error screen
                                            }
                                        }
                                    }
                                }
                        
                        }
                }
                Divider().overlay(Color.gray)
                
                if !primaryFilters.isEmpty {
                    LazyVGrid(columns: squareColumns, alignment: .center, spacing:40){
                        ForEach(0..<primaryFilters.count, id: \.self) { index in
                            PrimaryFilterView(
                                filter:primaryFilters[index],
                                action:{
                                    /*
                                    Task{
                                        debugPrint("Search Filter \(primaryFilters[index]), text \(searchString)")
                                        let filter = primaryFilters[index]
                                        
                                        var tags : [String] = []
                                        var attributes : [String : Any] = [:]
                                        
                                        if filter.id != "" {
                                            attributes = [filter.attribute : [filter.id]]
                                        }
                                        
                                        var groupBy = ""
                                        self.sections = try await fabric.searchProperty(property: propertyId, tags: tags, attributes: attributes, searchTerm: searchString, groupBy: groupBy)
                                        
                                        self.secondaryFilters = filter.secondaryFilters
                                        self.primaryFilters = []
                                        self.currentPrimaryFilter
                                    }
                                     */
                                    debugPrint("Secondary Filters: ", primaryFilters[index].secondaryFilters)
                                    pathState.searchParams = SearchParams(propertyId: propertyId,
                                                                          searchTerm: searchString,
                                                                          secondaryFilters: primaryFilters[index].secondaryFilters,
                                                                          currentPrimaryFilter: primaryFilters[index]
                                    )
                                    pathState.path.append(.search)
                    
                                })
                        }
                    }
                }
                else {
                    
                    if !secondaryFilters.isEmpty {
                        ScrollView {
                            LazyHStack(spacing:20){
                                ForEach(0..<secondaryFilters.count, id: \.self) { index in
                                    Button(
                                        action:{
                                            /*
                                             Task{
                                             debugPrint("Search Secondary Filter \(secondaryFilters[index]), text \(searchString)")
                                             let filter = secondaryFilters[index]
                                             
                                             var tags : [String] = [filter]
                                             var attributes : [String : Any] = [:]
                                             var groupBy = ""
                                             self.sections = try await fabric.searchProperty(property: propertyId, tags: tags, attributes: attributes, searchTerm: searchString, groupBy: groupBy)
                                             
                                             //self.secondaryFilters = filter.secondaryFilters
                                             }
                                             */
                                            
                                            pathState.searchParams = SearchParams(propertyId: propertyId,
                                                                                  searchTerm: searchString,
                                                                                  currentPrimaryFilter: currentPrimaryFilter,
                                                                                  currentSecondaryFilter: secondaryFilters[index]
                                            )
                                            pathState.path.append(.search)
                                            
                                        }) {
                                            Text(secondaryFilters[index].lowercased())
                                        }
                                    //.buttonStyle()
                                }
                            }
                        }
                        .scrollClipDisabled()
                        
                    }
                    
                    ForEach(sections) {section in
                        VStack{
                            MediaPropertySectionView(propertyId: propertyId, section: section)
                        }
                        .frame(maxWidth:.infinity)
                        .focusSection()
                    }
                }
                
                Spacer()
            }
            .padding([.leading,.trailing,.bottom],80)
            .padding(.top,40)
        }
        .ignoresSafeArea()
        .scrollClipDisabled()
        .onAppear(){
            Task {
                if !propertyId.isEmpty {
                    do {
                        
                        let property = try await fabric.getProperty(property: propertyId)
                        name = property?.page_title ?? ""
                        do {
                            logoUrl = try fabric.getUrlFromLink(link: property?.header_logo)
                        }catch{
                            print("Could not get logo from property \(propertyId)", error)
                        }
                        
                        if let primary = currentPrimaryFilter {
                            var attributes : [String : Any] = [:]
                            if !primary.id.isEmpty{
                                attributes[primary.attribute] = [primary.id]
                            }
                            
                            
                            if !currentSecondaryFilter.isEmpty {
                                attributes [primary.seconaryAttribute] = [currentSecondaryFilter]
                            }
                            

                            self.sections = try await fabric.searchProperty(property: propertyId, attributes: attributes, searchTerm: searchString)
                            return
                            
                        }
                        
                        let filterResult = try await fabric.getPropertyFilters(property: propertyId)
                        debugPrint("Property Filter Response ",filterResult)
                        
                        let attributes = filterResult["attributes"]
                        let primaryFilterValue = filterResult["primary_filter"].stringValue
                        debugPrint("has primary filter ",primaryFilterValue)
                        let primaryAttribute = attributes[primaryFilterValue]
                        
                        if !primaryAttribute.isEmpty {
                            debugPrint("Found primary attribute ",primaryAttribute)
                            var tags = primaryAttribute["tags"].arrayValue
                            let options = filterResult["filter_options"].arrayValue
                            
                            if !tags.isEmpty {
                                var newPrimaryFilters : [PrimaryFilterViewModel] = []
                                tags.insert("", at:0)
                                for tag in tags {
                                    debugPrint("searching tag ", tag)
                                    for option in options {
                                        var secondary : [String] = []
                                        let secondaryJSON = attributes[option["secondary_filter_attribute"].stringValue]["tags"].arrayValue
                                        
                                        for secondaryItem in secondaryJSON {
                                            secondary.append(secondaryItem.stringValue)
                                        }
                                        
                                        debugPrint("Secondary Filters ", secondary)
                                        
                                        if option["primary_filter_value"].stringValue == tag.stringValue {
                                            debugPrint("matched tag value for option")
                                            do {
                                                let primary = PrimaryFilterViewModel(id: tag.stringValue,
                                                                                     imageURL: try fabric.getUrlFromLink(link: option["primary_filter_image"]),
                                                                                     secondaryFilters: secondary,
                                                                                     attribute:primaryFilterValue,
                                                                                     seconaryAttribute: attributes["secondary_filter"].stringValue
                                                )
                                                newPrimaryFilters.append(primary)
                                            }catch{
                                                print("Could not create primary filter from data ", error.localizedDescription)
                                            }
                                        }
                                    }
                                }
                                
                                self.primaryFilters = newPrimaryFilters
                            }
                        
                            
                        }else{
                            self.sections = try await fabric.searchProperty(property: propertyId)
                        }
                        
                    }catch{
                        print("Could not do search ", error.localizedDescription)
                        //TODO: Send to error screen
                    }
                }
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
