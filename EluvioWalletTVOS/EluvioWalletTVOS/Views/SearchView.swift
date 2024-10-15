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
                          showFocusedTitle: false,
                          showBottomTitle: false
                )
                .background(
                    //Rectangle().fill(Color(hex:UInt(Float(title.hashValue).wrapped(within: 0x3311dd..<0x7711ff))))
                    //Rectangle().fill(Color(hex:0x0f2c56))
                        //.brightness(-0.3)
                    //    .opacity(0.6)
                    Color.buttonGradient
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .padding()
            
            if imageUrl.isEmpty {
                Text(title.uppercased()).font(.itemTitle.bold())
                    .lineLimit(3)
                    .frame(maxWidth: 400)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

struct SearchTileView: View {
    var imageUrl : String
    var title: String
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
                          showFocusedTitle: false,
                          showBottomTitle: false
                )
                .background(
                    .clear
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .padding()
            
            if imageUrl.isEmpty {
                Text(title.uppercased()).font(.itemTitle.bold())
                    .lineLimit(3)
                    .frame(maxWidth: 400)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

struct SecondaryFilterView: View {
    var title = ""
    var action : ()->()
    
    @FocusState var isFocused
    var selected = false
    
    var body: some View {
        ZStack(alignment:.center){
            Button(action:action)
            {
                Text(title)
                    .font(.rowTitle)
            }
            .buttonStyle(secondaryFilterButtonStyle(focused: isFocused, selected: selected))
            .focused($isFocused)
            .padding()
        }
    }
}

struct PropertyFilterView: View {
    var title = ""
    var imageUrl = ""
    var propertyId : String
    @Binding var currentId : String
    var action : ()->()

    
    @FocusState var isFocused
    var selected : Bool {
        return currentId == propertyId
    }
    
    var body: some View {
        ZStack(alignment:.center){
            Button(action:action)
            {
                HStack(spacing:10){
                    if !imageUrl.isEmpty{
                        WebImage(url:URL(string:imageUrl))
                            .resizable()
                            .scaledToFit()
                            .frame(width:64, height:64)
                            .padding([.top,.bottom], 10)
                    }
                    Text(title)
                        .font(.rowSubtitle)
                }
            }
            .buttonStyle(propertyFilterButtonStyle(focused: isFocused, selected: selected))
            .focused($isFocused)
            .padding()
        }
    }
}

struct PropertySelector: Hashable {
    var logoUrl : String = ""
    var iconUrl : String = ""
    var propertyId : String = ""
    var title: String = ""
    
    var isEmpty: Bool {
        return propertyId.isEmpty || (title.isEmpty && logoUrl.isEmpty && iconUrl.isEmpty)
    }
}

struct SearchView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    @State var searchString : String = ""
    var propertyId : String = ""
    @State var logoUrl = ""
    @State var name = ""
    
    @State var sections : [MediaPropertySection] = []
    @State var primaryFilters : [PrimaryFilterViewModel] = []
    @State var currentPrimaryFilter : PrimaryFilterViewModel? = nil
    @State var currentSecondaryFilter = ""
    @State var secondaryFilters : [String] = []
    
    @State var subProperties : [PropertySelector] = []
    @State var currentSubpropertyId : String = ""
    @State var selectedProperty: MediaPropertyViewModel = MediaPropertyViewModel()
    
    private let squareColumns = [
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    func search() {
        Task {
            if !propertyId.isEmpty {
                debugPrint("Replace Search")
                
                var searchPropertyId = propertyId
                if !currentSubpropertyId.isEmpty {
                    searchPropertyId = currentSubpropertyId
                }
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
                    
                    
                    self.sections = try await eluvio.fabric.searchProperty(property: searchPropertyId, attributes: attributes, searchTerm: searchString)
                }catch{
                    print("Could not do search ", error.localizedDescription)
                    //TODO: Send to error screen
                }
            }
        }
    }
    
    var body: some View {
        ScrollView(.vertical){
            VStack(alignment:.leading) {
                SearchBar(searchString:$searchString, logoUrl:logoUrl, name:name, action:{ searchString in
                    search()
                })
                .frame(height:200)
                .padding(.top,40)
                .padding(.bottom)
                
                if !subProperties.isEmpty {
                    if searchString.isEmpty {
                        ScrollView(.horizontal){
                            LazyHStack(spacing:20){
                                ForEach(subProperties, id: \.self) { property in
                                    //MediaPropertySelectorView(propertyId: property.propertyId, title: property.title, logoUrl: property.logoUrl,  landscape:true)
                                    SearchTileView(
                                        imageUrl: property.logoUrl,
                                        title: property.title,
                                        action:{
                                            Task {
                                                do {
                                                    if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                                        debugPrint("propertyID clicked: ", propertyId)
                                                        
                                                        await MainActor.run {
                                                            eluvio.pathState.propertyPage = property.main_page
                                                        }
                                                        
                                                        await MainActor.run {
                                                            let param = PropertyParam(property:property)
                                                            eluvio.pathState.path = []
                                                            eluvio.pathState.path.append(.property(param))
                                                        }
                                                    }

                                                }catch(FabricError.apiError(let code, let response, let error)){
                                                    eluvio.handleApiError(code: code, response: response, error: error)
                                                }catch{
                                                    debugPrint("Error finding property ", error.localizedDescription)
                                                }
                                            }
                                        })
                                }
                            }
                            
                        }
                        .scrollClipDisabled()
                        .padding([.leading,.trailing], 80)
                    }else {
                        ScrollView(.horizontal){
                            LazyHStack(spacing:10){
                                Text("Search In: ")
                                    .font(.rowTitle)
                                ForEach(subProperties, id: \.self) { property in
                                    //if property.hasAuth {
                                        PropertyFilterView(
                                            title:property.title,
                                            imageUrl: property.iconUrl,
                                            propertyId: property.propertyId,
                                            currentId: $currentSubpropertyId,
                                            action:{
                                                if self.currentSubpropertyId != property.propertyId {
                                                    self.currentSubpropertyId = property.propertyId
                                                    search()
                                                }else {
                                                    self.currentSubpropertyId = ""
                                                    search()
                                                }
                                            }
                                        )
                                    //}
                                }
                            }
                            
                        }
                        .scrollClipDisabled()
                        .padding([.leading,.trailing], 80)
                    }
                }

                if !primaryFilters.isEmpty{
                    ScrollView(.horizontal){
                        LazyHStack(spacing:10){
                            ForEach(0..<primaryFilters.count, id: \.self) { index in
                                PrimaryFilterView(
                                    filter:primaryFilters[index],
                                    action:{
                                        debugPrint("Secondary Filters: ", primaryFilters[index].secondaryFilters)
                                        eluvio.pathState.searchParams = SearchParams(propertyId: propertyId,
                                                                              searchTerm: searchString,
                                                                              secondaryFilters: primaryFilters[index].secondaryFilters,
                                                                              currentPrimaryFilter: primaryFilters[index]
                                        )
                                        eluvio.pathState.path.append(.search)
                                        searchString = ""
                                        
                                    })
                            }
                        }
                        
                    }
                    .scrollClipDisabled()
                    .padding(.top,20)
                    .padding([.leading,.trailing], 80)
                }
                else {
                    if !secondaryFilters.isEmpty {
                        ScrollView {
                            LazyHStack(spacing:10){
                                HStack(spacing:20){
                                    Image("back")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height:30)
                                    
                                    Button(
                                        action:{
                                            _ = eluvio.pathState.path.popLast()
                                        }) {
                                            
                                            if let text = currentPrimaryFilter?.id {
                                                Text("\(text == "" ? "ALL" : text.uppercased() )")
                                            }
                                        }
                                        .buttonBorderShape(.capsule)
                                }

                                
                                ForEach(0..<secondaryFilters.count, id: \.self) { index in
                                    SecondaryFilterView(
                                        title: secondaryFilters[index],
                                        action:{
                                            currentSecondaryFilter = secondaryFilters[index]
                                            search()
                                            
                                        },
                                        selected: currentSecondaryFilter == secondaryFilters[index]
                                    )
                                }
                            }
                        }
                        .scrollClipDisabled()
                        .padding(.top,20)
                        .padding([.leading,.trailing], 80)
                    }
                }
                
                
                if sections.count == 1 {
                    SectionGridView(propertyId: propertyId, pageId: "main", section: sections.first!, forceDisplay: .square)
                        .edgesIgnoringSafeArea([.leading,.trailing])
                        .frame(maxWidth:.infinity)
                        .padding(.top,40)
                }else {
                    ForEach(sections) {section in
                        VStack{
                            MediaPropertySectionView(propertyId: propertyId, pageId:"main", section: section)
                                .edgesIgnoringSafeArea([.leading,.trailing])
                        }
                        .frame(maxWidth:.infinity)
                        .focusSection()
                    }
                    .padding(.top,40)
                }
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .scrollClipDisabled()
        .onChange(of: searchString) {
            search()
        }
        .onAppear(){
            if !sections.isEmpty {
                return
            }
            Task {
                if !propertyId.isEmpty {
                    do {
                        debugPrint("Search onAppear()")
                        
                        var mainProperty = try await eluvio.fabric.getProperty(property: propertyId)
                        
                        //Retrieving sub properties to populate Search In: filters
                        var subs : [PropertySelector] = []
                        if let subproperties = mainProperty?.property_selection {
                            debugPrint("Found subproperties ", subproperties)
                            for subpropSelection in subproperties.arrayValue {
                                var logoUrl = ""
                                debugPrint("subpropSelection : ", subpropSelection)
                                debugPrint("logo link: ",subpropSelection["logo"])
                                do {
                                    logoUrl = try eluvio.fabric.getUrlFromLink(link: subpropSelection["logo"])
                                }catch{
                                    print("Could not get logo from link ", error)
                                }
                                
                                var iconUrl = ""
                                do {
                                    iconUrl = try eluvio.fabric.getUrlFromLink(link: subpropSelection["icon"])
                                }catch{
                                    print("Could not get icon from link ", error)
                                }
                                
                                let selector = PropertySelector(logoUrl: logoUrl,
                                                                iconUrl: iconUrl,
                                                                propertyId: subpropSelection["property_id"].stringValue,
                                                                title: subpropSelection["title"].stringValue)
                                debugPrint("selector created: ", selector)
                                if !selector.isEmpty {
                                    subs.append(selector)
                                    debugPrint("added selector")
                                }
                            }
                        }
                        
                        subProperties = subs
                        
                        var searchPropertyId = propertyId
                        
                        if !currentSubpropertyId.isEmpty{
                            searchPropertyId = currentSubpropertyId
                        }
                        
                        var property = try await eluvio.fabric.getProperty(property: searchPropertyId)

                        name = property?.page_title ?? ""
                        do {
                            logoUrl = try eluvio.fabric.getUrlFromLink(link: property?.header_logo)
                        }catch{
                            print("Could not get logo from property \(propertyId)", error)
                        }

                        if !searchString.isEmpty || currentPrimaryFilter != nil{
                            debugPrint("Search searchString \(searchString) currentPrimaryFilter \(currentPrimaryFilter)")
                            var attributes : [String : Any] = [:]
                            if let primary = currentPrimaryFilter {
                                if !primary.id.isEmpty{
                                    attributes[primary.attribute] = [primary.id]
                                }
                                
                                if !currentSecondaryFilter.isEmpty {
                                    attributes[primary.secondaryAttribute] = [currentSecondaryFilter]
                                }
                            }
                            
                            debugPrint("Searching property")
                            self.sections = try await eluvio.fabric.searchProperty(property: propertyId, attributes: attributes, searchTerm: searchString)
                            return
                        }

                        
                        let filterResult = try await eluvio.fabric.getPropertyFilters(property: propertyId)
                        debugPrint("Property Filter Response ",filterResult)
                        
                        let attributes = filterResult["attributes"]
                        let primaryFilterValue = filterResult["primary_filter"].stringValue
                        let secondaryFilterValue = filterResult["secondary_filter"].stringValue
                        debugPrint("has primary filter ",primaryFilterValue)
                        let primaryAttribute = attributes[primaryFilterValue]
                        let options = filterResult["filter_options"].arrayValue
                        var newPrimaryFilters : [PrimaryFilterViewModel] = []
                        //tags.insert("", at:0)
                        let secondary : [String] = attributes[secondaryFilterValue]["tags"].arrayValue.map {$0.stringValue}
                        var allPrimaryFilter = PrimaryFilterViewModel(id: "",
                                                                      imageURL: "",
                                                                      secondaryFilters: secondary,
                                                                      attribute:primaryFilterValue,
                                                                      secondaryAttribute: secondaryFilterValue)
                        var foundAllPrimary = false
                        
                        if !options.isEmpty {
                            for option in options {
                                var secondary : [String] = []
                                let secondaryJSON = attributes[option["secondary_filter_attribute"].stringValue]["tags"].arrayValue
                                
                                for secondaryItem in secondaryJSON {
                                    secondary.append(secondaryItem.stringValue)
                                }
                                
                        
                                debugPrint("Secondary Filters ", secondary)
                                debugPrint("Secondary attribute ", option["secondary_filter_attribute"].stringValue)
                                var image = ""
                                let primaryValue = option["primary_filter_value"].stringValue
                                
                                if !option["primary_filter_image"].isEmpty {
                                    do {
                                        image = try eluvio.fabric.getUrlFromLink(link: option["primary_filter_image"])
                                    }catch{
                                        print("Could not create image for option \(option)", error.localizedDescription)
                                    }
                                }
                                
                                debugPrint("filter image: ", image)
                                    
                                let filter = PrimaryFilterViewModel(id: primaryValue,
                                                                    imageURL: image,
                                                                    secondaryFilters: secondary,
                                                                    attribute:primaryFilterValue,
                                                                    secondaryAttribute: option["secondary_filter_attribute"].stringValue)
                                    
                                newPrimaryFilters.append(filter)
                            }
                        }else if !primaryAttribute.isEmpty {
                            debugPrint("Found primary attribute ",primaryAttribute)
                            var tags = primaryAttribute["tags"].arrayValue

                            
                            debugPrint("tags: ", tags)
                            debugPrint("options: ", options)
                            
                            if !tags.isEmpty {
                                for tag in tags {
                                    debugPrint("searching tag ", tag)
                                    var foundOptions = false
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
                                                    image = try eluvio.fabric.getUrlFromLink(link: option["primary_filter_image"])
                                                }catch{
                                                    print("Could not create image for option \(option)", error.localizedDescription)
                                                }
                                            }
                                            
                                            debugPrint("filter image: ", image)
                                            
                                            let filter = PrimaryFilterViewModel(id: tag.stringValue,
                                                                                imageURL: image,
                                                                                secondaryFilters: secondary,
                                                                                attribute:primaryFilterValue,
                                                                                secondaryAttribute: option["secondary_filter_attribute"].stringValue)
                                            
                                            if tag.stringValue == "" {
                                                allPrimaryFilter = filter
                                                foundAllPrimary = true
                                            }else{
                                                newPrimaryFilters.append(filter)
                                            }
                                            foundOptions = true
                                        }
                                    }
                                    
                                    if !foundOptions {
                                        let filter = PrimaryFilterViewModel(id: tag.stringValue,
                                                                            imageURL: "",
                                                                            secondaryFilters: secondary,
                                                                            attribute:primaryFilterValue,
                                                                            secondaryAttribute: secondaryFilterValue)
                                        if tag.stringValue == "" {
                                            allPrimaryFilter = filter
                                            foundAllPrimary = true
                                        }else{
                                            newPrimaryFilters.append(filter)
                                        }
                                    }
                                }
                                
                                if foundAllPrimary {
                                    newPrimaryFilters.insert(allPrimaryFilter, at:0)
                                }

                            }
                        }
                        self.primaryFilters = newPrimaryFilters
                        
                        debugPrint("Searching ALL ", propertyId)
                        self.sections = try await eluvio.fabric.searchProperty(property: propertyId)
                        debugPrint("result: ", sections.first)

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
