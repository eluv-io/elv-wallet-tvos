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
                .edgesIgnoringSafeArea([.leading, .trailing])
                .focusSection()
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
        .edgesIgnoringSafeArea([.leading, .trailing])
        .padding([.top,.bottom], 40)
        .padding([.leading], 80)
        .focusSection()
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
            //.frame(width:UIScreen.main.bounds.width, height: UIScreen.main.bounds.size.height)
            //.padding()
            //.padding([.leading],40)
            .focusSection()
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
        if thumbnailFull.isEmpty {
            return ""
        }
        
        if thumbnailFull.contains("?") {
            return thumbnailFull + "&height=400"
        }else {
            return thumbnailFull + "?height=400"
        }
    }
    
    var thumbnailFull : String {
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
                        guard let property = try await eluvio.fabric.getProperty(property: propertyId) else {
                            await MainActor.run {
                                _ = eluvio.pathState.path.popLast()
                                eluvio.pathState.path.append(.errorView("A problem occured."))
                            }
                            return
                        }

                        let viewModel = await MediaPropertyViewModel.create(mediaProperty:property, fabric:eluvio.fabric)

                        
                        if let permission = item.resolvedPermission {
                            if !permission.authorized  || item.type == "item_purchase"{
                                
                                var purchaseImage = viewModel.purchaseImage
                                
                                if permission.purchaseGate || item.type == "item_purchase" {
                                    
                                    debugPrint("permission ids ", permission.permissionItemIds)
                                    
                                    let auth = eluvio.createWalletAuthorization()
                                    let url = try eluvio.fabric.createWalletPurchaseUrl(id:item.id ?? "", propertyId: propertyId, pageId: "", sectionItemId: item.id ?? "", permissionIds: permission.permissionItemIds, secondaryPurchaseOption: permission.secondaryPurchaseOption, authorization: auth)
                                    debugPrint("SectionMediaItemView Purchase! ", url)

                                    let params = PurchaseParams(url:url,
                                                                backgroundImage: purchaseImage,
                                                                propertyId : propertyId,
                                                                pageId : permission.alternatePageId,
                                                                sectionItem: sectionItem,
                                                                mediaItem: item)
                                    _ = eluvio.pathState.path.popLast()
                                    eluvio.pathState.path.append(.purchaseQRView(params))
                                    
                                    return
                                }else if permission.showAlternatePage {
                                    debugPrint("ShowAlternatePage ")
                                    
                                    let auth = eluvio.createWalletAuthorization()
                                    let url = eluvio.fabric.createWalletPageLink(propertyId: propertyId, pageId:permission.alternatePageId, authorization: auth)
                                    debugPrint("SectionItemView Alternative Page Purchase! ", url)

                                    let params = PurchaseParams(url:url,
                                                                backgroundImage: purchaseImage,
                                                                propertyId : propertyId,
                                                                pageId : permission.alternatePageId,
                                                                sectionItem : sectionItem,
                                                                mediaItem: item)
                                    _ = eluvio.pathState.path.popLast()
                                    eluvio.pathState.path.append(.purchaseQRView(params))
                                    return
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
                                        let playerItem  = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: link, title:item.title ?? "", description: item.description ?? "", imageThumb: thumbnail)
                                        let params = VideoParams(mediaId: item.id ?? "",
                                                                 title: item.title ?? "",
                                                                 playerItem: playerItem)
                                        eluvio.pathState.videoParams = params
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
                            let params = ImageParams(url:thumbnailFull, title: item.title ?? "")
                            eluvio.pathState.path.append(.imageView(params))
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
                          isUpcoming: item.isUpcoming,
                          startTimeString: item.startDateTimeString,
                          title: item.title ?? "",
                          isLive: item.currentlyLive,
                          showFocusedTitle: item.title ?? "" == "" ? false : true
                          //sizeFactor: display == .square ? 1.0 : 1.0
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused, scale:1.0))
            .focused($isFocused)
            .onAppear(){

            }
        }
    }
}

struct SectionItemView: View {
    @EnvironmentObject var eluvio: EluvioAPI

    var sectionId : String
    var pageId : String
    var propertyId: String
    var forceAspectRatio : String = ""
    var forceDisplay : MediaDisplay?
    var viewItem : MediaPropertySectionMediaItemViewModel
    
