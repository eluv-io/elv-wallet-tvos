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
    var title: String {
        filter.id == "" ? "All" : filter.id
    }
    var action : ()->()
    
    @FocusState var isFocused
    var selected = false
    
    var body: some View {
        //ZStack(alignment:.center){
            Button(action:action)
            {
                Text(title)
                    .font(.rowTitle)
            }
            .buttonStyle(primaryFilterButtonStyle(focused: isFocused, selected: selected))
            .focused($isFocused)
            //.padding()
        //}
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
    var imageUrl = ""
    var action : ()->()
    
    @FocusState var isFocused
    var selected = false
    
    var body: some View {
        ZStack(alignment:.center){
            Button(action:action)
            {
                if !imageUrl.isEmpty{
                    WebImage(url:URL(string:imageUrl))
                        .resizable()
                        .scaledToFit()
                        .frame(width:80, height:80)
                }else {
                    Text(title)
                        .font(.rowTitle)
                }
            }
            .buttonStyle(secondaryFilterButtonStyle(focused: isFocused, selected: selected, isImage: !imageUrl.isEmpty))
            .focused($isFocused)
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
    @State var currentSecondaryFilter : SecondaryFilterViewModel? = nil
    @State var secondaryFilters : [SecondaryFilterViewModel] = []
    
    @State var subProperties : [PropertySelector] = []
    @State var currentSubpropertyId : String = ""
    @State var selectedProperty: MediaPropertyViewModel = MediaPropertyViewModel()
    @State var refreshId : String = UUID().uuidString
    
    private let squareColumns = [
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    func getPrimaryFilters(searchPropertyId: String) async throws -> [PrimaryFilterViewModel] {
        var property = try await eluvio.fabric.getProperty(property: searchPropertyId)

        let filterResult = try await eluvio.fabric.getPropertyFilters(property: propertyId)
        //debugPrint("Property Filter Response ",filterResult)
        
        let attributes = filterResult["attributes"]
        let primaryFilterValue = filterResult["primary_filter"].stringValue
        debugPrint("primaryFilterValue ",primaryFilterValue)
        
        let secondaryFilterValue = filterResult["secondary_filter"].stringValue

        let primaryAttribute = attributes[primaryFilterValue]
        let options = filterResult["filter_options"].arrayValue
        var newPrimaryFilters : [PrimaryFilterViewModel] = []

        if !primaryAttribute.isEmpty {
            debugPrint("Found primary attribute ",primaryAttribute)
            let primaryTags = primaryAttribute["tags"].arrayValue

            
            debugPrint("tags: ", primaryTags)
            debugPrint("options: ", options)
            
            if !options.isEmpty {
                for option in options {
                    let optionPrimaryFilterValue = option["primary_filter_value"].stringValue
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

                        //Find secondary filters
                        var secondary : [SecondaryFilterViewModel] = []
                        let secondaryFilterOptions = option["secondary_filter_options"].arrayValue
                        
                        for secondaryItem in secondaryFilterOptions {
                            var secondaryImage = ""
                            if !secondaryItem["secondary_filter_image"].isEmpty {
                                do {
                                    secondaryImage = try eluvio.fabric.getUrlFromLink(link: secondaryItem["secondary_filter_image_tv"])
                                }catch{
                                    print("Could not create image for option \(option)", error.localizedDescription)
                                }
                            }
                            
                            let secondaryValue = secondaryItem["secondary_filter_value"].stringValue
                            
                            let secondaryFilter = SecondaryFilterViewModel(id: secondaryValue,
                                                                           imageUrl: secondaryImage)
                            secondary.append(secondaryFilter)
                        }
                    
                        let secondaryAttribute = option["secondary_filter_attribute"].stringValue
                        if secondary.isEmpty {
                            for secondaryTag in attributes[secondaryAttribute]["tags"].arrayValue {
                                secondary.append(SecondaryFilterViewModel(id: secondaryTag.stringValue))
                            }
                        }
                    
                        let filterStyle = option["secondary_filter_style"].stringValue
                        let filter = PrimaryFilterViewModel(id: optionPrimaryFilterValue,
                                                            imageUrl: image,
                                                            secondaryFilters: secondary,
                                                            attribute:primaryFilterValue,
                                                            secondaryAttribute: secondaryAttribute,
                                                            secondaryFilterStyle: PrimaryFilterViewModel.GetFilterStyle(style:filterStyle)
                        )
                        
                        newPrimaryFilters.append(filter)
                }
            }else if !primaryTags.isEmpty {
                for tag in primaryTags {
                    debugPrint("searching tag ", tag)
                    let filter = PrimaryFilterViewModel(id: tag.stringValue,
                                                        imageUrl: "",
                                                        secondaryFilters: [],
                                                        attribute:primaryFilterValue,
                                                        secondaryAttribute:"")
                    
                    newPrimaryFilters.append(filter)
                }
                
            }
        }
       return newPrimaryFilters
    }
    
    
    func refresh() {
        if !sections.isEmpty {
            return
        }
        Task {
            if !propertyId.isEmpty {
                do {
                    debugPrint("Search onAppear()")
                    
                    var mainProperty = try await eluvio.fabric.getProperty(property: propertyId)
                    var searchPropertyId = propertyId
                    
                    if !currentSubpropertyId.isEmpty{
                        searchPropertyId = currentSubpropertyId
                    }
                    
                    let property = try await eluvio.fabric.getProperty(property: searchPropertyId)
                    
                    if let title = property?.title{
                        name = title
                    }
                    
                    if name.isEmpty {
                        if let title = property?.page_title {
                            name = title
                        }
                    }
                    
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
                            
                            if let secondary = currentSecondaryFilter{
                                attributes[primary.secondaryAttribute] = [secondary.id]
                            }
                        }
                        
                        debugPrint("Searching property")
                        self.sections = try await eluvio.fabric.searchProperty(property: propertyId, attributes: attributes, searchTerm: searchString)
                        return
                    }
                    
                    self.primaryFilters = try await getPrimaryFilters(searchPropertyId: searchPropertyId)
                    
                    if !primaryFilters.isEmpty{
                        currentPrimaryFilter = primaryFilters.first
                        secondaryFilters = currentPrimaryFilter?.secondaryFilters ?? []
                    }
                    
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
                        //debugPrint("currentSecondaryFilter:", currentSecondaryFilter)
                        if let secondary = currentSecondaryFilter{
                            if !secondary.id.isEmpty {
                                attributes[primary.secondaryAttribute] = [secondary.id]
                            }
                        }
                    }
                    
                    //debugPrint("attributes:", attributes)
                    
                    let sections = try await eluvio.fabric.searchProperty(property: searchPropertyId, attributes: attributes, searchTerm: searchString)
                    
                    await MainActor.run {
                        self.sections = []
                        self.sections = sections
                        self.refreshId = UUID().uuidString
                    }
                }catch{
                    print("Could not do search ", error.localizedDescription)
                    //TODO: Send to error screen
                }
            }
        }
    }
    
    var body: some View {
        ScrollView(.vertical){
            VStack(alignment:.leading, spacing:0) {
                SearchBar(searchString:$searchString, logoUrl:logoUrl, name:name, action:{ searchString in
                    search()
                })
                .padding(.top,40)
                .padding(.bottom, searchString.isEmpty ? 20 : 110)
                
                HStack(alignment:.center, spacing: 20) {
                    if ( !primaryFilters.isEmpty) {
                        Text("Filters")
                    }
                    VStack {
                        if !primaryFilters.isEmpty {
                            ScrollView(.horizontal){
                                LazyHStack(alignment:.center, spacing:20){
                                    ForEach(0..<primaryFilters.count, id: \.self) { index in
                                        PrimaryFilterView(
                                            filter:primaryFilters[index],
                                            action:{
                                                if currentPrimaryFilter?.id != primaryFilters[index].id {
                                                    currentPrimaryFilter = primaryFilters[index]
                                                    secondaryFilters = primaryFilters[index].secondaryFilters
                                                }else {
                                                    currentPrimaryFilter = nil
                                                    secondaryFilters = []
                                                }
                                                currentSecondaryFilter = nil
                                                search()

                                            },
                                            selected: currentPrimaryFilter?.id == primaryFilters[index].id
                                        )
                                    }
                                }
                                .frame(maxHeight:.infinity, alignment:.center)
                            }
                            .frame(alignment:.center)
                            .scrollClipDisabled()
                        }
                    }
                }
                .padding([.leading,.trailing], 90)
                .padding([.top], 40)

                if !secondaryFilters.isEmpty {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing:20){
                            ForEach(0..<secondaryFilters.count, id: \.self) { index in
                                SecondaryFilterView(
                                    title: secondaryFilters[index].title,
                                    imageUrl: currentPrimaryFilter?.secondaryFilterStyle == .image ? secondaryFilters[index].imageUrl : "",
                                    action:{
                                        
                                        if currentSecondaryFilter != secondaryFilters[index] {
                                            currentSecondaryFilter = secondaryFilters[index]
                                        }else {
                                            currentSecondaryFilter = nil
                                        }

                                        search()
                                        
                                    },
                                    selected: currentSecondaryFilter == secondaryFilters[index] || currentSecondaryFilter == nil && secondaryFilters[index].id.isEmpty
                                )
                            }
                        }
                    }
                    .padding([.leading], 80)
                    .padding([.top], 10)
                    .scrollClipDisabled()
                }

                
                
                if sections.count == 1{
                    SectionGridView(propertyId: propertyId, pageId: "main", section: sections.first!)
                        .edgesIgnoringSafeArea([.leading,.trailing])
                        .frame(maxWidth:.infinity)
                        .id(refreshId)
                }else {
                    ForEach(sections, id:\.self) {section in
                        VStack{
                            MediaPropertySectionView(propertyId: propertyId, pageId:"main", section: section)
                                .edgesIgnoringSafeArea([.leading,.trailing])
                        }
                        .frame(maxWidth:.infinity)
                        .focusSection()
                    }
                    .id(refreshId)
                }
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .scrollClipDisabled()
        .onAppear(){
            refresh()
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
