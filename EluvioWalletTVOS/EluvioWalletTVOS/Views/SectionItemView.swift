//
//  SectionItemView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-19.
//

import SwiftUI
import SwiftyJSON
import AVFoundation
import SDWebImageSwiftUI

struct SectionGridView: View {
    @EnvironmentObject var eluvio: EluvioAPI

    var propertyId: String
    var pageId:String
    var section: MediaPropertySection
    
    var items : [MediaPropertySectionItem] {
        return section.content ?? []
    }
    
    var forceDisplay : MediaDisplay? = nil
    
    var display : MediaDisplay {
        if let force = forceDisplay {
            return force
        }
        if let item = items.first {
            if item.media?.thumbnail_image_portrait != nil {
                return .feature
            }
            
            if item.media?.thumbnail_image_landscape != nil {
                return .video
            }
        }
        
        return .square
    }
    
    var title: String {
        if let display = section.display {
            return display["title"].stringValue
        }
        return ""
    }
    
    var numColumns: Int {
        if display == .video {
            return 4
        } else if display == .square {
            return 6
        } else {
            return 4
        }
    }
    
    
    var body: some View {
        VStack{
            HStack{
                Text(title)
                    .font(.rowTitle)
                Spacer()
            }
            .frame(maxWidth:.infinity)
            .padding(.bottom, 30)
            
            if items.dividedIntoGroups(of: numColumns).count <= 1 {
                HStack(spacing:34) {
                        ForEach(items, id: \.self) { item in
                            SectionItemView(item: item, sectionId: section.id, pageId:pageId, propertyId: propertyId, forceDisplay:display)
                                .environmentObject(self.eluvio)
                        }
                        Spacer()
                }
                .frame(maxWidth:.infinity, alignment:.leading)
            }else{
                Grid(alignment:.leading, horizontalSpacing: 20, verticalSpacing: 80) {
                    ForEach(items.dividedIntoGroups(of: numColumns), id: \.self) {groups in
                        GridRow(alignment:.top) {
                            ForEach(groups, id: \.self) { item in
                                SectionItemView(item: item, sectionId: section.id, pageId:pageId, propertyId: propertyId, forceDisplay:display)
                                    .environmentObject(self.eluvio)
                            }
                            .gridColumnAlignment(.leading)
                        }
                        .frame(maxWidth:.infinity, alignment:.leading)
                        .gridColumnAlignment(.leading)
                    }
                }
                .frame(maxWidth:.infinity)
                .focusSection()
            }
        }
    }
}

struct MediaItemGridView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    
    var propertyId: String
    var items : [MediaPropertySectionMediaItem]
    var title : String = ""
    var sectionItem: MediaPropertySectionItem?
    
    @FocusState var isFocused
    
    var display : MediaDisplay {
        if let item = items.first {
            if item.thumbnail_image_portrait != nil {
                return .feature
            }
            
            if item.thumbnail_image_landscape != nil {
                return .video
            }
        }
        
        return .square
    }
    
    var numColumns: Int {
        if display == .video {
            return 4
        } else if display == .square {
            return 6
        } else {
            return 4
        }
    }
    
    var body: some View {
            ScrollView(.vertical) {
                VStack{
                    HStack{
                        Text(title)
                            .font(.rowTitle)
                        Spacer()
                    }
                    .frame(maxWidth:.infinity)
                    .padding(.bottom, 30)
                    
                    if items.dividedIntoGroups(of: numColumns).count <= 1 {
                        HStack(spacing:34) {
                                ForEach(items, id: \.self) { item in
                                    SectionMediaItemView(item: item, sectionItem:sectionItem, propertyId: propertyId, forceDisplay: display)
                                        .environmentObject(self.eluvio)
                                }
                                Spacer()
                        }
                        .frame(maxWidth:.infinity, alignment:.leading)
                    }else{
                        Grid(alignment:.leading, horizontalSpacing: 20, verticalSpacing: 80) {
                            ForEach(items.dividedIntoGroups(of: numColumns), id: \.self) {groups in
                                GridRow(alignment:.top) {
                                    ForEach(groups, id: \.self) { item in
                                        SectionMediaItemView(item: item, sectionItem:sectionItem, propertyId: propertyId, forceDisplay: display)
                                            .environmentObject(self.eluvio)
                                    }
                                    .gridColumnAlignment(.leading)
                                }
                                .frame(maxWidth:.infinity, alignment:.leading)
                                .gridColumnAlignment(.leading)
                                
                            }
                        }
                        .frame(maxWidth:.infinity, alignment:.leading)
                        .focusSection()
                    }
                }
            }
            .frame(maxWidth:UIScreen.main.bounds.width, alignment:.leading)
            .padding(80)
            .scrollClipDisabled()
        }
}