    @FocusState var isFocused
    
    var permission : ResolvedPermission? {
        return viewItem.sectionItem?.media?.resolvedPermission
    }
    
    var scaleFactor = 1.0
    @State private var refreshId = UUID().uuidString
    
    var hide : Bool {
        if let permission = self.permission {
            return !permission.authorized && permission.hide
        }
        return false
    }
    
    var disable: Bool {
        return viewItem.disabled
    }
    
    var opacity : CGFloat {
        if let permission = self.permission {
            return !permission.authorized ? 0.60 : 1.0
        }
        return 1.0
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
        
        return viewItem.thumb_aspect_ratio == .square ? .square :
            viewItem.thumb_aspect_ratio == .portrait ? .feature :
            viewItem.thumb_aspect_ratio == .landscape ? .video : .square

    }
    
    var title : String {
        if viewItem.title.isEmpty {
            if let mediaTitle = viewItem.sectionItem?.media?.title {
                if !mediaTitle.isEmpty {
                    return mediaTitle
                }
            }
            
            if let mediaTitle = viewItem.mediaItem?.title {
                if !mediaTitle.isEmpty {
                    return mediaTitle
                }
            }
            
            return ""
        }else{
            return viewItem.title
        }
    }
    
    @State var refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State var refresh : Bool = false

    @State var subtitle : String = ""
    @State var imageThumbnail : String = ""
    @State var isUpcoming : Bool = false
    @State var isLive : Bool = false
    @State var startTimeString : String = ""
    @State var mediaProgress: MediaProgress?
    @State var isVisible : Bool = false
    
    var progressText: String {
        guard let progress = mediaProgress else {
            return ""
        }
        
        let left = progress.duration_s - progress.current_time_s
        let timeStr = left.asTimeString(style: .abbreviated)
        return "\(timeStr) left"
    }
    var progressValue: Double {
        if !isLive{
            guard let progress = mediaProgress else {
                return 0.0
            }
            
            if (progress.duration_s != 0) {
                return progress.current_time_s / progress.duration_s
            }
        }
        return 0.0
    }
    
    func updateProgress() {
        if !self.isVisible {
            return
        }
        Task {
            do{
                let mediaId = viewItem.media_id
                if let account = eluvio.accountManager.currentAccount {
                    let progress = try eluvio.fabric.getUserViewedProgress(address: account.getAccountAddress(), mediaId: mediaId)
                    if (progress.current_time_s > 0){
                        //debugPrint("Found saved progress ", progress)
                        await MainActor.run {
                            self.mediaProgress = progress
                        }
                    }
                }
                
            }catch{
                print("MediaView could not create MediaItemViewModel ", error)
            }
        }
    }
    
