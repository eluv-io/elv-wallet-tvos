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

struct SearchBar: View {
    @Binding var searchString : String
    var logoUrl = ""
    var logo = "e_logo"
    var name = ""
    var action: (String)->Void
    
    var body: some View {
        VStack(alignment:.center){
            HStack(alignment:.center, spacing:40){
                if !logoUrl.isEmpty {
                    WebImage(url:URL(string:logoUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height:100)
                }else if !logo.isEmpty{
                    Image(logo)
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
                                action(searchString)
                            }
                    }
                    Divider().overlay(Color.gray)
                }
            }
        }
        .padding(.top,20)
        .padding([.leading,.trailing], 80)
        .focusSection()
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
                    
                    
                    self.sections = try await eluvio.fabric.searchProperty(property: propertyId, attributes: attributes, searchTerm: searchString)
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
                .padding(.top,40)
                
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
                        .padding(.top,20)
                        .padding([.leading,.trailing], 80)
                }else {
                    ForEach(sections) {section in
                        VStack{
                            MediaPropertySectionView(propertyId: propertyId, pageId:"main", section: section)
                                .edgesIgnoringSafeArea([.leading,.trailing])
                        }
                        .frame(maxWidth:.infinity)
                        .focusSection()
                    }
                }
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .scrollClipDisabled()
        .onAppear(){
            Task {
                if !propertyId.isEmpty {
                    do {
                        debugPrint("Search onAppear()")
                        let property = try await eluvio.fabric.getProperty(property: propertyId)
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
                        
                        if !primaryAttribute.isEmpty {
                            debugPrint("Found primary attribute ",primaryAttribute)
                            var tags = primaryAttribute["tags"].arrayValue
                            let options = filterResult["filter_options"].arrayValue
                            
                            if !tags.isEmpty {
                                var newPrimaryFilters : [PrimaryFilterViewModel] = []
                                //tags.insert("", at:0)
                                let secondary : [String] = attributes[secondaryFilterValue]["tags"].arrayValue.map {$0.stringValue}
                                var allPrimaryFilter = PrimaryFilterViewModel(id: "",
                                                                              imageURL: "",
                                                                              secondaryFilters: secondary,
                                                                              attribute:primaryFilterValue,
                                                                              secondaryAttribute: secondaryFilterValue)
                                var foundAllPrimary = false
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
                                    currentPrimaryFilter = allPrimaryFilter
                                }else {
                                    currentPrimaryFilter = newPrimaryFilters.first
                                }
                                self.primaryFilters = newPrimaryFilters
                            }
                        
                            
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
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