struct SectionItemListView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    
    var propertyId: String
    var item: MediaPropertySectionItem?
    var list : [String]?
    var isSearch : Bool = false
    
    @State var items : [MediaPropertySectionMediaItem] = []
    //@State var lists : [(String, MediaPropertySectionMediaItem)] = []
    @FocusState var isFocused
    
    func filterList(list : [MediaPropertySectionMediaItem]) async throws -> [MediaPropertySectionMediaItem] {
        debugPrint("SectionItemListView filterList")
        var filtered : [MediaPropertySectionMediaItem] = []
        for var mediaItem in list {
            if let mediaId = mediaItem.id {
                debugPrint("SEARCH PERMISSION MediaID: \(mediaId)")
                let permissions = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, mediaItemId: mediaId, isSearch:isSearch)
                //debugPrint("FilterList Permissions for \(mediaItem.title ?? "") ", permissions)
                if !permissions.hide {
                    mediaItem.resolvedPermission = permissions
                    filtered.append(mediaItem)
                    debugPrint("filter list mediaItem authorized? ", mediaItem.resolvedPermission?.authorized)
                }
            }
        }
        return filtered
    }
    
    var body: some View {
        MediaItemGridView(propertyId:propertyId, items:items, title: item?.media?.title ?? "", sectionItem:item)
            .frame(width:UIScreen.main.bounds.width, height: UIScreen.main.bounds.size.height)
            .padding()
        .onAppear(){
            debugPrint("SectionItemListView onAppear item ", item)
            Task {
                var filtered : [MediaPropertySectionMediaItem] = []

                if let ids = list {
                    let result = try await eluvio.fabric.getPropertyMediaItems(property: propertyId, mediaItems: ids)
                    debugPrint("media result: ", result)
                    do {
                        filtered = try await filterList(list:result)
                    }catch{
                        print("Could not filter media list ", error)
                    }
                    await MainActor.run {
                        items = filtered
                    }
                }else if let mediaList = item?.media?.media {
                    let result = try await eluvio.fabric.getPropertyMediaItems(property: propertyId, mediaItems: mediaList)
                    debugPrint("media result: ", result)
                    do {
                        filtered = try await filterList(list:result)
                    }catch{
                        print("Could not filter media list ", error)
                    }
                    
                    await MainActor.run {
                        items = result
                    }
                }else if let lists = item?.media?.media_lists {
                    let result = try await eluvio.fabric.getPropertyMediaItems(property: propertyId, mediaItems: lists)
                    debugPrint("media_list result: ", result)
                    do {
                        filtered = try await filterList(list:result)
                    }catch{
                        print("Could not filter media list ", error)
                    }
                    await MainActor.run {
                        items = result
                    }
                }
            }
        }
    }
}

struct SectionMediaItemView: View {
    @EnvironmentObject var eluvio: EluvioAPI

    var item: MediaPropertySectionMediaItem
    var sectionItem: MediaPropertySectionItem?
    var propertyId: String = ""
    @State var viewItem: MediaPropertySectionMediaItemViewModel? = nil
    var forceDisplay : MediaDisplay? = nil
    
    var display : MediaDisplay {
        if let forceDisplay = forceDisplay {
            return forceDisplay
        }

        if item.thumbnail_image_square != nil {
            return .square
        }
        
        if item.thumbnail_image_portrait != nil {
            return .feature
        }
        
        if item.thumbnail_image_landscape != nil {
            return .video
        }
        
        return .square
    }


    var thumbnail : String {
        do {
            let thumbnailSquare = try eluvio.fabric.getUrlFromLink(link: item.thumbnail_image_square)
            if !thumbnailSquare.isEmpty {
                return thumbnailSquare
            }
        }catch{}
        
        do {
            let thumbnailPortrait = try eluvio.fabric.getUrlFromLink(link: item.thumbnail_image_portrait)
            if !thumbnailPortrait.isEmpty {
                return thumbnailPortrait
            }
        }catch{}
        
        do {
            let thumbnailLand = try eluvio.fabric.getUrlFromLink(link: item.thumbnail_image_landscape )
            if !thumbnailLand.isEmpty {
                return thumbnailLand
            }
        }catch{}
        
        return ""
    }

