//
//  SectionItemView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-19.
//

import SwiftUI
import SwiftyJSON
import AVFoundation

struct SectionGridView: View {
    @EnvironmentObject var eluvio: EluvioAPI

    var propertyId: String
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
            return 7
        } else {
            return 4
        }
    }
    
    
    var body: some View {
        //ScrollView(.vertical) {
        VStack{
            HStack{
                Text(title)
                    .font(.rowTitle)
                Spacer()
            }
            .frame(maxWidth:.infinity)
            .padding(.bottom, 30)
            
            
            Grid(alignment:.leading, horizontalSpacing: 20, verticalSpacing: 80) {
                ForEach(items.dividedIntoGroups(of: numColumns), id: \.self) {groups in
                    GridRow(alignment:.top) {
                        ForEach(groups, id: \.self) { item in
                            SectionItemView(item: item, sectionId: section.id, propertyId: propertyId)
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
            
        //}
        //.scrollClipDisabled()
    }
}

struct MediaItemGridView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    
    var propertyId: String
    var items : [MediaPropertySectionMediaItem]
    var title : String = ""
    
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
            return 7
        } else {
            return 4
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            HStack{
                Text(title)
                    .font(.rowTitle)
                Spacer()
            }
            .frame(maxWidth:.infinity)
            .padding(.bottom, 30)
            
            Grid(alignment:.leading, horizontalSpacing: 10, verticalSpacing: 80) {
                ForEach(items.dividedIntoGroups(of: numColumns), id: \.self) {groups in
                    GridRow(alignment:.center) {
                        ForEach(groups, id: \.self) { item in
                            SectionMediaItemView(item: item)
                                .environmentObject(self.eluvio)
                        }
                    }
                    .frame(maxWidth:UIScreen.main.bounds.size.width)
                    .focusSection()
                }
            }
        }
        .scrollClipDisabled()
    }
}

struct SectionItemListView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    
    var propertyId: String
    var item: MediaPropertySectionItem
    @State var items : [MediaPropertySectionMediaItem] = []
    @FocusState var isFocused
    
    var body: some View {
        MediaItemGridView(propertyId:propertyId, items:items, title: item.media?.title ?? "")
        .onAppear(){
            debugPrint("SectionItemListView onAppear item ", item)
            Task {
                if let mediaList = item.media?.media {
                    let result = try await eluvio.fabric.getPropertyMediaItems(property: propertyId, mediaItems: mediaList)
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
    var display : MediaDisplay {
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
                                eluvio.pathState.url = try eluvio.fabric.getUrlFromLink(link:file,staticUrl:true)
                                eluvio.pathState.path.append(.html)
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
                    }else {
                        debugPrint("Item media_type: ", item.media_type)
                        debugPrint("Item without type Item: ", item)
                    }
                }
                
            }){
                MediaCard(display: display,
                          image: thumbnail,
                          isFocused:isFocused,
                          title: item.title ?? "",
                          isLive: item.live ?? false,
                          showFocusedTitle: item.title ?? "" == "" ? false : true,
                          sizeFactor: display == .square ? 1.3 : 1.0
                )
            }
            .buttonStyle(TitleButtonStyle(focused: isFocused))
            .focused($isFocused)
        }
    }
}

    

