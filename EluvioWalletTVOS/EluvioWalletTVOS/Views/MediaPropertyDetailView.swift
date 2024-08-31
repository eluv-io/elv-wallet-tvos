//
//  MediaPropertyDetailView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-14.
//

import SwiftUI
import SDWebImageSwiftUI
import AVFoundation

struct ViewAllButton: View {
    @FocusState var isFocused
    var action: ()->Void
    
    var body: some View {
        Button(action:action, label:{
            Text("VIEW ALL").font(.system(size:24)).bold()
        })
        .buttonStyle(TextButtonStyle(focused:isFocused, bordered:true))
        .focused($isFocused)
    }
}

struct MediaPropertySectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    var propertyId: String
    var section: MediaPropertySection
    let margin: CGFloat = 100
    
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
    
    var isDisplayable: Bool {
        if section.display?["display_format"].stringValue == "carousel" || isHero {
            return true
        }
        
        return false
    }
    
    var isHero: Bool {
        if section.display?["display_format"].stringValue == "hero"  {
            return true
        }
        return false
    }
    
    @State var logoUrl: String? = nil
    var logoText: String {
        if let display = section.display {
            return display["logo_text"].stringValue
        }
        return ""
    }
    
    @State var inlineBackgroundUrl: String? = nil
    @State var playerItem : AVPlayerItem? = nil
    
    var heroLogoUrl: String {
        if let items = section.hero_items?.arrayValue {
            if !items.isEmpty {
                do {
                    return try eluvio.fabric.getUrlFromLink(link: items[0]["display"]["logo"])
                }catch{
                    return ""
                }
            }
        }
        
        return ""
    }
    
    var heroTitle: String {
        if let items = section.hero_items?.arrayValue {
            if !items.isEmpty {
                return items[0]["display"]["title"].stringValue
            }
        }
        return ""
    }
    
    var heroDescription: String {
        if let items = section.hero_items?.arrayValue {
            if !items.isEmpty {
                return items[0]["display"]["description"].stringValue
            }
        }
        return ""
    }


    var body: some View {
        if isHero {
            MediaPropertyHeader(logo: heroLogoUrl, title: heroTitle, description: heroDescription)
                .focusable()
                .padding([.leading,.trailing],margin)
        }else if items.isEmpty{
            EmptyView()
        } else {
            HStack(alignment:.center){
                if let url = logoUrl {
                    VStack(spacing:20) {
                        WebImage(url:URL(string:url))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height:180)
                        Text(logoText)
                            .font(.sectionLogoText)
                    }
                }
                VStack(alignment: .leading, spacing: 10)  {
                    HStack(spacing:20){
                        Text(title).font(.rowTitle).foregroundColor(Color.white)
                        if showViewAll {
                            ViewAllButton(action:{
                                debugPrint("View All pressed")
                                eluvio.pathState.section = section
                                eluvio.pathState.propertyId = propertyId
                                eluvio.pathState.path.append(.sectionViewAll)
                            })
                        }
                    }
                    .focusSection()
                    .padding(.top, 20)
                    .padding(.bottom, 30)

                    
                    ScrollView(.horizontal) {
                        HStack(alignment: .center, spacing: 20) {
                            ForEach(section.content ?? []) {item in
                                if item.type == "item_purchase" {
                                    //Skip for now
                                }else{
                                    SectionItemView(item: item, sectionId: section.id, propertyId: propertyId)
                                            .environmentObject(self.eluvio)
                                }
                            }
                        }
                        .focusSection()
                    }
                    .scrollClipDisabled()
                }
                .padding(.bottom,40)
            }
            .frame(height:402)
            .padding([.leading,.trailing],margin)
            .background(
                Group {
                    if let url = inlineBackgroundUrl {
                        WebImage(url:URL(string:url))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight:402)
                            .frame(height:410)
                            .clipped()
                 
                    }
                }
                .frame(maxWidth: .infinity, maxHeight:402)
                .frame(height:402)
            )
            .onAppear() {
                debugPrint("MediaPropertySectionView onAppear()")
                if let display = section.display {
                    debugPrint("MediaPropertySectionView section ", display["title"])
                    debugPrint("Display format ", section.display?["display_format"].stringValue)
                    
                    do {
                        logoUrl = try eluvio.fabric.getUrlFromLink(link: display["logo"])
                    }catch{}
                    
                    do {
                        inlineBackgroundUrl = try eluvio.fabric.getUrlFromLink(link: display["inline_background_image"])
                    }catch{}
                }
            }
        }
    }
}

struct MediaPropertyDetailView: View {
    @Namespace var NamespaceProperty
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    @State var property: MediaPropertyViewModel
    @State var sections : [MediaPropertySection] = []
    @FocusState var searchFocused
    @FocusState var headerFocused
    @State var playerItem : AVPlayerItem? = nil
    @State var backgroundImage : String = ""
    
