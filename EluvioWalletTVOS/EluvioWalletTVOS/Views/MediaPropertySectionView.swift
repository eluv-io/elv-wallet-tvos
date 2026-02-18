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
                            debugPrint("Width: ", proxyWidth)
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
    @State private var refreshId = ""
    var useScale = false
    
    var logoText: String {
        if let display = section.display {
            return display["logo_text"].stringValue
        }
        return ""
    }
    //@State var inlineBackgroundUrl: String? = nil

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
            
            SectionGridView(propertyId:propertyId, pageId:pageId, section:section, margin:margin, useScale: useScale, showBackground: false)
        }
        /*
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
         */
        .clipped()
        .frame(maxWidth:.infinity, maxHeight: .infinity)
        .onAppear(){
            if self.refreshId == eluvio.refreshId {
                return
            }
            
            self.refreshId = eluvio.refreshId
            
            if let display = section.display {
                do {
                    logoUrl = try eluvio.fabric.getUrlFromLink(link: display["logo"])
                    
                }catch{}
                
                /*
                do {
                    inlineBackgroundUrl = try eluvio.fabric.getUrlFromLink(link: display["inline_background_image"])
                }catch{}
                 */
            }
            
        }
    }
}

struct MediaPropertyRegularSectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    @Namespace var SectionNamespace
    var propertyId: String
    var pageId: String
    var section: MediaPropertySection
    var margin: CGFloat = 80
    @State private var refreshId = ""
    @State var items: [MediaPropertySectionMediaItemViewModel] = []
    @FocusState private var currentFocusItem: MediaPropertySectionMediaItemViewModel?
    @State private var lastFocusItem: MediaPropertySectionMediaItemViewModel?
    var useScale = false
    var scaleFactor: CGFloat = 0.7
    var lookForBackground = false
    
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
    
    var titleIcon: String {
        if let display = section.display {
            do {
                
                let icon = try eluvio.fabric.getUrlFromLink(link: display["title_icon"])
                return icon
            }catch{
                //print("error ", error)
                return ""
            }
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
            return 420
        }
        
        return 400
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
        ZStack(alignment:.leading){
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
                        VStack(alignment:hAlignment, spacing:5) {
                            HStack(alignment: .center, spacing:20) {
                                if !titleIcon.isEmpty {
                                    WebImage(url:URL(string:titleIcon))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height:60)
                                }
                                if (!section.displayTitle.isEmpty) {
                                    Text(section.displayTitle).font(.rowTitle)
                                        .frame(alignment:alignment)
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
                            .frame(alignment:alignment)

                            if (!section.displaySubtitle.isEmpty) {
                                Text(section.displaySubtitle).font(.rowSubtitle)
                                    .frame(alignment:alignment)
                            }
                        }
                        .focusSection()
                        .frame(maxWidth: .infinity, maxHeight:.infinity,alignment:alignment)
                        .padding(.bottom, 10)
                        .padding(.leading, 10)
                        
                        if alignment == .center && items.count < 5 {
                            HStack(alignment: .top, spacing: 20) {
                                ForEach(items) {item in
                                    SectionItemView(//item: item.sectionItem,
                                        sectionId: section.id,
                                        pageId:pageId,
                                        propertyId: propertyId,
                                        forceAspectRatio:forceAspectRatio,
                                        viewItem: item
                                    )
                                    .focused($currentFocusItem, equals: item)
                                    .environmentObject(self.eluvio)
                                }
                            }
                            .padding([.top,.bottom],20)
                            .padding(.leading, 10)
                            .padding(.trailing, 0)
                            .edgesIgnoringSafeArea([.leading, .trailing])
                            .focusSection()
                        }else{
                            ScrollView(.horizontal) {
                                HStack(alignment: .center, spacing: 20) {
                                    ForEach(Array(items.enumerated()), id: \.offset) {index, item in
                                        SectionItemView(sectionId: section.id,
                                                        pageId:pageId,
                                                        propertyId: propertyId,
                                                        forceAspectRatio:forceAspectRatio,
                                                        viewItem: item
                                        )
                                        .padding(.top,0)
                                        .environmentObject(self.eluvio)
                                        .focused($currentFocusItem, equals: item)
                                        
                                    }
                                }
                                .frame(maxWidth:.infinity)
                                .padding([.top,.bottom],20)
                                .padding(.leading, 10)
                                .focusSection()
                            }
                            .defaultFocus($currentFocusItem, lastFocusItem ?? items.first, priority: .userInitiated)
                            .onChange(of: currentFocusItem) {
                                if currentFocusItem != nil {
                                    lastFocusItem = currentFocusItem
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
            .focusSection()
            .padding(.top,40)
            .padding([.leading],margin)
            .padding(.bottom,20)
            .padding(.trailing, 0)
            .edgesIgnoringSafeArea([.trailing])
            
            if lookForBackground {
                Group {
                    if let url = inlineBackgroundUrl {
                        WebImage(url:URL(string:url))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight:.infinity)
                            .clipped()
                            .zIndex(-10)
                        
                    }
                }
                .frame(maxWidth: .infinity, maxHeight:.infinity)
            }
             
        }
        .clipped()
        .edgesIgnoringSafeArea([.trailing])
        .frame(maxWidth: .infinity, maxHeight:.infinity)
        .onAppear() {
            refresh()
        }
    }
    
    func refresh() {
        // Guard against duplicate refreshes (onAppear fires every time section scrolls into view)
        if self.refreshId == eluvio.refreshId {
            return
        }
        self.refreshId = eluvio.refreshId

        debugPrint("MediaPropertyRegularSectionView refresh() ", section.displayTitle)

        Task {
            let start = CFAbsoluteTimeGetCurrent()

            // Load from cache first for immediate display
            if let cachedItems = await loadFromCache() {
                await MainActor.run {
                    self.items = cachedItems
                }
                debugPrint("⏱️ Section '\(section.displayTitle)' cache load: \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - start))s (\(cachedItems.count) items)")
            }

            // Always refresh from network to get latest data and permissions
            let networkStart = CFAbsoluteTimeGetCurrent()
            await refreshFromNetwork()
            debugPrint("⏱️ Section '\(section.displayTitle)' network refresh: \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - networkStart))s")
            debugPrint("⏱️ Section '\(section.displayTitle)' TOTAL: \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - start))s")
        }
    }
    
    private func loadFromCache() async -> [MediaPropertySectionMediaItemViewModel]? {
        // Use the existing cache infrastructure from Fabric
        var cachedItems: [MediaPropertySectionMediaItemViewModel] = []
        
        // Check if we have cached section content
        if let content = section.content, !content.isEmpty {
            let max = 25
            var count = 0
            
            for _item in content {
                var item = _item
                
                // Try to get from cache first
                if let type = section.type {
                    if type != "search" {
                        if let cachedItem = eluvio.fabric.getSectionItem(sectionId: section.id, sectionItemId: _item.id ?? "") {
                            item = cachedItem
                        } else {
                            // If not in cache, skip for now - will be loaded by network refresh
                            continue
                        }
                    }
                }
                
                // Check if we have cached permissions
                if let resolvedPermission = item.resolvedPermission {
                    if !resolvedPermission.hide {
                        let viewItem = MediaPropertySectionMediaItemViewModel.create(item: item, fabric: eluvio.fabric)
                        cachedItems.append(viewItem)
                    }
                } else {
                    // If no cached permission, create view model anyway and let network refresh handle permissions
                    let viewItem = MediaPropertySectionMediaItemViewModel.create(item: item, fabric: eluvio.fabric)
                    cachedItems.append(viewItem)
                }
                
                count += 1
                if count == max {
                    break
                }
            }
        }
        
        // Return cached items only if we have some meaningful content
        return cachedItems.isEmpty ? nil : cachedItems
    }
    
    private func refreshFromNetwork() async {
        do {
            // Only refresh display URLs if we don't have them cached
            if let display = section.display {
                if logoUrl == nil {
                    do {
                        logoUrl = try eluvio.fabric.getUrlFromLink(link: display["logo"])
                    } catch {}
                }

                if lookForBackground && inlineBackgroundUrl == nil {
                    do {
                        inlineBackgroundUrl = try eluvio.fabric.getUrlFromLink(link: display["inline_background_image"])
                    } catch {}
                }
            }

            let max = 25

            // Phase 1: Build ViewModels immediately from cached data (text + images, no permissions yet)
            // This shows the full layout with all titles and thumbnails right away
            var resolvedItems: [(item: MediaPropertySectionItem, viewModel: MediaPropertySectionMediaItemViewModel)] = []

            if let content = section.content {
                var count = 0
                for _item in content {
                    var item = _item

                    if let type = section.type {
                        if type != "search" {
                            guard let testItem = eluvio.fabric.getSectionItem(sectionId: section.id, sectionItemId: _item.id ?? "") else {
                                continue
                            }
                            item = testItem
                        }
                    }

                    let viewItem = MediaPropertySectionMediaItemViewModel.create(item: item, fabric: eluvio.fabric)
                    resolvedItems.append((item: item, viewModel: viewItem))

                    count += 1
                    if count == max {
                        break
                    }
                }
            }

            // Show all items immediately so layout is stable (no jumping)
            if !resolvedItems.isEmpty {
                let immediateViewModels = resolvedItems.map { $0.viewModel }
                await MainActor.run {
                    self.items = immediateViewModels
                }
            }

            // Phase 2: Resolve permissions in parallel, then filter hidden items
            let permStart = CFAbsoluteTimeGetCurrent()
            let sectionId = section.id
            let fabricRef = eluvio.fabric
            let propId = self.propertyId
            let pgId = self.pageId

            let permissionResults: [(index: Int, item: MediaPropertySectionItem, permission: ResolvedPermission)] = await withTaskGroup(
                of: (Int, MediaPropertySectionItem, ResolvedPermission)?.self
            ) { group in
                for (index, entry) in resolvedItems.enumerated() {
                    let entryItem = entry.item
                    group.addTask {
                        do {
                            let perm = try await fabricRef.resolveContentPermission(
                                propertyId: propId,
                                pageId: pgId,
                                sectionId: sectionId,
                                sectionItemId: entryItem.id ?? "",
                                mediaItemId: entryItem.media_id ?? ""
                            )
                            var updatedItem = entryItem
                            updatedItem.media?.resolvedPermission = perm
                            updatedItem.resolvedPermission = perm
                            return (index, updatedItem, perm)
                        } catch {
                            return nil
                        }
                    }
                }

                var results: [(Int, MediaPropertySectionItem, ResolvedPermission)] = []
                for await result in group {
                    if let r = result {
                        results.append(r)
                    }
                }
                return results.sorted { $0.0 < $1.0 }
            }

            debugPrint("⏱️ Section '\(sectionId)' parallel permissions: \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - permStart))s (\(resolvedItems.count) items, \(permissionResults.count) resolved)")
            // Rebuild final list with permissions applied, filtering hidden items
            // Items that failed permission resolution keep their Phase 1 ViewModel
            var finalItems: [MediaPropertySectionMediaItemViewModel] = []
            for (index, entry) in resolvedItems.enumerated() {
                if let result = permissionResults.first(where: { $0.index == index }) {
                    if !result.permission.hide {
                        let viewItem = MediaPropertySectionMediaItemViewModel.create(item: result.item, fabric: fabricRef)
                        finalItems.append(viewItem)
                    }
                } else {
                    // Permission resolution failed — keep the item as-is from Phase 1
                    finalItems.append(entry.viewModel)
                }
            }

            await MainActor.run {
                self.items = finalItems
            }
        } catch {
            print("Error refreshing from network: \(error)")
        }
    }

}

struct MediaPropertySectionBannerView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    var propertyId: String
    var pageId: String
    var margin: CGFloat = 80
    var isFullBleed = false
    var isFocusable = true
    @State var section: MediaPropertySection
    var items: [MediaPropertySectionItem] {
        section.content ?? []
    }
    
    var body: some View {
        VStack {
            ForEach(items, id:\.self) { item in
                MediaPropertyBanner(image:item.getBannerUrl(fabric: eluvio.fabric),
                                    margin:margin,
                                    isFullBleed: isFullBleed,
                                    isFocusable: isFocusable,
                                    action:{
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
                                return;
                            }catch {
                                print("An error occured getting the background image ", error)
                                return;
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
    @State private var refreshId = ""
    
    @State var subsections : [MediaPropertySection] = []
    
    var useScale = false
    var isFirstSection  = false
    
    @State var inlineBackgroundUrl: String? = nil
    var hasBackground : Bool {
        if let background = inlineBackgroundUrl {
            if !background.isEmpty {
                return true
            }
        }
        
        return false
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
    
    var titleIcon: String {
        if let display = section.display {
            do {
                
                let icon = try eluvio.fabric.getUrlFromLink(link: display["title_icon"])
                return icon
            }catch{
                //print("error ", error)
                return ""
            }
        }
        return ""
    }
    
    var isDisplayable: Bool {
        if section.display?["display_format"].stringValue == "carousel" || isHero {
            return true
        }
        
        return false
    }
    
    var isRegular: Bool {
        return !isHero && !isBanner && !isContainer
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
    
    var isFullBleed: Bool {
        if section.display?["full_bleed"].boolValue == true {
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
    
    @State var playerItem : AVPlayerItem? = nil

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
            if !permission.authorized && permission.hide {
                return true
            }
        }
        
        if let content = section.content {
            if (isRegular || isGrid) && content.count == 0 {
                return true;
            }
        }
        if isContainer && subsections.isEmpty{
            return true;
        }else {
            if isContainer {
                var hasContent = false;
                for section in subsections {
                    if section.content?.count ?? 0 > 0 {
                        hasContent = true;
                    }
                }
                
                if !hasContent {
                    return true
                }
            }
        }
        
        if let display = section.display {
            if let hide = display["hide_on_tv"].bool {
                if hide {
                    return true
                }
            }
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
                    MediaPropertyHeader(logo: heroLogoUrl, title: heroTitle,
                                        description: heroDescription,
                                        position:heroPosition,
                                        margin:margin)
                    .edgesIgnoringSafeArea([.leading, .trailing])
                }else if isBanner {
                    MediaPropertySectionBannerView(propertyId:propertyId,
                                                   pageId:pageId,
                                                   margin:margin,
                                                   isFullBleed: isFullBleed,
                                                   isFocusable: !isFirstSection,
                                                   section:section)
                    .edgesIgnoringSafeArea([.leading, .trailing])
                }else if isContainer{
                    VStack(alignment:.leading, spacing:0){
                        VStack(alignment:hAlignment, spacing:5) {
                            if (!section.displayTitle.isEmpty) {
                                HStack(alignment: .center, spacing:20) {
                                    if !titleIcon.isEmpty {
                                        WebImage(url:URL(string:titleIcon))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 60, height:60)
                                    }
                                    
                                    Text(section.displayTitle).font(.sectionContainerTitle)
                                        .frame(maxWidth:.infinity, alignment:alignment)
                                }
                                .frame(maxWidth:.infinity, maxHeight:.infinity)
                                
                            }
                            
                            if (!section.displaySubtitle.isEmpty) {
                                Text(section.displaySubtitle).font(.sectionContainerSubtitle)
                                    .frame(maxWidth:.infinity, alignment:alignment)
                            }
                            
                        }
                        .padding([.leading, .trailing], margin+10)
                        .padding(.top, 40)
                        .padding(.bottom, 10)
                        
                        
                        ForEach(subsections) { sub in
                            MediaPropertyRegularSectionView(propertyId:propertyId, pageId: pageId, section: sub, margin:margin, useScale: useScale, lookForBackground: true)
                        }
                    }
                }else if isGrid {
                    MediaPropertySectionGridView(propertyId:propertyId, pageId:pageId, section:section, margin:margin, useScale:useScale)
                }else {
                    MediaPropertyRegularSectionView(
                        propertyId:propertyId,
                        pageId: pageId,
                        section:section,
                        margin:margin,
                        useScale: useScale
                    )
                }
            }
        }
        .clipped()
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
            .clipped()
        )
        .disabled(disable)
        .focusSection()
        .onAppear() {
            refresh()
        }
    }

    func refresh() {
        if self.refreshId == eluvio.refreshId {
            return
        }
        self.refreshId = eluvio.refreshId

        debugPrint("MediaPropertySectionView section ", section.displayTitle)
        debugPrint("section isHero ", isHero)
        debugPrint("section isBanner ", isBanner)
        debugPrint("number of contents: ", section.content?.count)

        Task(){
                do {
                    if section.type != "search" {
                        do {
                            
                            if section.resolvedPermission == nil {
                                self.permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: section.id)
                                section.resolvedPermission = self.permission
                                if let perm = self.permission, !perm.authorized && perm.hide {
                                    debugPrint("Section \(section.id) is hidden (permission)")
                                }
                            }else {
                                self.permission = section.resolvedPermission
                            }
                        }catch{
                            self.permission = section.resolvedPermission
                        }
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
                    
                    debugPrint("Finished MediaPropertySectionView refresh for \(section.id)")
                }catch(FabricError.apiError(let code, let response, let error)){
                    eluvio.handleApiError(code: code, response: response, error: error)
                }catch {
                    debugPrint("Error getting section info:",error)
                }
                
                if let display = section.display {
                    do {
                        inlineBackgroundUrl = try eluvio.fabric.getUrlFromLink(link: display["inline_background_image"])
                    }catch{}
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
        .padding([.bottom], hasOnlyImage ? 10 : 20)
        .padding([.top], hasOnlyImage ? 10 : 95)
    }
}

struct MediaPropertyBanner: View {
    @Namespace var NamespaceProperty
    @EnvironmentObject var eluvio: EluvioAPI
    var image: String = ""
    var imageURL: String {
        return image + "&width=600"
    }
    var margin: CGFloat = 80
    var isFullBleed = false
    var isFocusable = true
    var action: ()->Void
    @FocusState var isFocused: Bool
    @State var opacity : CGFloat = 0
    
    var body: some View {
        if !image.isEmpty {
            if isFocusable {
                Button(action:action, label:{
                    HStack(alignment:.center){
                        WebImage(url:URL(string:image))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .edgesIgnoringSafeArea(.horizontal)
                            .frame(maxWidth:.infinity)
                    }
                })
                .clipped()
                .frame(maxWidth: .infinity, alignment:.leading)
                .padding([.leading, .trailing], isFullBleed ? 0 : margin)
                .padding([.top, .bottom], isFullBleed ? 0 : 40)
                .buttonStyle(BannerButtonStyle(focused:isFocused, scale:1.0, bordered: false))
                .focused($isFocused)
                .opacity(isFocused ? 1.0 : 0.6)
            }else {
                HStack(alignment:.center){
                    WebImage(url:URL(string:image))
                        .resizable()
                        .aspectRatio(contentMode: isFullBleed ? .fill : .fit)
                        .edgesIgnoringSafeArea(.horizontal)
                        .frame(maxWidth:.infinity)
                        .padding([.leading, .trailing], isFullBleed ? 0 : margin)
                        .padding([.top, .bottom], isFullBleed ? 0 : 40)
                }
            }
        }else{
            EmptyView()
        }
    }
}
