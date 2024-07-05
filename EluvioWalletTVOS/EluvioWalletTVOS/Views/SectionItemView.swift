//
//  SectionItemView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-19.
//

import SwiftUI

struct SectionItemView: View {
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    @EnvironmentObject var pathState: PathState
    
    var item: MediaPropertySectionItem
    @State var viewItem : MediaPropertySectionMediaItemView? = nil
    @FocusState var isFocused
    
    var body: some View {
        VStack(alignment:.leading, spacing:10){
            if let mediaItem = viewItem {
                Button(action: {
                    debugPrint("Item Selected! ", mediaItem.title)
                    debugPrint("Item Type ", mediaItem.media_type)
                    debugPrint("Media Item Type ", item.media?.media_type)
                    
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
                    }else if ( mediaItem.media_type.lowercased() == "list") {
                        let state = ViewState()
                        state.op = .gallery
                        state.mediaId = mediaItem.media_id
                        
                        viewState.setViewState(state: state)
                    }else if ( mediaItem.type == "subproperty_link") {
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
                        debugPrint("Item: ", mediaItem)
                    }
                    
                }){
                    MediaCard(display: mediaItem.thumb_aspect_ratio == .square ? .square :
                                mediaItem.thumb_aspect_ratio == .portrait ? .feature :
                                mediaItem.thumb_aspect_ratio == .landscape ? .video : .square,
                              image: mediaItem.thumbnail,
                              isFocused:isFocused,
                              title: mediaItem.title,
                              isLive: mediaItem.live,
                              showFocusedTitle: mediaItem.title.isEmpty ? false : true
                    )
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
