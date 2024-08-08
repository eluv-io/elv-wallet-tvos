//
//  MediaPropertyDetailView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-14.
//

import SwiftUI
import SDWebImageSwiftUI

struct ViewAllButton: View {
    @FocusState var isFocused
    var action: ()->Void
    
    var body: some View {
        Button(action:action, label:{
            Text("VIEW ALL")
        })
        .buttonStyle(TextButtonStyle(focused:isFocused, bordered:true))
        .focused($isFocused)
    }
}

struct MediaPropertySectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var pathState: PathState
    @EnvironmentObject var viewState: ViewState
    var propertyId: String
    var section: MediaPropertySection
    
    var items: [MediaPropertySectionItem] {
        section.content ?? []
    }
    
    var showViewAll: Bool {
        if let sectionItems = section.content {
            if sectionItems.count > 5 || (sectionItems.count > section.displayLimit && section.displayLimit > 0)  {
                return true
            }
        }
        
        return false
    }
    
    var title: String {
        if let display = section.display {
            return display["title"].stringValue
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10)  {
            if !title.isEmpty {
                HStack{
                    Text(title).font(.rowTitle).foregroundColor(Color.white)
                    if showViewAll {
                        ViewAllButton(action:{
                            debugPrint("View All pressed")
                            pathState.section = section
                            pathState.propertyId = propertyId
                            pathState.path.append(.sectionViewAll)
                        })
                    }
                }
                .padding(.bottom, 20)
                .focusSection()
            }
            
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 50) {
                    ForEach(section.content ?? []) {item in
                        if item.type == "item_purchase" {
                            //Skip for now
                        }else{
                            SectionItemView(item: item, propertyId: propertyId)
                                .environmentObject(self.pathState)
                                .environmentObject(self.fabric)
                                .environmentObject(self.viewState)
                        }
                    }
                }
            }
            .scrollClipDisabled()
            
        }
        .padding(.top)
    }
}

struct MediaPropertyDetailView: View {
    @Namespace var NamespaceProperty
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var pathState: PathState
    @EnvironmentObject var viewState: ViewState
    var property: MediaPropertyViewModel
    @State var sections : [MediaPropertySection] = []
    @FocusState var searchFocused
    @FocusState var headerFocused
    
    var body: some View {
        ScrollView() {
            VStack(alignment:.leading) {
                HStack(alignment:.top){
                    MediaPropertyHeader(logo: property.logo, title: property.logoAlt, description: property.description, descriptionRichText: property.descriptionRichText)
                        .prefersDefaultFocus(in: NamespaceProperty)
                        .focusable()
                    
                    Button(action:{
                        debugPrint("Search....")
                        pathState.searchParams = SearchParams(propertyId: property.id ?? "")
                        pathState.path.append(.search)
                    }){
                        HStack(){
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .frame(width:40, height:40)
                                .padding()
                        }
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                    }
                    .buttonStyle(IconButtonStyle(focused: searchFocused, initialOpacity: 0.7, scale: 1.2))
                    .focused($searchFocused)
                }
                .focusSection()
                
                ForEach(sections) {section in
                    if let propertyId = property.id {
                        MediaPropertySectionView(propertyId: propertyId, section: section)
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)
        }
        .scrollClipDisabled()
        .background(
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                if (property.backgroundImage.hasPrefix("http")){
                    WebImage(url: URL(string: property.backgroundImage))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth:.infinity, maxHeight:.infinity)
                        .frame(alignment: .topLeading)
                        .clipped()
                }else if(property.backgroundImage != "") {
                    Image(property.backgroundImage)
                        .resizable()
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth:.infinity, maxHeight:.infinity)
                        .frame(alignment: .topLeading)
                        .clipped()
                }
            }
            .edgesIgnoringSafeArea(.all)
        )
        .onAppear(){
            debugPrint("MediaPropertyDetailView onAppear")
            
            Task {
                do {
                    guard let id = property.id else {
                        return
                    }
                    self.sections = try await  fabric.getPropertySections(property: id, sections: property.sections)
                    //let sectionsJSON = try await fabric.getPropertySectionsJSON(property: id, sections: property.sections)
                    //debugPrint("Sections ", sectionsJSON)
                }catch {
                    print("Error getting property sections ", error.localizedDescription)
                }
            }
        }
    }
}


struct MediaPropertyHeader: View {
    @Namespace var NamespaceProperty
    @EnvironmentObject var fabric: Fabric
    var logo: String = ""
    var title: String = ""
    var description: String = ""
    var descriptionRichText: AttributedString = ""

    var body: some View {
        VStack(alignment:.leading, spacing: 10) {
            if (logo.isEmpty) {
                Text(title).font(.title3)
                    .foregroundColor(Color.white)
                    .fontWeight(.bold)
                    .frame(maxWidth:1500, alignment:.leading)
            }else{
                WebImage(url: URL(string: logo))
                    .resizable()
                    .transition(.fade(duration: 0.5))
                    .aspectRatio(contentMode: .fit)
                    .frame(width:800, height:400, alignment: .leading)
                    .clipped()
            }
                        
            if (!description.isEmpty) {
                Text(description)
                    .foregroundColor(Color.white)
                    //.padding(.top)
                    .font(.propertyDescription)
                    .frame(maxWidth:1200, alignment:.leading)
                    .lineLimit(3)
            }else {
                Text(self.descriptionRichText)
                .foregroundColor(Color.white)
                //.padding(.top)
                .font(.propertyDescription)
                .frame(maxWidth:1200, alignment:.leading)
                .lineLimit(10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }
}
