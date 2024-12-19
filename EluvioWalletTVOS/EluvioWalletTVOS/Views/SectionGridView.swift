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
    
    @State var items : [MediaPropertySectionMediaItemViewModel] = []
    
    var forceDisplay : MediaDisplay? = nil
 
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
    
    var numColumns: Int{
        if forceNumColumns > 0 {
            return forceNumColumns
        }
        
        if width < 1000 {
            if display == .square {
                return 4
            }else {
                return 2
            }
        }else if width < 1700 {
            if display == .square {
                return 4
            }else {
                return 3
            }
        }else {
            if display == .square {
                return 6
            }else {
                return 4
            }
        }
    }
    
    var scale : CGFloat {
        if display == .square {
            return 1.0
        }else {
            return 1.0
        }
    }
    
    var forceNumColumns = 0
    
    @State var width: CGFloat =  0
    
    var body: some View {
            VStack(alignment:.leading, spacing:0){
                if !title.isEmpty {
                    HStack{
                        Text(title)
                            .font(.rowTitle)
                        //Text("\(width)")
                        Spacer()
                    }
                    .frame(maxWidth:.infinity)
                    .padding(.top, 40)
                }
                if items.dividedIntoGroups(of: numColumns).count <= 1 {
                    HStack(spacing:20) {
                        ForEach(items, id: \.self) { item in
                            SectionItemView(//item: item.sectionItem,
                                            sectionId: section.id,
                                            pageId:pageId,
                                            propertyId: propertyId,
                                            forceDisplay:display,
                                            viewItem: item,
                                            scaleFactor: scale
                            )
                            .environmentObject(self.eluvio)
                        }
                        Spacer()
                    }
                    .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.leading)
                    .padding([.top,.bottom], 40)
                    .edgesIgnoringSafeArea([.leading, .trailing])
                    .focusSection()
                }else{
                    
                    LazyVStack(alignment:.leading){
                        Grid(alignment:.leading, horizontalSpacing: 40, verticalSpacing: 60) {
                                ForEach(items.dividedIntoGroups(of: numColumns), id: \.self) {groups in
                                    GridRow(alignment:.top) {
                                        ForEach(groups, id: \.self) { item in
                                            SectionItemView(/*item: item.sectionItem,*/ sectionId: section.id, pageId:pageId, propertyId: propertyId, forceDisplay:display,
                                                            viewItem: item,
                                                            scaleFactor: scale
                                            )
                                            .gridColumnAlignment(.leading)
                                            .environmentObject(self.eluvio)
                                            
                                        }
                                    }
                                    .frame(maxHeight:.infinity, alignment:.leading)
                                }
                        }
                        .padding([.top,.bottom], 40)
                        .edgesIgnoringSafeArea([.leading, .trailing])
                        .focusSection()
                    }
                    .frame(maxWidth:.infinity)
                    .focusSection()
                    
                    //FIXME: LazyVGrid loses selection DO NOT USE
                }
        }
        .padding([.leading], margin)
        .edgesIgnoringSafeArea([.leading, .trailing])
        .focusSection()
        .getWidth($width)
        .task {
            debugPrint("SectionGridView  ", margin)
            do {
                var sectionItems : [MediaPropertySectionMediaItemViewModel] = []
                let max = 50
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
                
            }
        }
    }
}
