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
        .opacity(isFocused ? 1.0 : 0.6)
    }
}

enum SectionPosition {
    case Left, Right, Center
}

extension View {
    func getWidth(_ width: Binding<CGFloat>) -> some View {
        modifier(GetWidthModifier(width: width))
    }
}

struct GetWidthModifier: ViewModifier {
    @Binding var width: CGFloat
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    let proxyWidth = proxy.size.width
                    Color.clear
                        .task(id: proxy.size.width) {
                            $width.wrappedValue = max(proxyWidth, 0)
                        }
                }
            )
    }
}

struct MediaPropertySectionGridView: View {
    @Namespace var NamespaceProperty
    @EnvironmentObject var eluvio: EluvioAPI
    var propertyId: String
    var pageId: String
    var section: MediaPropertySection
    var margin: CGFloat = 80
    @State var logoUrl: String? = nil
    var logoText: String {
        if let display = section.display {
            return display["logo_text"].stringValue
        }
        return ""
    }
    @State var inlineBackgroundUrl: String? = nil

    

    
    var body: some View {
        HStack(spacing:0){
            if let url = logoUrl {
                VStack(spacing:20) {
                    WebImage(url:URL(string:url))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height:180)
                    Text(logoText)
                        .font(.sectionLogoText)
                }
                .padding(.leading, margin)
            }
            
            SectionGridView(propertyId:propertyId, pageId:pageId, section:section, margin:margin, forceDisplay: .video)
            
            .padding()
        }
        .background(
            Group {
                if let url = inlineBackgroundUrl {
                    WebImage(url:URL(string:url))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .zIndex(-10)
                }
            }
            .frame(maxWidth: .infinity)
        )
        .clipped()
        .frame(maxWidth:.infinity, maxHeight: .infinity)
        .task{
            if let display = section.display {
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

struct MediaPropertyRegularSectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    var propertyId: String
    var pageId: String
    var section: MediaPropertySection
    var margin: CGFloat = 80
    
    @State var items: [MediaPropertySectionMediaItemViewModel] = []
    
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
        if section.display?["display_format"].stringValue == "carousel"{
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
            return 400
        }
        
        return 380
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
    var forceAspectRatio: String {
        if let display = self.section.display {
            return display["aspect_ratio"].stringValue
        }
        
        return ""
    }

    
    var body: some View {
        HStack(alignment:.center){
                if items.isEmpty {
                    EmptyView()
                }else {
                    if let url = logoUrl {
                        VStack(spacing:20) {
                            WebImage(url:URL(string:url))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 180, height:180)
                            Text(logoText)
                                .font(.sectionLogoText)
                        }
                        .padding(.trailing, 20)
                    }
                        
                    VStack(alignment: hAlignment, spacing: 0)  {
                        HStack(alignment:.bottom, spacing:30){
                            if !title.isEmpty {
                                Text(title).font(.rowTitle).foregroundColor(Color.white)
                                    .padding(0)
                            }
                            if showViewAll {
                                ViewAllButton(action:{
                                    debugPrint("View All pressed")
                                    eluvio.pathState.section = section
                                    eluvio.pathState.propertyId = propertyId
                                    eluvio.pathState.pageId = pageId
                                    eluvio.pathState.path.append(.sectionViewAll)
                                })
                                .padding(0)
                            }
                        }
                        .focusSection()
                        .padding(.top, 30)
                        .padding(.bottom, 10)
                        .padding(.leading, 10)
                        
                        if alignment == .center && items.count < 5 {
                            HStack(alignment: .top, spacing: 20) {
                                ForEach(items) {item in
                                    SectionItemView(item: item.sectionItem,
                                                    sectionId: section.id,
                                                    pageId:pageId,
                                                    propertyId: propertyId,
                                                    forceAspectRatio:forceAspectRatio,
                                                    viewItem: item
                                    )
                                    .environmentObject(self.eluvio)
                                }
                            }
                            .padding([.top,.bottom],20)
                            .padding(.leading, 10)
                            .padding(.trailing, 0)
                        }else{
                            ScrollView(.horizontal) {
                                HStack(alignment: .center, spacing: 34) {
                                    ForEach(items) {item in
                                        SectionItemView(item: item.sectionItem,
                                                        sectionId: section.id,
                                                        pageId:pageId,
                                                        propertyId: propertyId,
                                                        forceAspectRatio:forceAspectRatio,
                                                        viewItem: item
                                        )
                                        .fixedSize()
                                        .padding(.top,0)
                                        .environmentObject(self.eluvio)
                                        
                                    }
                                }
                                .padding([.top,.bottom],20)
                                .padding(.leading, 10)
                                .padding(.trailing, 0)
                            }
                            .frame(maxWidth:.infinity)
                            .edgesIgnoringSafeArea(.trailing)
                        }
                    }
            }
        }
        .focusSection()
        .padding([.leading],margin)
        .padding(.bottom,40)
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
        .clipped()
        .task() {
            debugPrint("MediaPropertyRegularSectionView onAppear()")
            if let display = section.display {
                do {
                    logoUrl = try eluvio.fabric.getUrlFromLink(link: display["logo"])
                }catch{}
                
                do {
                    inlineBackgroundUrl = try eluvio.fabric.getUrlFromLink(link: display["inline_background_image"])
                }catch{}
            }
            
            Task {
                var sectionItems : [MediaPropertySectionMediaItemViewModel] = []
                let max = 25
                var count = 0
                if let content = section.content {
                    for var item in content {
                        let permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: section.id, sectionItemId: item.id ?? "")
                        item.resolvedPermission = permission
                        
                        let mediaPermission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: section.id, sectionItemId: item.id ?? "", mediaItemId: item.media_id ?? "")
                        item.media?.resolvedPermission = mediaPermission
                        if content.count == 1 {
                            debugPrint("permission: ", permission)
                            debugPrint("media permission: ", mediaPermission)
                            debugPrint("SectionItemTitle ", item.media?.title)
                            debugPrint("SectionItem Type ", item.type)
                            debugPrint("SectionItem Media Type ", item.media_type)
                            debugPrint("SectionItem Media Display ", item.display)
                            debugPrint("SectionItem Id ", item.id)
                            debugPrint("SectionItem Media Id ", item.media?.id)
                            debugPrint("SectionItem item media", item)
                        }
                        
                        if !permission.hide && !mediaPermission.hide{
                            let viewItem = MediaPropertySectionMediaItemViewModel.create(item: item, fabric: eluvio.fabric)
                            sectionItems.append(viewItem)
                            debugPrint("added item")
                        }
                        count += 1
                        if count == max {
                            break
                        }
                    }
                }
                self.items = sectionItems
            }
        }
    }
}

