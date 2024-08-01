//
//  SearchView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-16.
//

import SwiftUI
import SDWebImageSwiftUI

public extension FloatingPoint {
    
    func wrapped(within range: Range<Self>) -> Self {
        
        let breadth = range.upperBound - range.lowerBound
        
        let offset: Self
        if self < range.lowerBound {
            offset = breadth
        }
        else {
            offset = 0
        }
        
        let baseResult = (self - range.lowerBound).truncatingRemainder(dividingBy: breadth)

        return baseResult + range.lowerBound + offset
    }
}


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
        ZStack(alignment:.center){
            Button(action:action)
            {
                
                MediaCard(display:.video,
                          image: imageUrl,
                          isFocused:isFocused,
                          title: title,
                          showFocusedTitle: false
                )
                .background(
                    //Rectangle().fill(Color(hex:UInt(Float(title.hashValue).wrapped(within: 0x3311dd..<0x7711ff))))
                    //Rectangle().fill(Color(hex:0x0f2c56))
                        //.brightness(-0.3)
                    //    .opacity(0.6)
                    Color.buttonGraident
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .padding()
            
            Text(title.uppercased()).font(.largeTitle.bold())
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
                VStack(alignment:.center){
                    HStack(alignment:.center, spacing:40){
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
                        VStack{
                            HStack (spacing:15){
                                Image(systemName: "magnifyingglass")
                                    .resizable()
                                    .frame(width:40,height:40)
                                    .padding(10)
                                    .padding(.leading, 0)
                                TextField("Search \(name)", text: $searchString)
                                    .frame(alignment: .leading)
                                    .font(.rowTitle)
                                    .onSubmit {
                                        print("Search submit…", searchString)
                                        Task {
                                            if !propertyId.isEmpty {
                                                
                                                //if searchString.isEmpty {
                                                debugPrint("Replace Search")
                                                do {
                                                    var attributes : [String : Any] = [:]
                                                    
                                                    if let primary = currentPrimaryFilter {
                                                        if !primary.id.isEmpty{
                                                            attributes[primary.attribute] = [primary.id]
                                                        }
                                                        
                                                        if !currentSecondaryFilter.isEmpty {
                                                            attributes[primary.secondaryAttribute] = [currentSecondaryFilter]
                                                        }
                                                    }
                                                    
                                                    
                                                    self.sections = try await fabric.searchProperty(property: propertyId, attributes: attributes, searchTerm: searchString)
                                                }catch{
                                                    print("Could not do search ", error.localizedDescription)
                                                    //TODO: Send to error screen
                                                }
                                                //}else {
                                                
                                                
                                                
                                                
                                                debugPrint("New Search")
                                                
                                                /* pathState.searchParams = SearchParams(propertyId: propertyId,
                                                 searchTerm: searchString,
                                                 primaryFilters: primaryFilters,
                                                 currentPrimaryFilter: currentPrimaryFilter,
                                                 currentSecondaryFilter: currentSecondaryFilter)
                                                 pathState.path.append(.search)*/
                                                //}
                                            }
                                        }
                                    }
                            }
                            Divider().overlay(Color.gray)
                        }
                    }
                }
                .padding(40)
                .focusSection()
                
                if !primaryFilters.isEmpty{
                    //LazyVGrid(columns: squareColumns, alignment: .center, spacing:20){
                    ScrollView(.horizontal){
                        LazyHStack(spacing:10){
                            ForEach(0..<primaryFilters.count, id: \.self) { index in
                                PrimaryFilterView(
                                    filter:primaryFilters[index],
                                    action:{
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
                    .scrollClipDisabled()
                    //}
                }
                else {
                    
                    if !secondaryFilters.isEmpty {
                        ScrollView {
                            LazyHStack(spacing:20){
                                ForEach(0..<secondaryFilters.count, id: \.self) { index in
                                    Button(
                                        action:{
                                            pathState.searchParams = SearchParams(propertyId: propertyId,
                                                                                  searchTerm: searchString,
                                                                                  currentPrimaryFilter: currentPrimaryFilter,
                                                                                  currentSecondaryFilter: secondaryFilters[index]
                                            )
                                            pathState.path.append(.search)
                                            
                                        }) {
                                            Text(secondaryFilters[index].lowercased())
                                        }
                                }
                            }
                        }
                        .scrollClipDisabled()
                        
                    }
                }
                
                ForEach(sections) {section in
                    VStack{
                        MediaPropertySectionView(propertyId: propertyId, section: section)
                    }
                    .frame(maxWidth:.infinity)
                    .focusSection()
                }
                
                Spacer()
            }
            .padding([.leading,.trailing,.bottom],80)
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

                        if !searchString.isEmpty || currentPrimaryFilter != nil{
                            var attributes : [String : Any] = [:]
                            if let primary = currentPrimaryFilter {
                                if !primary.id.isEmpty{
                                    attributes[primary.attribute] = [primary.id]
                                }
                                
                                if !currentSecondaryFilter.isEmpty {
                                    attributes[primary.secondaryAttribute] = [currentSecondaryFilter]
                                }
                            }
                            
                            self.sections = try await fabric.searchProperty(property: propertyId, attributes: attributes, searchTerm: searchString)
                            return
                        }

                        
                        let filterResult = try await fabric.getPropertyFilters(property: propertyId)
                        debugPrint("Property Filter Response ",filterResult)
                        
                        let attributes = filterResult["attributes"]
                        let primaryFilterValue = filterResult["primary_filter"].stringValue
                        let secondaryFilterValue = filterResult["secondary_filter"].stringValue
                        debugPrint("has primary filter ",primaryFilterValue)
                        let primaryAttribute = attributes[primaryFilterValue]
                        
                        if !primaryAttribute.isEmpty {
                            debugPrint("Found primary attribute ",primaryAttribute)
                            var tags = primaryAttribute["tags"].arrayValue
                            let options = filterResult["filter_options"].arrayValue
                            
                            if !tags.isEmpty {
                                var newPrimaryFilters : [PrimaryFilterViewModel] = []
                                tags.insert("", at:0)
                                
                                let secondary : [String] = attributes[secondaryFilterValue]["tags"].arrayValue.map {$0.stringValue}
                                var primary = PrimaryFilterViewModel(id: "",
                                                                     imageURL: "",
                                                                     secondaryFilters: secondary,
                                                                     attribute:primaryFilterValue,
                                                                     secondaryAttribute: secondaryFilterValue)
                                
                                var hasPrimary = false
                                
                                for tag in tags {
                                    debugPrint("searching tag ", tag)
                                    for option in options {
                                        var secondary : [String] = []
                                        let secondaryJSON = attributes[option["secondary_filter_attribute"].stringValue]["tags"].arrayValue
                                        
                                        for secondaryItem in secondaryJSON {
                                            secondary.append(secondaryItem.stringValue)
                                        }
                                        

                                        if option["primary_filter_value"].stringValue == tag.stringValue {
                                            debugPrint("matched tag value for option")
                                            
                                            debugPrint("Secondary Filters ", secondary)
                                            debugPrint("Secondary attribute ", option["secondary_filter_attribute"].stringValue)
                                            var image = ""
                                            
                                            if !option["primary_filter_image"].isEmpty {
                                                do {
                                                    image = try fabric.getUrlFromLink(link: option["primary_filter_image"])
                                                }catch{
                                                    print("Could not create image for option \(option)", error.localizedDescription)
                                                }
                                            }
                                            
                                            let filter = PrimaryFilterViewModel(id: tag.stringValue,
                                                                                imageURL: image,
                                                                                secondaryFilters: secondary,
                                                                                attribute:primaryFilterValue,
                                                                                secondaryAttribute: option["secondary_filter_attribute"].stringValue)
                                                                                
                                            if tag.stringValue == "" {
                                                hasPrimary = true
                                                
                                                primary = filter
                                                
                                            }else{
                                                newPrimaryFilters.append(filter)
                                            }

                                        }
                                    }
                                }
                                
                                newPrimaryFilters.insert(primary, at:0)
                                currentPrimaryFilter = primary
                                self.primaryFilters = newPrimaryFilters
                            }
                        
                            
                        }
                        self.sections = try await fabric.searchProperty(property: propertyId)

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
