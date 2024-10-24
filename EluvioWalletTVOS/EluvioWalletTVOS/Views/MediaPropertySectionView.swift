//
//  MediaPropertySectionView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-10-24.
//

import SwiftUI
import SDWebImageSwiftUI
import AVFoundation
import SwiftyJSON
import Foundation


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
            
            SectionGridView(propertyId:propertyId, pageId:pageId, section:section, margin:margin)
            
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
            debugPrint("MediaPropertyRegularSectionView onAppear() ", section.displayTitle)
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
                if let content = section.content {
                    
                    for var item in content {
                            var mediaPermission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: section.id, sectionItemId: item.id ?? "", mediaItemId: item.media_id ?? "")
                            
                            item.media?.resolvedPermission = mediaPermission
                            item.resolvedPermission = mediaPermission
                            
                            if !mediaPermission.hide {
                                let viewItem = MediaPropertySectionMediaItemViewModel.create(item: item, fabric: eluvio.fabric)
                                sectionItems.append(viewItem)
                            }
                    }

                }
                self.items = sectionItems
            }
        }
    }
    
    //This doesn't seem to be faster, actually messes up the selection since the loading is not in order
    /*
    func process(content: [MediaPropertySectionItem]) async -> [MediaPropertySectionMediaItemViewModel] {
        let max = 25
        var count = 0
        var sectionItems: [MediaPropertySectionMediaItemViewModel] = []
        do {
             sectionItems = try await withThrowingTaskGroup(of: MediaPropertySectionMediaItemViewModel?.self ) {group -> [MediaPropertySectionMediaItemViewModel] in
                
                for var item in content {
                    group.addTask {
                        debugPrint("item id ", item.id)
                        var mediaPermission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: section.id, sectionItemId: item.id ?? "", mediaItemId: item.media_id ?? "")
                        
                        item.media?.resolvedPermission = mediaPermission
                        item.resolvedPermission = mediaPermission
                        
                        if !mediaPermission.hide {
                            let viewItem = await MediaPropertySectionMediaItemViewModel.create(item: item, fabric: eluvio.fabric)
                            return viewItem
                        }
                        
                        return nil
                    }
                    
                    count += 1
                    if count == max {
                        break
                    }
                }
                
                var items : [MediaPropertySectionMediaItemViewModel] = []
                
                
                for try await value in group {
                    if let val = value {
                        items.append(val)
                    }
                }
                
                return items
            }
        }catch{}
        
        return sectionItems
    }
     */
}

struct MediaPropertySectionBannerView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    var propertyId: String
    var pageId: String
    var margin: CGFloat = 80
    @State var section: MediaPropertySection
    var items: [MediaPropertySectionItem] {
        section.content ?? []
    }
    
    var body: some View {
        VStack {
            ForEach(items, id:\.self) { item in
                MediaPropertyBanner(image:item.getBannerUrl(fabric: eluvio.fabric), margin:margin, action:{
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
    var margin: CGFloat = 80

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
                    MediaPropertyHeader(logo: heroLogoUrl, title: heroTitle, description: heroDescription, position:heroPosition, margin:margin)
                }else if isBanner {
                    MediaPropertySectionBannerView(propertyId:propertyId, pageId:pageId, margin:margin, section:section)
                }else if isContainer{
                    VStack(spacing:0){
                        ForEach(subsections) { sub in
                            MediaPropertyRegularSectionView(propertyId:propertyId, pageId: pageId, section: sub, margin:margin)
                        }
                    }
                }else if isGrid {
                    MediaPropertySectionGridView(propertyId:propertyId, pageId:pageId, section:section, margin:margin)
                }else if !items.isEmpty {
                    MediaPropertyRegularSectionView(
                            propertyId:propertyId,
                            pageId: pageId,
                            section:section,
                            margin:margin
                        )
                     
                }else {
                    EmptyView()
                }
            }
        }
        .disabled(disable)
        .focusSection()
        .task() {
            //debugPrint("MediaPropertySectionView onAppear() type:", section.type)
            //debugPrint("Subsections count ", section.sections?.count)

            
            if section.type != "search" {
                Task(priority: .background){
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
            }

            Task(priority: .background){
                do {
                    
                    if section.type != "search" {
                        print("Fetching section \(section.id)")
                        let result = try await eluvio.fabric.getPropertySections(property: propertyId, sections:[section.id], newFetch: true)
                        if result.count == 0 {
                            print("Could not fetch section \(section.id)")
                            return
                        }
                        
                        
                        self.section = result[0]
                    }

                    //looking for subsections
                    var sections : [String] = []
                    if let sects = section.sections{
                        for sub in sects{
                            sections.append(sub)
                        }

                        debugPrint("Fetching subsections count ", sections.count)
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


struct MediaPropertyHeader: View {
    @Namespace var NamespaceProperty
    @EnvironmentObject var eluvio: EluvioAPI
    var logo: String = ""
    var title: String = ""
    var description: String = ""
    var position: SectionPosition = .Left
    var margin: CGFloat = 80
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
        .padding([.leading, .trailing], margin + 15)  //FIXME: there's a padding in the other sections for some reason
        .padding([.bottom], hasOnlyImage ? 10 : 40)
        .padding([.top], hasOnlyImage ? 10 : 100)
        .onAppear(){
            debugPrint("MediaPropertyHeader Description text : ", description)
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
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 1)) {
                        self.opacity = 1.0
                    }
                }
            }
        }else{
            EmptyView()
        }
    }
}