struct SectionItemView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    
    var item: MediaPropertySectionItem
    var sectionId : String
    var propertyId: String
    @State var viewItem : MediaPropertySectionMediaItemViewModel? = nil
    @FocusState var isFocused
    
    var body: some View {
        VStack(alignment:.leading, spacing:10){
            if let mediaItem = viewItem {
                Button(action: {
                    debugPrint("Item Selected! ", mediaItem.title)
                    debugPrint("MediaItemView Type ", mediaItem.media_type)
                    debugPrint("Item Type ", item.type ?? "")
                    debugPrint("Item Media Type ", item.media_type ?? "")

                    if ( mediaItem.media_type.lowercased() == "video") {
                        Task{
                            if var link = item.media?.media_link?["sources"]["default"] {
                                eluvio.pathState.path.append(.black)
                                var backgroundImage = ""
                                if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                    let viewModel = MediaPropertyViewModel.create(mediaProperty:property, fabric:eluvio.fabric)
                                    backgroundImage = viewModel.backgroundImage
                                }
                                
                                var images : [String] = []
                                if let icons = mediaItem.icons {
                                    for link in icons {
                                        do {
                                            let image = try eluvio.fabric.getUrlFromLink(link: link["icon"])
                                            images.append(image)
                                        }catch{}
                                    }
                                }
                                
                                
                                if mediaItem.isUpcoming {
                                    let videoErrorParams = VideoErrorParams(mediaItem:mediaItem, type: .upcoming, backgroundImage: backgroundImage, images: images)
                                    
                                    eluvio.pathState.videoErrorParams = videoErrorParams
                                    _ = eluvio.pathState.path.popLast()
                                    eluvio.pathState.path.append(.videoError)
                                    return
                                }
                                
                                
                                if item.media?.media_link?["."]["resolution_error"]["kind"].stringValue == "permission denied" {
                                    debugPrint("permission denied! ", mediaItem.title)
                                    debugPrint("startTime! ", mediaItem.start_time)
                                    //debugPrint("icons! ", mediaItem.icons)

                                    let videoErrorParams = VideoErrorParams(mediaItem:mediaItem, type: .permission, backgroundImage: backgroundImage, images: images)
                                    
                                    eluvio.pathState.videoErrorParams = videoErrorParams
                                    _ = eluvio.pathState.path.popLast()
                                    eluvio.pathState.path.append(.videoError)
                                    return
                                }
                             
                                do {
                                    //let playerItem  = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: link, hash:hash)
                                    let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(propertyId: propertyId, mediaId: mediaItem.media_id)
                                    let playerItem = try MakePlayerItemFromMediaOptionsJson(fabric: eluvio.fabric, optionsJson: optionsJson)
                                        eluvio.pathState.playerItem = playerItem
                                        _ = eluvio.pathState.path.popLast()
                                        eluvio.pathState.path.append(.video)
                                }catch{
                                    print("Error getting link url for playback ", error)
                                    let videoErrorParams = VideoErrorParams(mediaItem:mediaItem, type:.permission, backgroundImage: mediaItem.thumbnail)
                                    eluvio.pathState.videoErrorParams = videoErrorParams
                                    _ = eluvio.pathState.path.popLast()
                                    eluvio.pathState.path.append(.videoError)
                                }
                            }
                        }
                        
                    }else if ( mediaItem.media_type.lowercased() == "html") {
                        
                        debugPrint("Media Item", item)
                        if !mediaItem.media_file_url.isEmpty {
                            eluvio.pathState.url = mediaItem.media_file_url
                            eluvio.pathState.path.append(.html)
                        }else{
                            print("MediaItem has empty file for html type")
                        }
                    }else if ( item.media_type?.lowercased() == "list") {
                        
                        debugPrint("Media Item media List type!", item.media)
                        
                        if let media = item.media {
                            if let list = media.media {
                                if !list.isEmpty {
                                    eluvio.pathState.mediaItem = item
                                    eluvio.pathState.propertyId = propertyId
                                    eluvio.pathState.path.append(.mediaGrid)
                                }
                            }
                        }else{
                            print("MediaItem has empty file for html type")
                        }
                        
                    }else if (mediaItem.media_type.lowercased() == "gallery") {
                        debugPrint("Media Item Gallery Type ", item)
                        if let gallery = item.media?.gallery {
                            eluvio.pathState.gallery = gallery
                            eluvio.pathState.path.append(.gallery)
                        }else{
                            print("MediaItem has empty file for html type")
                        }
                    }else if ( mediaItem.type == "subproperty_link") {
                        debugPrint("Media Subproperty Item", mediaItem.thumbnail)
                        debugPrint("Media Item", item)
                        Task {
                            do {
                                if let propertyId = item.subproperty_id {
                                    if let property = try await eluvio.fabric.getProperty(property: propertyId) {
                                        debugPrint("Found Sub property", property)
                                        
                                        var pageId = "main"
                                        if let _pageId = item.subproperty_page_id {
                                            pageId = _pageId
                                        }
                                        
                                        var page = property.main_page
                                        if let _page = try await eluvio.fabric.getPropertyPage(property: propertyId, page: pageId) {
                                            debugPrint("Found page")
                                            page = _page
                                        }else{
                                            debugPrint("Could not find page for propertyId")
                                        }

                                        await MainActor.run {
                                            debugPrint("Found sub property page")
                                            eluvio.pathState.property = property
                                            eluvio.pathState.propertyPage = page
                                            eluvio.pathState.path.append(.property)
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
                        }

                    }else {
                        debugPrint("Item without type Item: ", mediaItem)
                    }
                    
                }){
                    VStack(alignment: .leading, spacing: 10){
                        MediaCard(display: mediaItem.thumb_aspect_ratio == .square ? .square :
                                    mediaItem.thumb_aspect_ratio == .portrait ? .feature :
                                    mediaItem.thumb_aspect_ratio == .landscape ? .video : .square,
                                  image: mediaItem.thumbnail,
                                  isFocused:isFocused,
                                  title: mediaItem.title,
                                  subtitle: mediaItem.subtitle,
                                  timeString: mediaItem.headerString,
                                  isLive: mediaItem.live, centerFocusedText: false,
                                  showFocusedTitle: mediaItem.title.isEmpty ? false : true,
                                  showBottomTitle: true
                        )
                    }
                }
                .buttonStyle(TitleButtonStyle(focused: isFocused))
                .focused($isFocused)
                .overlay(content: {
                    /*
                    if (mediaItem.mediaType == "Video"){
                        if !isFocused  {
                            Image(systemName: "play.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .opacity(0.7)
                        }else{
                            //TODO: when enabling resume again
                            if !media.isLive && mediaProgress?.current_time_s ?? 0.0 > 0.0{
                                VStack{
                                    Spacer()
                                    VStack(alignment:.leading, spacing:5){
                                        Text(progressText).foregroundColor(.white)
                                            .font(.system(size: 12))
                                        ProgressView(value:progressValue)
                                            .foregroundColor(.white)
                                            .frame(height:4)
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                     */
                    
                })
            }
            
            
        }
        .onAppear(){
            viewItem = MediaPropertySectionMediaItemViewModel.create(item: item, fabric : eluvio.fabric)
        }
    }
}