struct MediaPropertySectionBannerView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    var propertyId: String
    var pageId: String
    @State var section: MediaPropertySection
    var items: [MediaPropertySectionItem] {
        section.content ?? []
    }
    
    var body: some View {
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
                            
                            do {
                                let property = try await eluvio.fabric.getProperty(property: propertyId)
                                
                                
                                backgroundImage = try eluvio.fabric.getUrlFromLink(link: property?.image_tv ?? "")
                            }catch(FabricError.apiError(let code, let response, let error)){
                                eluvio.handleApiError(code: code, response: response, error: error)
                            }catch {
                                //eluvio.pathState.path.append(.errorView("A problem occured."))
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
    }
}

struct MediaPropertySectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    var propertyId: String
    var pageId: String
    @State var section: MediaPropertySection
    var margin: CGFloat = 100

    var items: [MediaPropertySectionItem] {
        section.content ?? []
    }
    
    @State var subsections : [MediaPropertySection] = []
    
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
    
    var isContainer: Bool {
        if let type = section.type {
            return type.lowercased() == "container"
        }
        return false
    }
    
    var isGrid: Bool {
        if section.display?["display_format"].stringValue == "grid"  {
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
            return 420
        }
        
        return 400
    }
    
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

    var body: some View {
        Group{
            if !hide {
                if isHero {
                    MediaPropertyHeader(logo: heroLogoUrl, title: heroTitle, description: heroDescription, position:heroPosition)
                        //.focusable()

                }else if isBanner {
                    MediaPropertySectionBannerView(propertyId:propertyId, pageId:pageId, section:section)
                        //.padding([.leading,.trailing],margin)
                        //.padding(.top,40)
                    
                }else if isContainer{
                    VStack(spacing:0){
                        ForEach(subsections) { sub in
                            MediaPropertyRegularSectionView(propertyId:propertyId, pageId: pageId, section: sub)
                                //.frame(minHeight:minHeight)
                        }
                    }
                }else if isGrid {
                    MediaPropertySectionGridView(propertyId:propertyId, pageId:pageId, section:section)
                }else if !items.isEmpty {
                    MediaPropertyRegularSectionView(
                        propertyId:propertyId,
                        pageId: pageId,
                        section:section
                        )
                     
                }else {
                    EmptyView()
                }
            }
        }
        .disabled(disable)
        .task() {
            debugPrint("MediaPropertySectionView onAppear() type:", section.type)
            debugPrint("Subsections count ", section.sections?.count)

            Task{
                do {
                    
                    if section.resolvedPermission == nil {
                        self.permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: section.id)
                        section.resolvedPermission = self.permission
                    }else {
                        self.permission = section.resolvedPermission
                    }
                }catch{
                    self.permission = section.resolvedPermission
                }
            }
            

            Task{
                do {
                
                    var sections : [String] = []
                    if let sects = section.sections{
                        for sub in sects{
                            sections.append(sub)
                        }

                        debugPrint("Fething subsections count ", sections.count)
                        if !sections.isEmpty {
                            
                            let result = try await eluvio.fabric.getPropertySections(property: propertyId, sections: sections)
                            await MainActor.run {
                                self.subsections = result
                                debugPrint("finished getting sub sections. ")
                            }
                        }
                    }
                }catch(FabricError.apiError(let code, let response, let error)){
                    eluvio.handleApiError(code: code, response: response, error: error)
                }catch {
                    //eluvio.pathState.path.append(.errorView("A problem occured."))
                    debugPrint("Error:",error.localizedDescription)
                }
            }

        }
    }
}

