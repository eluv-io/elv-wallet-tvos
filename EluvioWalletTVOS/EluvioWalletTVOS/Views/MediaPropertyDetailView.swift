//
//  MediaPropertyDetailView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-14.
//

import SwiftUI
import SDWebImageSwiftUI
import AVFoundation
import SwiftyJSON

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

enum SectionPosition {
    case Left, Right, Center
}

struct MediaPropertySectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    var propertyId: String
    var pageId: String
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
    
    var isBanner: Bool {
        if section.display?["display_format"].stringValue == "banner"  {
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
    
    
    var heroPosition: SectionPosition {
        if let items = section.hero_items?.arrayValue {
            if !items.isEmpty {
                if items[0]["display"]["position"].stringValue == "Left" {
                    return .Left
                }else if items[0]["display"]["position"].stringValue == "Right" {
                    return .Right
                }else if items[0]["display"]["position"].stringValue == "Center" {
                    return .Center
                }
            }
        }
        
        return .Left
    }
    
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
    
    var hAlignment: HorizontalAlignment {
        if let justification = section.display?["justification"].stringValue {
            if justification.lowercased() == "left" {
                return .leading
            }
            if justification.lowercased() == "right" {
                return .trailing
            }
            if justification.lowercased() == "center" {
                return .center
            }
        }
        
        return .leading
    }
    
    var alignment: Alignment {
        if let justification = section.display?["justification"].stringValue {
            if justification.lowercased() == "left" {
                return .leading
            }
            if justification.lowercased() == "right" {
                return .trailing
            }
            if justification.lowercased() == "center" {
                return .center
            }
        }
        
        return .leading
    }
    
    @State var permission : ResolvedPermission? = nil
    var hide : Bool {
        if let permission = self.permission {
            return !permission.authorized && permission.hide
        }
        return false
    }
    
    var disable: Bool {
        if let permission = self.permission {
            return !permission.authorized && permission.disable
        }
        return false
    }
    

    var forceAspectRatio: String {
        if let display = self.section.display {
            return display["aspect_ratio"].stringValue
        }
        
        return ""
    }
    
    var hasBackground : Bool {
        if let background = inlineBackgroundUrl {
            if !background.isEmpty {
                return true
            }
        }
        
        return false
    }
    
    var minHeight : CGFloat {
        if hasBackground{
            return 410
        }
        
        return 300
    }

    var body: some View {
        Group{
            if !hide {
                if isHero {
                    MediaPropertyHeader(logo: heroLogoUrl, title: heroTitle, description: heroDescription, position:heroPosition)
                        .focusable()
                        .padding([.leading,.trailing],margin)
                }else if isBanner {
                    VStack {
                        ForEach(items, id:\.self) { item in
                            
                            MediaPropertyBanner(image:item.getBannerUrl(fabric: eluvio.fabric), action:{
                                debugPrint("Banner clicked item ", item)
                                
                                if item.type == "page_link" {
                                    Task{
                                        do {
                                            debugPrint("Banner clicked page link ")
                                            let sectionId = section.id
                                            let permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: sectionId)
                                            debugPrint("Permission ", permission)
                                            
                                            if let content = section.content {
                                                if let pageId = content[0].page_id {
                                                    if !pageId.isEmpty {
                                                        let url = try eluvio.fabric.createWalletPurchaseUrl(id:section.id, propertyId: propertyId, pageId:pageId, permissionIds: permission.permissionItemIds)
                                                        debugPrint("URL ", url)
                                                        
                                                        var backgroundImage = ""
                                                        
                                                        let property = try await eluvio.fabric.getProperty(property: propertyId)
                                                        
                                                        do {
                                                            backgroundImage = try eluvio.fabric.getUrlFromLink(link: property?.image_tv ?? "")
                                                        }catch{
                                                            //print("Could not create image URL \(error)")
                                                        }
                                                        
                                                        let params = HtmlParams(url:url, backgroundImage: backgroundImage)
                                                        eluvio.pathState.path.append(.html(params))
                                                    }
                                                }
                                            }
                                            
                                        }catch{
                                            print("could not fetch page url for banner ", error.localizedDescription)
                                        }
                                    }
                                }else if item.type == "external_link"{
                                    Task{
                                        debugPrint("Banner clicked external link")
                                        
                                        var backgroundImage = ""
                                        
                                        let property = try await eluvio.fabric.getProperty(property: propertyId)
                                        
                                        do {
                                            backgroundImage = try eluvio.fabric.getUrlFromLink(link: property?.image_tv ?? "")
                                        }catch{
                                            //print("Could not create image URL \(error)")
                                        }
                                        if let url = item.url {
                                            let params = HtmlParams(url:url, backgroundImage: backgroundImage)
                                            eluvio.pathState.path.append(.html(params))
                                        }
                                    }
                                }
                            })
                        }
                    }
                   
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
                        VStack(alignment: hAlignment, spacing: 10)  {
                            HStack(spacing:20){
                                Text(title).font(.rowTitle).foregroundColor(Color.white)
                                if showViewAll {
                                    ViewAllButton(action:{
                                        debugPrint("View All pressed")
                                        eluvio.pathState.section = section
                                        eluvio.pathState.propertyId = propertyId
                                        eluvio.pathState.pageId = pageId
                                        eluvio.pathState.path.append(.sectionViewAll)
                                    })
                                }
                            }
                            .focusSection()
                            .padding(.top, 20)
                            .padding(.bottom, 30)
                            
                            if let content = section.content {
                                if alignment == .center && content.count < 5 {
                                    HStack(alignment: .center, spacing: 20) {
                                        ForEach(content) {item in
                                            SectionItemView(item: item, 
                                                            sectionId: section.id,
                                                            pageId:pageId, 
                                                            propertyId: propertyId,
                                                            forceAspectRatio:forceAspectRatio)
                                                .environmentObject(self.eluvio)
                                        }
                                    }
                                }else{
                                    ScrollView(.horizontal) {
                                        HStack(alignment: .center, spacing: 34) {
                                            ForEach(content) {item in
                                                SectionItemView(item: item,
                                                                sectionId: section.id,
                                                                pageId:pageId,
                                                                propertyId: propertyId,
                                                                forceAspectRatio:forceAspectRatio)
                                                    .environmentObject(self.eluvio)
                                            }
                                        }
                                    }
                                    .scrollClipDisabled()
                                }
                            }
                        }
                        .padding(.bottom,40)
                    }
                    .focusSection()
                    .frame(minHeight:minHeight)
                    .padding([.leading,.trailing],margin)
                    .background(
                        Group {
                            if let url = inlineBackgroundUrl {
                                WebImage(url:URL(string:url))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height:410)
                                    .clipped()
                                    .zIndex(-10)
                                
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight:.infinity)
                    )
                }
            }
        }
        .disabled(disable)
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
            
            Task{
                do {
                    if self.permission == nil {
                        self.permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: section.id)
                    }
                }catch{}
            }
        }
    }
}