    var body: some View {
        Group {
            if !hide {
                VStack(alignment:.leading, spacing:10){
                    Text(title).font(.system(size:1)).hidden() // This is needed for some reason single items in a section didn't show
                    Button(action: {
                        debugPrint("Item selected")
                        if disable {
                            return
                        }
                        
                        Task{
                            let mediaItem = viewItem

                            guard let item = viewItem.sectionItem else {
                                return
                            }
                            
                            do{
                                
                                //Test the token
                                guard let property = try await eluvio.fabric.getProperty(property: propertyId) else {
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
                                    //Might be a race condition where the resolved permissions
                                    
                                    debugPrint("sectionItemId ", sectionItemId)
                                    debugPrint("mediaItem.id ", mediaItem.id)
                                    
                                    var permission = permission
                                    if permission == nil {
                                        permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: sectionId, sectionItemId: sectionItemId, mediaItemId: mediaItem.media_id)
                                    }
                                    
                                    if let permission = permission {
                                        if !permission.authorized  || item.type == "item_purchase"{
                                            
                                            let purchaseImage = viewModel.purchaseImage
                                            debugPrint("purchase image: ", viewModel.purchaseImage)
                                            debugPrint("property purchase_settings ", property.purchase_settings)
                                            
                                            if permission.purchaseGate || item.type == "item_purchase" {
                                                
                                                let auth = eluvio.createWalletAuthorization()
                                                
                                                debugPrint("authorization: ", auth)
                                                let url = try eluvio.fabric.createWalletPurchaseUrl(id:sectionItemId, propertyId: propertyId, pageId:pageId, sectionId: sectionId, sectionItemId: sectionItemId, permissionIds: permission.permissionItemIds, secondaryPurchaseOption: permission.secondaryPurchaseOption, authorization:auth)
                                                debugPrint("SectionItemView Purchase! ", url)
                                                
                                                
                                                let params = PurchaseParams(url:url,
                                                                            backgroundImage: purchaseImage,
                                                                            propertyId : propertyId,
                                                                            pageId : permission.alternatePageId,
                                                                            sectionId : sectionId,
                                                                            sectionItem : item)
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.purchaseQRView(params))
                                                
                                                return
                                            }else if permission.showAlternatePage {
                                                debugPrint("ShowAlternatePage ")
                                                let auth = eluvio.createWalletAuthorization()
                                                let url = eluvio.fabric.createWalletPageLink(propertyId: propertyId, pageId:permission.alternatePageId, authorization: auth)
                                                debugPrint("SectionItemView Alternative Page Purchase! ", url)
                                                
                                                let params = PurchaseParams(url:url,
                                                                            backgroundImage: purchaseImage,
                                                                            propertyId : propertyId,
                                                                            pageId : permission.alternatePageId,
                                                                            sectionId : sectionId,
                                                                            sectionItem : item)
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.purchaseQRView(params))
                                                return
                                            }
                                            
                                            _ = eluvio.pathState.path.popLast()
                                            eluvio.pathState.path.append(.errorView("Could not access media."))
                                            return
                                        }
                                    }
                                }
                                
                                if let isUpcoming = item.media?.isUpcoming {
                                    if isUpcoming {
                                        let videoErrorParams = VideoErrorParams(mediaItem:item.media, type: .upcoming, backgroundImage: backgroundImage, images: images, headerString: mediaItem.headerString, propertyId:propertyId)
                                        
                                        eluvio.pathState.videoErrorParams = videoErrorParams
                                        _ = eluvio.pathState.path.popLast()
                                        eluvio.pathState.path.append(.videoError)
                                        return
                                    }
                                }
                                
                                if ( mediaItem.media_type.lowercased() == "video") {
                                    
                                    if var link = item.media?.media_link?["sources"]["default"] {
                                        if item.media?.media_link?["."]["resolution_error"]["kind"].stringValue == "permission denied" {
                                            debugPrint("permission denied! ", mediaItem.title)
                                            debugPrint("startTime! ", mediaItem.start_time)
                                            //debugPrint("icons! ", mediaItem.icons)
                                            
                                            let videoErrorParams = VideoErrorParams(mediaItem:item.media, type: .permission, backgroundImage: backgroundImage, images: images)
                                            
                                            eluvio.pathState.videoErrorParams = videoErrorParams
                                            await MainActor.run {
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.videoError)
                                                return
                                            }
                                        }
                                        
                                        do {
                                            let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(propertyId: propertyId, mediaId: mediaItem.media_id)
                                            let playerItem = try await MakePlayerItemFromMediaOptionsJson(fabric: eluvio.fabric, optionsJson: optionsJson, title:mediaItem.title, description:mediaItem.description, imageThumb: mediaItem.thumbnail)
                                            
                                            //let playerItem = try MakePlayerItemFromMediaOptionsJson(fabric: eluvio.fabric, optionsJson: optionsJson)
                                            
                                            let params = VideoParams(mediaId:mediaItem.media_id,
                                                                     title: mediaItem.title,
                                                                     playerItem: playerItem)
                                            eluvio.pathState.videoParams = params
                                            await MainActor.run {
                                                _ = eluvio.pathState.path.popLast()
                                                eluvio.pathState.path.append(.video)
                                                return
                                            }
                                        }catch{
                                            print("Error getting link url for playback ", error)
                                            let videoErrorParams = VideoErrorParams(mediaItem:item.media, type:.permission, backgroundImage: mediaItem.thumbnail)
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
                                    let params = ImageParams(url:mediaItem.thumbnailFull, title: viewItem.title)
                                    eluvio.pathState.path.append(.imageView(params))
                                    
                                }else if ( item.type?.lowercased() == "page_link") {
                                    debugPrint("page_link item: ", item)
                                    
                                    do {
                                        if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                            debugPrint("propertyID : ", propertyId)
                                            let pageId = item.page_id ?? ""
                                            
                                            var page = property.main_page
                                            if let _page = try await eluvio.fabric.getPropertyPage(propertyId: propertyId, pageId: pageId) {
                                                debugPrint("Found page")
                                                page = _page
                                            }else{
                                                debugPrint("Could not find page for propertyId")
                                            }
                                            
                                            await MainActor.run {
                                                
                                                if !pageId.isEmpty {
                                                    let param = PropertyParam(property:property, pageId:pageId)
                                                    debugPrint("property page params: ", param)
                                                    eluvio.pathState.property = property
                                                    eluvio.pathState.propertyPage = page
                                                    
                                                    _ = eluvio.pathState.path.popLast()
                                                    eluvio.pathState.path.append(.property(param))
                                                }
                                            }
                                            return
                                        }
                                    }catch{
                                        print("could not fetch page url for banner ", error.localizedDescription)
                                    }
                                    
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
                        MediaCard(display: display,
                                  image: imageThumbnail,
                                  isFocused:isFocused,
                                  isUpcoming: isUpcoming,
                                  startTimeString: startTimeString,
                                  title: viewItem.title,
                                  subtitle: viewItem.subtitle,
                                  timeString: viewItem.headerString,
                                  isLive: isLive,
                                  centerFocusedText: false,
                                  showFocusedTitle: viewItem.title.isEmpty ? false : true,
                                  showBottomTitle: true,
                                  progressValue: progressValue,
                                  sizeFactor: scaleFactor,
                                  permission: permission
                        )
                        .id(refreshId)
                        .opacity(opacity)
                        
                    }
                    .buttonStyle(TitleButtonStyle(focused: isFocused, scale:1.0))
                    .focused($isFocused)
                }
            }
        }
        .onReceive(refreshTimer) { _ in
            Task(priority:.background) {
                update()
            }
        }
        .onScrollVisibilityChange(threshold: 0.01){ isVisible in
            self.isVisible = isVisible
            if isVisible {
                Task(priority:.background){
                    update()
                    updateProgress()
                }
            }
        }
    }
    
    func update(){
        //debugPrint("SectionItemView update ", viewItem.title)
        
        if !isVisible {
            return
        }

        let sectionItemId = viewItem.id
        if let item = eluvio.fabric.getSectionItem(sectionId: sectionId, sectionItemId: sectionItemId) {


            self.isLive = item.media?.currentlyLive ?? false
            self.startTimeString = item.media?.startDateTimeString ?? ""
            let _thumb = viewItem.thumbnail
            if self.imageThumbnail != _thumb {
                self.imageThumbnail = viewItem.thumbnail
            }
            
            self.isUpcoming = item.media?.isUpcoming ?? false
        }else {
            self.isLive = viewItem.mediaItem?.currentlyLive ?? false
            self.startTimeString = viewItem.mediaItem?.startDateTimeString ?? ""
            
            let _thumb = viewItem.thumbnail
            if self.imageThumbnail != _thumb {
                self.imageThumbnail = viewItem.thumbnail
            }
            
            self.isUpcoming = viewItem.mediaItem?.isUpcoming ?? false
        }
        self.refreshId = viewItem.id + eluvio.refreshId
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
            .onAppear(){
                debugPrint("SectionItemPurchaseView onAppear ")
                debugPrint("title: ", title)
            }
    }
    
    func purchase() {
        Task {
            do {
                if let sectionItemId = sectionItem.id {
                    self.permission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: sectionId, sectionItemId: sectionItemId)
                    
                    if let permission = permission {
                        let auth = eluvio.createWalletAuthorization()
                        let url = try eluvio.fabric.createWalletPurchaseUrl(id: sectionItemId, propertyId: propertyId, pageId:pageId, sectionId: sectionId, sectionItemId: sectionItemId, permissionIds: permission.permissionItemIds, secondaryPurchaseOption: permission.secondaryPurchaseOption, authorization: auth)
                        debugPrint("Item Purchase! ", url)
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
        .buttonStyle(TitleButtonStyle(focused: isFocused, scale:1.0))
        .focused($isFocused)
    }
}
