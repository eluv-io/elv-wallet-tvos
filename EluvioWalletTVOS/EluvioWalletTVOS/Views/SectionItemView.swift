//
//  SectionItemView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-19.
//

import SwiftUI
import SwiftyJSON

struct SectionGridView: View {
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @EnvironmentObject var pathState: PathState
    
    var propertyId: String
    var section: MediaPropertySection
    
    var items : [MediaPropertySectionItem] {
        return section.content ?? []
    }
    
    //@State var display : MediaDisplay = .square
    
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
        ScrollView(.vertical) {
            HStack{
                Text(title)
                    .font(.rowTitle)
                Spacer()
            }
            .frame(maxWidth:.infinity)
            .padding(.bottom, 30)
            
            Grid(alignment:.center, horizontalSpacing: 10, verticalSpacing: 20) {
                ForEach(0..<(items.count / numColumns), id: \.self) {index in
                    GridRow(alignment:.center) {
                        ForEach(0..<numColumns, id: \.self) { index2 in
                            SectionItemView(item: items[(index * (numColumns)) + index2], propertyId: propertyId)
                                .environmentObject(self.pathState)
                                .environmentObject(self.fabric)
                                .environmentObject(self.viewState)
                        }
                    }
                    .frame(maxWidth:UIScreen.main.bounds.size.width)
                }
            }
        }
        .scrollClipDisabled()
    }
}

struct MediaItemGridView: View {
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @EnvironmentObject var pathState: PathState
    
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
    
    private let videoColumns = [
        GridItem(.fixed(560)),
        GridItem(.fixed(560)),
        GridItem(.fixed(560))
    ]
    private let squareColumns = [
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    var body: some View {
        ScrollView {
            HStack{
                Text(title)
                    .font(.rowTitle)
                Spacer()
            }
            .frame(maxWidth:.infinity)
            .padding(.bottom, 30)
            
            LazyVGrid(columns: display == .video ? videoColumns : squareColumns, alignment: .center, spacing:20) {
                ForEach(items) {item in
                    SectionMediaItemView(item:item)
                }
            }
        }
    }
}

struct SectionItemListView: View {
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @EnvironmentObject var pathState: PathState
    
    var propertyId: String
    var item: MediaPropertySectionItem
    @State var items : [MediaPropertySectionMediaItem] = []
    @FocusState var isFocused
    

    private let videoColumns = [
        GridItem(.fixed(560)),
        GridItem(.fixed(560)),
        GridItem(.fixed(560))
    ]
    private let squareColumns = [
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    var body: some View {
        MediaItemGridView(propertyId:propertyId, items:items, title: item.media?.title ?? "")
        .onAppear(){
            debugPrint("SectionItemListView onAppear item ", item)
            Task {
                if let mediaList = item.media?.media {
                    let result = try await fabric.getPropertyMediaItems(property: propertyId, mediaItems: mediaList)
                    //debugPrint("MediaItems: ", result)
                    await MainActor.run {
                      /*  if let item = result.first {
                            if item.thumbnail_image_portrait != nil {
                                display = .feature
                            }
                            
                            if item.thumbnail_image_landscape != nil {
                                display = .video
                            }
                            debugPrint("SectionItemListView display ", display)
                        }*/
                       
                        items = result
                    }
                }
            }
        }
    }
}

struct SectionMediaItemView: View {
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @EnvironmentObject var pathState: PathState
    
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
            let thumbnailSquare = try fabric.getUrlFromLink(link: item.thumbnail_image_square)
            if !thumbnailSquare.isEmpty {
                return thumbnailSquare
            }
        }catch{}
        
        do {
            let thumbnailPortrait = try fabric.getUrlFromLink(link: item.thumbnail_image_portrait)
            if !thumbnailPortrait.isEmpty {
                return thumbnailPortrait
            }
        }catch{}
        
        do {
            let thumbnailLand = try fabric.getUrlFromLink(link: item.thumbnail_image_landscape )
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
                                    let playerItem  = try await MakePlayerItemFromLink(fabric: fabric, link: link)
                                    pathState.playerItem = playerItem
                                    pathState.path.append(.video)
                                }catch{
                                    print("Error getting link url for playback ", error)
                                }
                            }
                        }
                    }else if (type.lowercased() == "html") {
                        
                        debugPrint("Media Item", item)
                        do {
                            if let file = item.media_file {
                                pathState.url = try fabric.getUrlFromLink(link:file,staticUrl:true)
                                pathState.path.append(.html)
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
                                pathState.gallery = gallery
                                pathState.path.append(.gallery)
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
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @EnvironmentObject var pathState: PathState
    
    var item: MediaPropertySectionItem
    var propertyId: String
    @State var viewItem : MediaPropertySectionMediaItemView? = nil
    @FocusState var isFocused
    
    var body: some View {
        VStack(alignment:.leading, spacing:10){
            if let mediaItem = viewItem {
                Button(action: {
                    debugPrint("Item Selected! ", mediaItem.title)
                    debugPrint("MediaItemView Type ", mediaItem.media_type)
                    debugPrint("Item Type ", item.type)
                    debugPrint("Item Media Type ", item.media_type)
                    
                    if ( mediaItem.media_type.lowercased() == "video") {
                        let state = ViewState()
                        state.op = .play
                        state.mediaId = mediaItem.media_id
                        
                        viewState.setViewState(state: state)
                    }else if ( mediaItem.media_type.lowercased() == "html") {
                        
                        debugPrint("Media Item", item)
                        if !mediaItem.media_file_url.isEmpty {
                            pathState.url = mediaItem.media_file_url
                            pathState.path.append(.html)
                        }else{
                            print("MediaItem has empty file for html type")
                        }
                    }else if ( item.media_type?.lowercased() == "list") {
                        
                        debugPrint("Media Item media List type!", item.media)
                        
                        if let media = item.media {
                            if let list = media.media {
                                if !list.isEmpty {
                                    pathState.mediaItem = item
                                    pathState.propertyId = propertyId
                                    pathState.path.append(.mediaGrid)
                                }
                            }
                        }else{
                            print("MediaItem has empty file for html type")
                        }
                        
                    }else if (mediaItem.media_type.lowercased() == "gallery") {
                        debugPrint("Media Item Gallery Type ", item)
                        if let gallery = item.media?.gallery {
                            pathState.gallery = gallery
                            pathState.path.append(.gallery)
                        }else{
                            print("MediaItem has empty file for html type")
                        }
                    }else if ( mediaItem.type == "subproperty_link") {
                        debugPrint("Media Subproperty Item", mediaItem.thumbnail)
                        debugPrint("Media Item", item)
                        Task {
                            do {
                                if let propertyId = item.subproperty_id {
                                    if let property = try await fabric.getProperty(property: propertyId) {
                                        debugPrint("Found Sub property", property)
                                        
                                        await MainActor.run {
                                            pathState.property = property
                                        }
                                        
                                        if let pageId = item.subproperty_page_id {
                                            if let page = try await fabric.getPropertyPage(property: propertyId, page: pageId) {
                                                await MainActor.run {
                                                    pathState.propertyPage = page
                                                }
                                            }
                                        }
                                        
                                        await MainActor.run {
                                            pathState.path.append(.property)
                                        }
                                    }
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
            viewItem = MediaPropertySectionMediaItemView.create(item: item, fabric : fabric)
        }
    }
}