struct MediaPropertyDetailView: View {
    @Namespace var NamespaceProperty
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    @State var property: MediaProperty?
    @State var propertyView: MediaPropertyViewModel?
    @State var pageId:String  = "main"
    @State var sections : [MediaPropertySection] = []
    @FocusState var searchFocused
    @FocusState var headerFocused
    @State var playerItem : AVPlayerItem? = nil
    @State var backgroundImage : String = ""
    @State private var opacity: Double = 0.0
    
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
                            //.transition(.opacity)
                            .id("property video \(item.hashValue)")
                        Spacer()
                    }
                    .frame(maxWidth:.infinity, maxHeight:  UIScreen.main.bounds.size.height)
                }else if (backgroundImage.hasPrefix("http")){
                    WebImage(url: URL(string: backgroundImage))
                        .resizable()
                        //.transition(.opacity)
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea([.top,.leading,.trailing])
                        .frame(alignment: .topLeading)
                        .clipped()
                        .id(backgroundImage)
                }else if(backgroundImage != "") {
                    Image(backgroundImage)
                        .resizable()
                        //.transition(.opacity)
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
                            eluvio.pathState.searchParams = SearchParams(propertyId: property?.id ?? "")
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

                VStack(spacing:0) {
                    ForEach(sections) {section in
                        if let propertyId = property?.id {
                            MediaPropertySectionView(propertyId: propertyId, pageId:pageId, section: section)
                                .edgesIgnoringSafeArea([.leading,.trailing])
                        }
                    }
                }
                .prefersDefaultFocus(in: NamespaceProperty)
                .padding(.top, 100)
                
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .edgesIgnoringSafeArea([.top,.leading,.trailing])
        }
        .opacity(opacity)
        .scrollClipDisabled()
        .edgesIgnoringSafeArea(.all)
        .background(
            Color.black.edgesIgnoringSafeArea(.all)
        )
        .onAppear(){
            debugPrint("MediaPropertyDetailView onAppear")
            withAnimation(.easeInOut(duration: 2)) {
              opacity = 1.0
            }
            
            Task {
                do {

                    guard let id = property?.id else {
                        debugPrint("Couldn't get property.id")
                        return
                    }

                    do {
                        if let mediaProperty = try await eluvio.fabric.getProperty(property:id, noCache: true) {
                            debugPrint("Fetched new property ", mediaProperty.id)
                            self.propertyView = await MediaPropertyViewModel.create(mediaProperty:mediaProperty, fabric:eluvio.fabric)
                        }
                    }catch{
                        debugPrint("Could not fetch new property ",error.localizedDescription)
                    }
                    
                    var pageId = self.pageId
                    do {
                        debugPrint("Property title ", property?.title)
                        debugPrint("Property permissions ", property?.permissions)
                        debugPrint("Property authState ", property?.permission_auth_state)
                        debugPrint("Page permissions ", property?.main_page?.permissions)

                        
                        let pagePerms = try await eluvio.fabric.resolvePagePermission(propertyId: id, pageId: pageId)
                        debugPrint("Main Page resolved permissions", pagePerms)
                        
                        if !pagePerms.authorized {
                            if pagePerms.behavior == .showAlternativePage {
                                //pageId = "ppge2T7uwNNeJt1FEZFDyweQNh" //pagePerms.alternatePageId
                                pageId = pagePerms.alternatePageId
                            }else if pagePerms.behavior == .showPurchase {
                                //TODO: Waht to show?
                            }
                        }
                        await MainActor.run {
                            self.pageId = pageId
                        }
                    }catch{
                        print("Could not resolve permissions for property id \(id)", error.localizedDescription)
                    }
                    
                    var sections : [MediaPropertySection] = []
                    do {
                        sections = try await eluvio.fabric.getPropertyPageSections(property: id, page: pageId)
                        debugPrint("finished getting sections. ", sections)
                    }catch{
                        print("Error retrieving property \(id) page \(pageId) ", error.localizedDescription)
                    }


                    var backgroundImageString : String = ""
                    //Finding the hero video to play
                    if !sections.isEmpty{
                        let section = sections[0]
                        if let heros = section.hero_items?.arrayValue {
                            //debugPrint("found heros", heros[0])
                            if !heros.isEmpty{
                                let video = heros[0]["display"]["background_video"]
                                let background = heros[0]["display"]["background_image"]
                                //debugPrint("video: ", video)
                                if !video.isEmpty {
                                    do {
                                        let item = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: video)
                                        await MainActor.run {
                                            //withAnimation(.easeInOut(duration: 1), {
                                                self.playerItem = item
                                                debugPrint("playerItem set")
                                            //})
                                        }
                                    }catch{
                                        debugPrint("Error: ", error.localizedDescription)
                                    }
                                }
                                
                                if !background.isEmpty {
                                    do {
                                        let item = try eluvio.fabric.getUrlFromLink(link: background)
                                        backgroundImageString = item
                                    }catch{
                                        debugPrint("Error: ", error.localizedDescription)
                                    }
                                }
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.sections = sections
                    }
                    
                    await MainActor.run {
                        if self.playerItem == nil && backgroundImageString.isEmpty {
                            //withAnimation(.easeInOut(duration: 1), {
                                self.backgroundImage = propertyView?.backgroundImage ?? ""
                            //})
                        }else if self.playerItem == nil {
                            //withAnimation(.easeInOut(duration: 1), {
                                debugPrint("")
                                self.backgroundImage = backgroundImageString
                            //})
                        }
                    }
                    
                }catch {
                    print("Error retrieving property ", error.localizedDescription)
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
    var position: SectionPosition = .Left
    var horizontalAlignment: HorizontalAlignment {
        if position == .Left {
            return .leading
        }else if position == .Right {
            return .trailing
        }else if position == .Center {
            return .center
        }
        
        return .leading
    }
    
    var alignment: Alignment {
        if position == .Left {
            return .leading
        }else if position == .Right {
            return .trailing
        }else if position == .Center {
            return .center
        }
        
        return .leading
    }
    
    
    var body: some View {
        VStack(alignment: horizontalAlignment, spacing:0) {
            WebImage(url: URL(string: logo))
                .resizable()
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fit)
                .frame(width:890, height:180, alignment: alignment)
                .padding(.bottom,60)
                .clipped()
            
            if !title.isEmpty {
                Text(title).font(.title3)
                    .foregroundColor(Color.white)
                    .fontWeight(.bold)
                    .frame(maxWidth:1100, alignment: alignment)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
            }
            
            if !description.isEmpty {
                Text(description)
                    .foregroundColor(Color.white)
                    .font(.propertyDescription)
                    .frame(maxWidth:1200, alignment: alignment)
                    .frame(minHeight:100)
                    .lineLimit(3)
                    .padding(.bottom, 20)
            }
            //Spacer()

        }
        .frame(maxWidth: UIScreen.main.bounds.size.width,alignment: alignment)
        //.frame(minHeight: 410)
        //.padding(.top, 100)
        .padding(.bottom, 40)
    }
}

struct MediaPropertyBanner: View {
    @Namespace var NamespaceProperty
    @EnvironmentObject var eluvio: EluvioAPI
    var image: String = ""
    var margin: CGFloat = 40
    var action: ()->Void
    @FocusState var isFocused: Bool

    var body: some View {
        if !image.isEmpty {
            Button(action:action, label:{
                HStack(alignment:.center){
                    WebImage(url:URL(string:image))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea(.horizontal)
                        .frame(width: UIScreen.main.bounds.size.width - margin*2)
                        //.frame(maxHeight: height: UIScreen.main.bounds.size.height - margin*2)
                        .padding([.leading, .trailing], margin)
                        .transition(.opacity)

                }
                .focusable()
            })
            .buttonStyle(BannerButtonStyle(focused:isFocused))
            .focused($isFocused)
        }else{
            EmptyView()
        }
    }
}