struct MediaPropertyDetailView: View {
    @Namespace var NamespaceProperty
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    
    @State private var property: MediaProperty?
    @State private var propertyView: MediaPropertyViewModel?
    var propertyId:String
    @State var pageId:String  = "main"
    @State var sections : [MediaPropertySection] = []
    @FocusState var searchFocused
    @FocusState var headerFocused
    @State var playerItem : AVPlayerItem? = nil
    @State var backgroundImage : String = ""
    @State private var opacity: Double = 0.0
    @State var isRefreshing = false
    @State var permissions : ResolvedPermission? = nil
    @State private var refreshId = UUID().uuidString
    
    var body: some View {
        ScrollView() {
            ZStack(alignment:.topLeading) {
                if let item = playerItem {
                    VStack{
                        LoopingVideoPlayer([item], endAction: .loop)
                            .frame(maxWidth:.infinity, maxHeight:  UIScreen.main.bounds.size.height)
                            .edgesIgnoringSafeArea([.top,.leading,.trailing])
                            .frame(alignment: .topLeading)
                            .id("property video \(item.hashValue)")
                        Spacer()
                    }
                    .frame(maxWidth:.infinity, maxHeight:  UIScreen.main.bounds.size.height)
                }else if (backgroundImage.hasPrefix("http")){
                    WebImage(url: URL(string: backgroundImage))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea([.top,.leading,.trailing])
                        .frame(width:UIScreen.main.bounds.size.width,
                               height: UIScreen.main.bounds.size.height, alignment: .topLeading)
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
                                
                VStack(spacing:0) {
                    ForEach(sections) {section in
                        if let propertyId = property?.id {
                            MediaPropertySectionView(propertyId: propertyId, pageId:pageId, section: section)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(0)
                        }
                    }
                }
                .prefersDefaultFocus(in: NamespaceProperty)
                .id(refreshId)
                
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
                .zIndex(20)
                .focusSection()
                .padding(.trailing, 40)
                .padding(.top, 40)
                .frame(maxWidth:.infinity, maxHeight:120)
                
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .opacity(opacity)
        .scrollClipDisabled()
        .edgesIgnoringSafeArea(.all)
        .background(
            Color.black.edgesIgnoringSafeArea(.all)
        )
        .task {
            debugPrint("MediaPropertyDetailView onAppear")
            refresh()
        }
        .onWillDisappear {
            withAnimation(.easeInOut(duration: 2)) {
              opacity = 0.0
            }
        }
    }
    
    
    
    func refresh(){
        debugPrint("MediaPropertyDetailView refresh() propertyId: ",propertyId)
        debugPrint("MediaPropertyDetailView refresh() page: ",pageId)
        if self.isRefreshing{
            debugPrint("still refreshing..exiting")
            return
        }
        
        playerItem = nil
        backgroundImage = ""
        self.isRefreshing = true
        
        if propertyId.isEmpty {
            print("Error: propertyId is empty")
            return
        }
        
        /*
        Task {
            withAnimation(.easeInOut(duration: 2)) {
              opacity = 1.0
            }
        }
         */
        
        Task {
            defer {
                self.isRefreshing = false
                self.refreshId = eluvio.refreshId
                
                withAnimation(.easeInOut(duration: 2)) {
                  opacity = 1.0
                }
            }
            do {
                if let mediaProperty = try await eluvio.fabric.getProperty(property:propertyId, newFetch:true) {
                    debugPrint("Fetched new property ", mediaProperty.id)
                    self.propertyView = await MediaPropertyViewModel.create(mediaProperty:mediaProperty, fabric:eluvio.fabric)
                    await MainActor.run {
                        self.property = nil
                        self.property = mediaProperty
                        debugPrint("Property title inside mainactor", mediaProperty.title)
                    }
                }else{
                    debugPrint("Could not find property")
                    return
                }
            }catch{
                debugPrint("Could not fetch property ",error.localizedDescription)
                return
            }
            
            var altPageId = self.pageId
            do {
                debugPrint("Property title ", property?.title)
                debugPrint("Property permissions ", property?.permissions)
                debugPrint("Property authState ", property?.permission_auth_state)
                debugPrint("Page permissions ", property?.main_page?.permissions)
                
                var pagePerms = try await eluvio.fabric.resolvePagePermission(propertyId: propertyId, pageId: altPageId)
                debugPrint("Main Page resolved permissions", pagePerms)
                if !pagePerms.authorized {
                    if pagePerms.behavior == .showAlternativePage {
                        self.pageId = pagePerms.alternatePageId
                        debugPrint("Alternate pageId ", pagePerms.alternatePageId)
                        debugPrint("Setting pageId ", pageId)
                        altPageId = pagePerms.alternatePageId
                        
                        pagePerms = try await eluvio.fabric.resolvePagePermission(propertyId: propertyId, pageId: altPageId)
                        if !pagePerms.authorized {
                            if pagePerms.behavior == .showAlternativePage {
                                self.pageId = pagePerms.alternatePageId
                                altPageId = pagePerms.alternatePageId
                            }
                        }
                        
                    }else if pagePerms.behavior == .showPurchase {
                        //TODO: Waht to show?
                    }
                }
            }catch{
                print("Could not resolve permissions for property id \(propertyId)", error.localizedDescription)
            }

            do {
                sections = try await eluvio.fabric.getPropertyPageSections(property: propertyId, page: altPageId, newFetch:true)
                debugPrint("finished getting sections. ", sections.count)
                for sect in sections {
                    debugPrint("section \(sect.displayTitle) type: ", sect.type)
                }
            }catch(FabricError.apiError(let code, let response, let error)){
                eluvio.handleApiError(code: code, response: response, error: error)
            }catch {
                //eluvio.pathState.path.append(.errorView("A problem occured."))
                debugPrint("Error:",error.localizedDescription)
            }

            var backgroundImageString : String = ""
            //Finding the hero video to play
            if !sections.isEmpty{
                var section = sections[0]
            
                if let heros = section.hero_items?.arrayValue {
                    //debugPrint("found heros", heros[0])
                    if !heros.isEmpty{
                        let video = heros[0]["display"]["background_video"]
                        let background = heros[0]["display"]["background_image"]
                        //debugPrint("video: ", video)
                        if !video.isEmpty && self.playerItem == nil{
                            do {
                                let item = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: video)
                                await MainActor.run {
                                    self.playerItem = item
                                    debugPrint("playerItem set")
                                }
                            }catch{
                                debugPrint("Error making video item: ", error.localizedDescription)
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
                if self.playerItem == nil && backgroundImageString.isEmpty {
                    self.backgroundImage = propertyView?.backgroundImage ?? ""
                }else if self.playerItem == nil {
                    debugPrint("")
                    self.backgroundImage = backgroundImageString
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
    
    var hasOnlyImage : Bool {
        return !logo.isEmpty && title.isEmpty && description.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing:0) {
            WebImage(url: URL(string: logo))
                .resizable()
                .scaledToFit()
                .frame(height:180, alignment: alignment)
                //.frame(maxWidth:.infinity)
                //.clipped()

            if !title.isEmpty {
                Text(title).font(.title3)
                    .foregroundColor(Color.white)
                    .fontWeight(.bold)
                    .frame(maxWidth:1100, alignment: alignment)
                    .padding(.top, 60)
            }
            
            if !description.isEmpty {
                Text(description)
                    .foregroundColor(Color.white)
                    .font(.propertyDescription)
                    .frame(width:1200, alignment: alignment)
                    .frame(minHeight:130)
                    .lineLimit(4)
                    .padding(.top, 30)
            }

        }
        .frame(maxWidth: .infinity, alignment:.leading)
        .padding([.leading, .trailing], 80)
        .padding([.bottom], 40)
        .padding([.top], hasOnlyImage ? 40 : 100)
        .onAppear(){
            debugPrint("Description text : ", description)
        }

    }
}

struct MediaPropertyBanner: View {
    @Namespace var NamespaceProperty
    @EnvironmentObject var eluvio: EluvioAPI
    var image: String = ""
    var margin: CGFloat = 80
    var action: ()->Void
    @FocusState var isFocused: Bool
    @State var opacity : CGFloat = 0
    var body: some View {
        if !image.isEmpty {
            Button(action:action, label:{
                HStack(alignment:.center){
                    WebImage(url:URL(string:image))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea(.horizontal)
                        .frame(maxWidth:.infinity)
                        .transition(.opacity)

                }
                .padding([.leading, .trailing], margin)
                .padding([.top, .bottom], 40)
            })
            .opacity(opacity)
            .clipped()
            .frame(maxWidth: .infinity, alignment:.leading)
            .buttonStyle(BannerButtonStyle(focused:isFocused, bordered: true))
            .focused($isFocused)
            .task{
                do{
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                }catch{}
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 3)) {
                        self.opacity = 1.0
                    }
                }
            }
        }else{
            EmptyView()
        }
    }
}