    @State var permissions : ResolvedPermission? = nil
    var body: some View {
        ScrollView() {
            ZStack(alignment:.topLeading) {
                if let item = playerItem {
                    VStack{
                        LoopingVideoPlayer([item], endAction: .loop)
                            .frame(maxWidth:.infinity, maxHeight:  UIScreen.main.bounds.size.height)
                            .edgesIgnoringSafeArea([.top,.leading,.trailing])
                            .frame(alignment: .topLeading)
                            .transition(.opacity)
                            .id("property video \(item.hashValue)")
                        Spacer()
                    }
                    .frame(maxWidth:.infinity, maxHeight:  UIScreen.main.bounds.size.height)
                }else if (backgroundImage.hasPrefix("http")){
                    WebImage(url: URL(string: backgroundImage))
                        .resizable()
                        .transition(.opacity)
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea([.top,.leading,.trailing])
                        .frame(alignment: .topLeading)
                        .clipped()
                        .id(backgroundImage)
                }else if(backgroundImage != "") {
                    Image(backgroundImage)
                        .resizable()
                        .transition(.opacity)
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea([.top,.leading,.trailing])
                        .frame(alignment: .topLeading)
                        .clipped()
                        .id(backgroundImage)
                }
                
                HStack(alignment:.top){
                    Spacer()
                    VStack{
                        Button(action:{
                            debugPrint("Search....")
                            eluvio.pathState.searchParams = SearchParams(propertyId: property.id ?? "")
                            eluvio.pathState.path.append(.search)
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
                        
                        Spacer()
                    }
                }
                .focusSection()
                .padding(.trailing, 40)
                .padding(.top, 40)

                VStack() {
                    ForEach(sections) {section in
                        if let propertyId = property.id {
                            MediaPropertySectionView(propertyId: propertyId, section: section)
                                .edgesIgnoringSafeArea([.leading,.trailing])
                        }
                    }
                }
                .padding(.top, 40)
                .prefersDefaultFocus(in: NamespaceProperty)
                
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .edgesIgnoringSafeArea([.top,.leading,.trailing])
        }
        .scrollClipDisabled()
        .edgesIgnoringSafeArea(.all)
        .background(
            Color.black.edgesIgnoringSafeArea(.all)
        )
        .onAppear(){
            debugPrint("MediaPropertyDetailView onAppear")
            
            Task {
                do {
                    guard let id = property.id else {
                        debugPrint("Couldn't get property.id")
                        return
                    }
                    
                    do {
                        let propertyMainPagePermissions = try await eluvio.fabric.resolvePermission(propertyId: id, pageId: "main")
                        debugPrint("Property permissions ", propertyMainPagePermissions)
                        
                        //let mainPagePermissions = try await eluvio.fabric.getPropertyPage(property: <#T##String#>, page: "main")
                    }catch{
                        print("Could not resolve permissions for property id", id)
                    }
                    
                    self.sections = try await eluvio.fabric.getPropertySections(property: id, sections: property.sections)
                    debugPrint("finished getting sections. ", sections.count)
                    
                    //Finding the hero video to play
                    if !sections.isEmpty{
                        let section = sections[0]
                        if let heros = section.hero_items?.arrayValue {
                            debugPrint("found heros", heros[0])
                            if !heros.isEmpty{
                                let video = heros[0]["display"]["background_video"]
                                debugPrint("video: ", video)
                                if !video.isEmpty {
                                    do {
                                        let item = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: video)
                                        //withAnimation(.easeInOut(duration: 1), {
                                        await MainActor.run{
                                            self.playerItem = item
                                            debugPrint("playerItem set")
                                        }
                                        //})
                                    }catch{
                                        debugPrint("Error: ", error.localizedDescription)
                                    }
                                }
                            }
                        }
                    }
                    
                    if self.playerItem == nil {
                        await MainActor.run{
                            //withAnimation(.easeInOut(duration: 1), {
                                //backgroundImage = property.backgroundImage
                            //})
                        }
                    }
                    
                }catch {
                    print("Error getting property sections ", error.localizedDescription)
                }
            }
        }
    }
}


struct MediaPropertyHeader: View {
    @Namespace var NamespaceProperty
    @EnvironmentObject var eluvio: EluvioAPI
    var logo: String = ""
    var title: String = ""
    var description: String = ""

    var body: some View {
        VStack(alignment:.leading, spacing: 10) {

            WebImage(url: URL(string: logo))
                .resizable()
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fit)
                .frame(width:840, height:180, alignment: .leading)
                .padding(.bottom,40)
                .clipped()
            
            Text(title).font(.title3)
                .foregroundColor(Color.white)
                .fontWeight(.bold)
                .frame(maxWidth:1020, alignment:.leading)
                .padding(.top, 20)
            
            Text(description)
                .foregroundColor(Color.white)
                .font(.propertyDescription)
                .frame(maxWidth:1020, alignment:.leading)
                .lineLimit(3)
                .padding(.top, 20)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
        .padding(.bottom, 60)
    }
}