    @FocusState var isFocused

    var body: some View {
        VStack(alignment:.leading, spacing:10){
            Button(action: {
                Task {
                    debugPrint("Media Item pressed: ", item.type)
                    
                    
                    do {
                        guard let property = try await eluvio.fabric.getProperty(property: propertyId, noCache: true) else {
                            await MainActor.run {
                                _ = eluvio.pathState.path.popLast()
                                eluvio.pathState.path.append(.errorView("A problem occured."))
                            }
                            return
                        }
                        
                        if let permission = item.resolvedPermission {
                            if !permission.authorized  || item.type == "item_purchase"{
                                if permission.purchaseGate || item.type == "item_purchase" {
                                    
                                    debugPrint("permission ids ", permission.permissionItemIds)
                                    
                                    let url = try eluvio.fabric.createWalletPurchaseUrl(id:item.id ?? "", propertyId: propertyId, pageId: "", sectionItemId: item.id ?? "", permissionIds: permission.permissionItemIds, secondaryPurchaseOption: permission.secondaryPurchaseOption)
                                    debugPrint("Purchase! ", url)
                                    
                                    var backgroundImage = ""
                                    
                                    let viewModel = await MediaPropertyViewModel.create(mediaProperty:property, fabric:eluvio.fabric)
                                    backgroundImage = viewModel.backgroundImage
                                    
                                    
                                    let params = PurchaseParams(url:url,
                                                                backgroundImage: backgroundImage,
                                                                propertyId : propertyId,
                                                                pageId : permission.alternatePageId,
                                                                sectionItem: sectionItem,
                                                                mediaItem: item)
                                    _ = eluvio.pathState.path.popLast()
                                    eluvio.pathState.path.append(.purchaseQRView(params))
                                    
                                    return
                                }else if permission.showAlternatePage {
                                    debugPrint("ShowAlternatePage ")
                                    eluvio.pathState.property = property
                                    eluvio.pathState.propertyId = propertyId
                                    let newPage = permission.alternatePageId
                                    debugPrint("new page id ", newPage)
                                    if !newPage.isEmpty {
                                        eluvio.pathState.pageId = newPage
                                        eluvio.pathState.sectionItem = sectionItem
                                        let params = PropertyParam(property:property, pageId:newPage)
                                        _ = eluvio.pathState.path.popLast()
                                        eluvio.pathState.path.append(.property(params))
                                        return
                                    }else{
                                        debugPrint("Could not get page id.")
                                        return
                                    }
                                }
                                
                                //_ = eluvio.pathState.path.popLast()
                                eluvio.pathState.path.append(.errorView("Could not access media."))
                                return
                            }
                            
                        }
                        
                    }catch{
                        print("Could not get property \(propertyId) ", error)
                        return
                    }
                    
                    if item.type?.lowercased() == "list" {
                        debugPrint("list type")
                        if let list = item.media {
                            if !list.isEmpty {
                                
                                // await MainActor.run {
                                let params = MediaGridParams(propertyId: propertyId, list: list)
                                //_ = eluvio.pathState.path.popLast()
                                eluvio.pathState.path.append(.mediaGrid(params))
                                debugPrint("launching mediaGrid")
                                return
                                // }
                            }
                        }
                        
                    }
                    
                    if let type = item.media_type {
                        if ( type.lowercased() == "video") {
                            if let link = item.media_link?["sources"]["default"] {
                                Task{
                                    do {
                                        let playerItem  = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: link)
                                        eluvio.pathState.playerItem = playerItem
                                        eluvio.pathState.path.append(.video)
                                    }catch{
                                        print("Error getting link url for playback ", error)
                                    }
                                }
                            }
                        }else if (type.lowercased() == "html") {
                            debugPrint("Media Item", item)
                            do {
                                if let file = item.media_file {
                                    let url = try eluvio.fabric.getUrlFromLink(link:file,staticUrl:true)
                                    let params = HtmlParams(url:url, backgroundImage: "")
                                    eluvio.pathState.path.append(.html(params))
                                }else{
                                    print("MediaItem has empty file for html type")
                                }
                            }catch{
                                print("Could not get file url for html media type: ", error)
                            }
                        }else if (type.lowercased() == "gallery") {
                            debugPrint("Media Item Gallery Type ", item)
                            do {
                                if let gallery = item.gallery {
                                    eluvio.pathState.gallery = gallery
                                    eluvio.pathState.path.append(.gallery)
                                }else{
                                    print("MediaItem has empty file for html type")
                                }
                            }catch{
                                print("Could not get gallery from item: ", error)
                            }
                        }else if type.lowercased() == "image" {
                            _ = eluvio.pathState.path.popLast()
                            eluvio.pathState.path.append(.imageView(thumbnail))
                        }else {
                            debugPrint("Item media_type: ", item.media_type)
                            debugPrint("Item without type Item: ", item)
                        }
                    }
                }
        
            }){
                MediaCard(display: display,
                          image: thumbnail,
                          isFocused:isFocused,
                          title: item.title ?? "",
                          isLive: item.currentlyLive,
                          showFocusedTitle: item.title ?? "" == "" ? false : true
                          //sizeFactor: display == .square ? 1.0 : 1.0
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
            .onAppear(){

            }
        }
    }
}

struct SectionItemView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    
    var item: MediaPropertySectionItem
    var sectionId : String
    var pageId : String
    var propertyId: String
    var forceAspectRatio : String = ""
    var forceDisplay : MediaDisplay?
    
