//
//  SectionGridView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-10-24.
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
    var margin: CGFloat = 80
    var useScale = false
    
    @State var items : [MediaPropertySectionMediaItemViewModel] = []
    
    var forceDisplay : MediaDisplay? = nil
    var showBackground = true
    var topPadding: CGFloat = 10
 
    @State var inlineBackgroundUrl: String? = nil
    var hasBackground : Bool {
        if let background = inlineBackgroundUrl {
            if !background.isEmpty {
                return true
            }
        }
        
        return false
    }
    
    var display : MediaDisplay {
        if let force = forceDisplay {
            return force
        }
        if let item = items.first {
            if item.thumb_aspect_ratio == .portrait{
                return .feature
            }else if item.thumb_aspect_ratio == .landscape{
                return .video
            }else {
                return .square
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
    
    var scale : CGFloat {
        if (!useScale) {
            return 1.0
        }
        
        if display == .square {
            return 0.8
        }else {
            return 0.7
        }
    }

    @State var width: CGFloat =  0
    
    private var columns: [GridItem] {
        if (!useScale) {
            if display == .square {
                return [
                    .init(.adaptive(minimum: 280, maximum: 300))
                ]
            }else if display == .feature {
                return [
                    .init(.adaptive(minimum: 300, maximum: 320))
                ]
            }else {
                return [
                    .init(.adaptive(minimum: 400, maximum: 420))
                ]
            }
        }
        
        if display == .square {
            return [
                .init(.adaptive(minimum: 200, maximum: 240))
            ]
        }else if display == .feature {
            return [
                .init(.adaptive(minimum: 240, maximum: 260))
            ]
        }else {
            return [
                .init(.adaptive(minimum: 260, maximum: 280))
            ]
        }
    }
    
    var body: some View {
        VStack(alignment:.leading, spacing:0){
            HStack{
                if !title.isEmpty {
                    Text(title)
                        .font(.rowTitle)
                    Spacer()
                }
            }
            .padding(.top, topPadding)
            .padding(.bottom, 20)

            LazyVGrid(columns:columns, alignment: .leading, spacing:20){
                ForEach(items, id: \.self) { item in
                    SectionItemView(sectionId: section.id,
                                    pageId:pageId,
                                    propertyId: propertyId,
                                    forceDisplay:display,
                                    viewItem: item,
                                    scaleFactor: scale
                    )
                    .padding(.bottom, 40)
                    .environmentObject(self.eluvio)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if (showBackground) {
                    if let url = inlineBackgroundUrl {
                        WebImage(url:URL(string:url))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .zIndex(-10)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        )
        .padding([.leading], margin)
        //.focusSection()
        .task {
            debugPrint("SectionGridView  ", margin)
            do {
                var sectionItems : [MediaPropertySectionMediaItemViewModel] = []
                let max = 100
                var count = 0
                if let content = section.content {
                    for var item in content {
                        if let mediaId = item.media_id {
                            if !mediaId.isEmpty && item.media == nil {
                               let mediaItem = eluvio.fabric.getMediaItem(mediaId:mediaId)
                                if mediaItem != nil {
                                    item.media = mediaItem
                                }
                            }
                        }
                        
                        let mediaPermission = try await eluvio.fabric.resolveContentPermission(propertyId: propertyId, pageId: pageId, sectionId: section.id, sectionItemId: item.id ?? "", mediaItemId: item.media_id ?? "")
                        
                        item.media?.resolvedPermission = mediaPermission
                        item.resolvedPermission = mediaPermission

                        if !mediaPermission.hide {
                            let viewItem = MediaPropertySectionMediaItemViewModel.create(item: item, fabric: eluvio.fabric)
                            sectionItems.append(viewItem)
                        }
                        count += 1
                        if count == max {
                            break
                        }
                    }
                }
                self.items = sectionItems
            }catch {
                debugPrint("Error processing Section Grid Items: ", error)
            }
            if (showBackground) {
                if let display = section.display {
                    do {
                        inlineBackgroundUrl = try eluvio.fabric.getUrlFromLink(link: display["inline_background_image"])
                    }catch{}
                }
            }
        }
    }
}