    @State var viewItem : MediaPropertySectionMediaItemViewModel? = nil
    @FocusState var isFocused
    @State var permission : ResolvedPermission? = nil
    
    var scaleFactor = 1.0
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
    
    var display: MediaDisplay {
        
        if let forceDisplay = self.forceDisplay {
            return forceDisplay
        }
        
        let aspectRatio = forceAspectRatio.lowercased()
        if aspectRatio == "landscape" {
            return .video
        }else if aspectRatio == "portrait" {
            return .feature
        }else if aspectRatio == "square" {
            return .square
        }
        
        
        if let mediaItem = viewItem {
            return mediaItem.thumb_aspect_ratio == .square ? .square :
            mediaItem.thumb_aspect_ratio == .portrait ? .feature :
            mediaItem.thumb_aspect_ratio == .landscape ? .video : .square
        }
        
        return .square
    }

    var body: some View {
        Group {
            if !hide {
                    VStack(alignment:.leading, spacing:10){
                        if let mediaItem = viewItem {
                            Button(action: {
                                Task{
                                    debugPrint("Item Selected! ", item)
                                    debugPrint("MediaItemView Type ", mediaItem.media_type)
                                    debugPrint("Item Type ", item.type ?? "")
                                    debugPrint("Item Media Type ", item.media_type ?? "")
                                    debugPrint("Item permission: ", item.permissions)
                                    debugPrint("Media permission: ", item.media?.permissions)
                                    //debugPrint("Item ", item)

                                    do{
                                    

                                        //Test the token
                                        guard let property = try await eluvio.fabric.getProperty(property: propertyId, noCache: true) else {
                                            await MainActor.run {
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.errorView("A problem occured."))
                                            }
                                            return
                                        }
                                        eluvio.pathState.path.append(.black)

                                        var backgroundImage = ""
                                        let viewModel = await MediaPropertyViewModel.create(mediaProperty:property, fabric:eluvio.fabric)
                                        backgroundImage = viewModel.backgroundImage
                              
                                        var images : [String] = []
                                        if let icons = mediaItem.icons {
                                            for link in icons {
                                                do {
                                                    let image = try eluvio.fabric.getUrlFromLink(link: link["icon"])
                                                    images.append(image)
                                                }catch{}
                                            }
                                        }
            
                                        
                                        if let sectionItemId = item.id {
                                            self.permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: sectionId, sectionItemId: sectionItemId, mediaItemId: mediaItem.id)
                                            debugPrint("Permission ", permission)
                                            if let permission = permission {
                                                if !permission.authorized  || item.type == "item_purchase"{
                                                    if permission.purchaseGate || item.type == "item_purchase" {
                                                        let url = try eluvio.fabric.createWalletPurchaseUrl(id:sectionItemId, propertyId: propertyId, pageId:pageId, sectionId: sectionId, sectionItemId: sectionItemId, permissionIds: permission.permissionItemIds, secondaryPurchaseOption: permission.secondaryPurchaseOption)
                                                        debugPrint("Purchase! ", url)
                                                        
                                                        var backgroundImage = ""
                                                       
                                                        let viewModel = await MediaPropertyViewModel.create(mediaProperty:property, fabric:eluvio.fabric)
                                                        backgroundImage = viewModel.backgroundImage
                                                        
                                                        
                                                        let params = PurchaseParams(url:url,
                                                                                    backgroundImage: backgroundImage,
                                                                                    propertyId : propertyId,
                                                                                    pageId : permission.alternatePageId,
                                                                                    sectionId : sectionId,
                                                                                    sectionItem : item)
                                                        _ = eluvio.pathState.path.popLast()
                                                        eluvio.pathState.path.append(.purchaseQRView(params))

                                                        return
                                                    }else if permission.showAlternatePage {
                                                        debugPrint("ShowAlternatePage ")
                                                        do{
                                                            if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                                                eluvio.pathState.property = property
                                                                eluvio.pathState.propertyId = propertyId
                                                                let newPage = permission.alternatePageId
                                                                debugPrint("new page id ", newPage)
                                                                debugPrint("existing page id ", pageId)
                                                                if !newPage.isEmpty {
                                                                    eluvio.pathState.pageId = newPage
                                                                    eluvio.pathState.sectionItem = item
                                                                    let params = PropertyParam(property:property, pageId:newPage)
                                                                    _ = eluvio.pathState.path.popLast()
                                                                    eluvio.pathState.path.append(.property(params))
                                                                    return
                                                                }else{
                                                                    debugPrint("Could not get page id.")
                                                                    return
                                                                }
                                                                
                                                            }else{
                                                                debugPrint("Could not get property.")
                                                                _ = eluvio.pathState.path.popLast()
                                                                eluvio.pathState.path.append(.errorView("A problem occured."))
                                                                return
                                                            }
                                                        }catch {
                                                            _ = eluvio.pathState.path.popLast()
                                                            debugPrint("Could not get property.", error.localizedDescription)
                                                            eluvio.pathState.path.append(.errorView("A problem occured."))
                                                            return
                                                        }
                                                    }
                                                    
                                                    _ = eluvio.pathState.path.popLast()
                                                    eluvio.pathState.path.append(.errorView("Could not access media."))
                                                    return
                                                }
                                                
                                            }
                                        }
                                   
                                    if mediaItem.isUpcoming {
                                        let videoErrorParams = VideoErrorParams(mediaItem:mediaItem, type: .upcoming, backgroundImage: backgroundImage, images: images)
                                        
                                        eluvio.pathState.videoErrorParams = videoErrorParams
                                        _ = eluvio.pathState.path.popLast()
                                        eluvio.pathState.path.append(.videoError)
                                        return
                                    }
                                    
                                    if ( mediaItem.media_type.lowercased() == "video") {
                                                 
                                        if var link = item.media?.media_link?["sources"]["default"] {
                                            if item.media?.media_link?["."]["resolution_error"]["kind"].stringValue == "permission denied" {
                                                debugPrint("permission denied! ", mediaItem.title)
                                                debugPrint("startTime! ", mediaItem.start_time)
                                                //debugPrint("icons! ", mediaItem.icons)
                                                
                                                let videoErrorParams = VideoErrorParams(mediaItem:mediaItem, type: .permission, backgroundImage: backgroundImage, images: images)
                                                
                                                eluvio.pathState.videoErrorParams = videoErrorParams
                                                await MainActor.run {
                                                    _ = eluvio.pathState.path.popLast()
                                                    eluvio.pathState.path.append(.videoError)
                                                    return
                                                }
                                            }
                                            
                                            do {
                                                //let playerItem  = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: link, hash:hash)
                                                let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(propertyId: propertyId, mediaId: mediaItem.media_id)
                                                let playerItem = try MakePlayerItemFromMediaOptionsJson(fabric: eluvio.fabric, optionsJson: optionsJson)
                                                eluvio.pathState.playerItem = playerItem
                                                await MainActor.run {
                                                    _ = eluvio.pathState.path.popLast()
                                                    eluvio.pathState.path.append(.video)
                                                    return
                                                }
                                            }catch{
                                                print("Error getting link url for playback ", error)
                                                let videoErrorParams = VideoErrorParams(mediaItem:mediaItem, type:.permission, backgroundImage: mediaItem.thumbnail)
                                                eluvio.pathState.videoErrorParams = videoErrorParams
                                                await MainActor.run {
                                                    _ = eluvio.pathState.path.popLast()
                                                    eluvio.pathState.path.append(.videoError)
                                                    return
                                                }
                                            }
                                        }
                                    }else if ( mediaItem.media_type.lowercased() == "html") {
                                        
                                        debugPrint("Media Item", item)
                                        if !mediaItem.media_file_url.isEmpty {
                                            let url = mediaItem.media_file_url
                                            let params = HtmlParams(url:url, backgroundImage: "")
                                            await MainActor.run {
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.html(params))
                                                return
                                            }
                                        }else{
                                            print("MediaItem has empty file for html type")
                                        }
                                    }else if ( item.media_type?.lowercased() == "list" || item.media_type?.lowercased() == "collection") {
                                        
                                        debugPrint("Media Item media List type!", item.media?.media_lists)
                                        
                                        if let media = item.media {
                                            if let list = media.media {
                                                if !list.isEmpty {
                                                    await MainActor.run {
                                                        _ = eluvio.pathState.path.popLast()
                                                        let params = MediaGridParams(propertyId: propertyId, pageId: pageId, list: list, sectionItem: item)
                                                        eluvio.pathState.path.append(.mediaGrid(params))
                                                        debugPrint("launching mediaGrid")
                                                        return
                                                    }
                                                }
                                            }
                                            
                                            if let list = media.media_lists {
                                                if !list.isEmpty {
                                                    await MainActor.run {
                                                        _ = eluvio.pathState.path.popLast()
                                                        let params = MediaGridParams(propertyId: propertyId, pageId: pageId, list: list, sectionItem: item)
                                                        eluvio.pathState.path.append(.mediaGrid(params))
                                                        debugPrint("launching mediaGrid")
                                                        return
                                                    }
                                                }
                                            }

                                            
                                        }else{
                                            print("MediaItem has empty file for html type")
                                        }
                                        
                                        
                                    }else if (mediaItem.media_type.lowercased() == "gallery") {
                                        debugPrint("Media Item Gallery Type ", item)
                                        if let gallery = item.media?.gallery {
                                            await MainActor.run {
                                                eluvio.pathState.gallery = gallery
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.gallery)
                                                return
                                            }
                                        }else{
                                            print("MediaItem has empty file for html type")
                                        }
                                    }else if ( mediaItem.type == "subproperty_link") {
                                        debugPrint("Media Subproperty Item", mediaItem.thumbnail)
                                        debugPrint("Media Item", item)
                                        //Task {
                                            do {
                                                if let propertyId = item.subproperty_id {
                                                    if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                                        debugPrint("Found Sub property", property)
                                                        
                                                        var pageId = "main"
                                                        if let _pageId = item.subproperty_page_id {
                                                            pageId = _pageId
                                                        }
                                                        
                                                        var page = property.main_page
                                                        if let _page = try await eluvio.fabric.getPropertyPage(propertyId: propertyId, pageId: pageId) {
                                                            debugPrint("Found page")
                                                            page = _page
                                                        }else{
                                                            debugPrint("Could not find page for propertyId")
                                                        }
                                                        
                                                        await MainActor.run {
                                                            debugPrint("Found sub property page")
                                                            eluvio.pathState.property = property
                                                            eluvio.pathState.propertyPage = page
                                                            let params = PropertyParam(property:property, pageId: page?.id ?? "main")
                                                            _ = eluvio.pathState.path.popLast()
                                                            eluvio.pathState.path.append(.property(params))
                                                        }
                                                        
                                                    }else{
                                                        debugPrint("Could not find property from propertyId ", propertyId)
                                                    }
                                                }else{
                                                    debugPrint("Could not find subproperty_id")
                                                }
                                            }catch{
                                                debugPrint("Error finding property ", item.subproperty_id)
                                            }
                                    }else if mediaItem.media_type.lowercased() == "image" {
                                        _ = eluvio.pathState.path.popLast()
                                        eluvio.pathState.path.append(.imageView(mediaItem.thumbnail))
                                        
                                    }else {
                                            debugPrint("Item without type Item: ", mediaItem)
                                        }
                                    }catch(FabricError.apiError(let code, let response, let error)){
                                        await MainActor.run {
                                            print("Could not get properties ", error.localizedDescription)
                                            _ = eluvio.pathState.path.popLast()
                                            eluvio.handleApiError(code: code, response: response, error: error)
                                        }
                                    }catch{
                                        print("Error processing section Item ", error.localizedDescription)
                                        await MainActor.run {
                                            _ = eluvio.pathState.path.popLast()
                                            eluvio.pathState.path.append(.errorView("Could not access media."))
                                            return
                                        }
                                    }
                                }
                                    
                            }){
                                VStack(alignment: .leading, spacing: 10){
                                    MediaCard(display: display,
                                              image: mediaItem.thumbnail,
                                              isFocused:isFocused, title: mediaItem.title,
                                              subtitle: mediaItem.subtitle,
                                              timeString: mediaItem.headerString,
                                              isLive: mediaItem.currentlyLive, centerFocusedText: false,
                                              showFocusedTitle: mediaItem.title.isEmpty ? false : true,
                                              showBottomTitle: true,
                                              sizeFactor: scaleFactor
                                    )
                                }
                            }
                            .buttonStyle(TitleButtonStyle(focused: isFocused))
                            .focused($isFocused)
                            .overlay(content: {
                                
                            })
                        }
                   // }
                }
            }
        }
        .disabled(disable)
        .onAppear(){
            viewItem = MediaPropertySectionMediaItemViewModel.create(item: item, fabric : eluvio.fabric)
            //debugPrint("SectionItemView thumbnail ", viewItem?.thumbnail)
            Task{
                do {
                    if self.permission == nil {
                        if let sectionItemId = item.id {
                            self.permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: sectionId, sectionItemId: sectionItemId)
                            debugPrint("Permissions for \(item.label) :\n", permission)
                        }
                    }
                }catch{}
            }
        }
        
    }
}

struct SectionItemPurchaseView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    
    var sectionItem: MediaPropertySectionItem
    var sectionId : String
    var pageId : String
    var propertyId: String
    @State var permission : ResolvedPermission? = nil
    var scaleFactor = 0.88
    
    var title : String {
        if let _title = sectionItem.display?["title"] {
            if _title.exists() {
                return _title.stringValue
            }
        }
        return ""
    }
    
    var description : String {
        if let _text = sectionItem.display?["description"] {
            if _text.exists() {
                return _text.stringValue
            }
        }
        return ""
    }
    
    var subtitle : String {
        if let _text = sectionItem.display?["subtitle"] {
            if _text.exists() {
                return _text.stringValue
            }
        }
        return ""
    }
    
    var header : String {
        if let _text = sectionItem.display?["headers"].arrayValue {
            if !_text.isEmpty {
                return _text[0].stringValue
            }
        }
        return ""
    }
    
    var display : MediaDisplay {
        if let image = sectionItem.display?["thumbnail_image_square"] {
            if image.exists() && !image.isEmpty {
                return .square
            }
        }
        
        if let image = sectionItem.display?["thumbnail_image_portrait"] {
            if image.exists() && !image.isEmpty {
                return .feature
            }
        }
        
        if let image = sectionItem.display?["thumbnail_image_landscape"] {
            if image.exists() && !image.isEmpty {
                return .video
            }
        }
        
        return .square
    }

    
    var thumbnail : String {
        
        if let image = sectionItem.display?["thumbnail_image_square"] {
            do {
                let thumbnailSquare = try eluvio.fabric.getUrlFromLink(link: image)
                if !thumbnailSquare.isEmpty {
                    return thumbnailSquare
                }
            }catch{}
        }
        
        
        if let image = sectionItem.display?["thumbnail_image_portrait"] {
            do {
                let thumbnailPortrait = try eluvio.fabric.getUrlFromLink(link: image)
                if !thumbnailPortrait.isEmpty {
                    return thumbnailPortrait
                }
            }catch{}
        }
        
        if let image = sectionItem.display?["thumbnail_image_landscape"] {
            do {
                let thumbnailLand = try eluvio.fabric.getUrlFromLink(link: image)
                if !thumbnailLand.isEmpty {
                    return thumbnailLand
                }
            }catch{}
        }

        return ""
    }
     
    var body: some View {
         ItemView(image:thumbnail, title: title, subtitle: subtitle, action:purchase, scale:scaleFactor)
    }
    
    func purchase() {
        Task {
            do {
                if let sectionItemId = sectionItem.id {
                    self.permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: sectionId, sectionItemId: sectionItemId)
                    
                    if let permission = permission {
                        let url = try eluvio.fabric.createWalletPurchaseUrl(id: sectionItemId, propertyId: propertyId, pageId:pageId, sectionId: sectionId, sectionItemId: sectionItemId, permissionIds: permission.permissionItemIds, secondaryPurchaseOption: permission.secondaryPurchaseOption)
                        debugPrint("Purchase! ", url)
                        eluvio.pathState.propertyId = propertyId
                        eluvio.pathState.pageId = permission.alternatePageId  
                        
                        var backgroundImage = ""
                        if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                            let viewModel = await MediaPropertyViewModel.create(mediaProperty:property, fabric:eluvio.fabric)
                            backgroundImage = viewModel.backgroundImage
                        }
                        
                        let params = PurchaseParams(url:url, 
                                                    backgroundImage: backgroundImage,
                                                    propertyId : propertyId,
                                                    pageId : permission.alternatePageId,
                                                    sectionId : sectionId,
                                                    sectionItem : sectionItem)
                        eluvio.pathState.path.append(.purchaseQRView(params))
                    }
                }
            }catch{
                print("Could not create purchase url.", error.localizedDescription)
            }
        }
    }
}

struct ItemView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    var isForsale = false
    @State private var buttonFocus: Bool = false
    @FocusState private var isFocused
    var display: MediaDisplay = MediaDisplay.feature
    var shadowRadius: CGFloat {
        if isFocused {
            return 10
        }else{
            return 3
        }
    }
    
    var titleColor: Color {
        if isFocused {
            return Color.black
        }else{
            return Color.white
        }
    }
    
    var subTitleColor: Color {
        if isFocused {
            return Color.black.opacity(0.5)
        }else{
            return Color.gray
        }
    }

    var image : String
    var title : String = ""
    
    var subtitle : String = ""
    
    var propertyLogo : String = ""
    var propertyName : String = ""
    var tokenId : String = ""
    var action : ()->Void
    
    
    var tokenDisplay : String {
        if tokenId.isEmpty {
            return ""
        }
        
        if tokenId.hasPrefix("#") {
            return tokenId
        }
        
        return "#\(tokenId)"
    }
    
    var scale: CGFloat = 1.0
    var width :CGFloat {
        return 480*scale
    }
    
    var height :CGFloat {
        return 660*scale
    }
    
    var logoBrightness: CGFloat {
        if isFocused {
            return -0.5
        }else{
            return 0
        }
    }
    
    var body: some View {
        Button(action:action) {
            ZStack{
                Image("dark-item-top-radial").resizable()
                    .overlay{
                        if isFocused{
                            Image("item-highlight").resizable()
                        }
                    }
                
                VStack() {
                    HStack(alignment:.center, spacing:10){
                        if(propertyLogo.hasPrefix("http")){
                            WebImage(url: URL(string: propertyLogo))
                                .resizable()
                                .indicator(.activity) // Activity Indicator
                                .transition(.fade(duration: 0.5))
                                .scaledToFill()
                                .cornerRadius(3)
                                .frame(width:40, height: 40, alignment: .center)
                                .clipped()
                                .brightness(logoBrightness)
                        }else if (propertyLogo != ""){
                            Image(propertyLogo)
                                .resizable()
                                .scaledToFill()
                                .cornerRadius(3)
                                .frame(width:40, height: 40, alignment: .center)
                                .clipped()
                                .brightness(logoBrightness)
                        }
                        
                        Text(propertyName).foregroundColor(subTitleColor).font(.itemSubtitle)
                        Spacer()
                        Text(tokenDisplay).foregroundColor(subTitleColor).font(.itemSubtitle)
                    }
                    .padding(.bottom)
                    if (image.hasPrefix("http")){
                        WebImage(url: URL(string: image))
                            .resizable()
                            .indicator(.activity) // Activity Indicator
                            .transition(.fade(duration: 0.5))
                            .scaledToFill()
                            .cornerRadius(3)
                            .frame(width: 420, height: 420, alignment: .center)
                            .clipped()
                    }else {
                        Image(image)
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(3)
                            .frame(width: 420, height: 420, alignment: .center)
                            .clipped()
                    }
                    
                    VStack(alignment: .center, spacing: 7) {
                        Spacer()
                        Text(title)
                            .foregroundColor(titleColor)
                            .font(.itemTitle)
                        Text(subtitle)
                            .foregroundColor(subTitleColor)
                            .font(.itemSubtitle)
                            .textCase(.uppercase)
                        
                        Spacer()
                    }
                    
                    if (isFocused){}
                    
                }
                .padding(30)
            }
            .shadow(radius: shadowRadius)
        }
        .scaleEffect(scale)
        .frame(width: width, height: height)
        .buttonStyle(TitleButtonStyle(focused: isFocused))
        .focused($isFocused)
    }
}
