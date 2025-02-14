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
import Foundation

extension UIImage {
    /// - Description: returns tinted image
    /// - Parameters:
    ///   - qualityMultiplier: when treating SVG image we need to enlarge the image size in order to preserve quality. The smaller the original SVG is compared to desired UIImage frame, the bigger multiplier should be.
    /// - Returns: Tinted image
    func withTintColor(_ color: UIColor, qualityMultiplier: CGFloat = 15) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width * qualityMultiplier, height: size.height * qualityMultiplier), false, scale)
        // 1 We create a rectangle equal to the size of the image
        let drawRect = CGRect(x: 0,y: 0,width: size.width * qualityMultiplier,height: size.height * qualityMultiplier)
        // 2 We set a color and fill the whole space with that color
        color.setFill()
        UIRectFill(drawRect)
        // 3 We draw an image over the space with a blend mode of .destinationIn, which is a mode that treats the image as an image mask
        draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
        
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage
    }
}

struct IconButton: View {
    @FocusState var focused
    var action: ()->Void
    var iconName: String
    
    var body: some View {
        Button(action:action){
            HStack(){
                Image(uiImage: UIImage(named: iconName)?.withTintColor(focused ? .black : .gray) ?? UIImage())
                    .resizable()
                    .frame(width:40, height:40)
                    .padding()
            }
            .background(focused ? .white : Color.black.opacity(0.5))
            .clipShape(Circle())
        }
        .buttonStyle(IconButtonStyle(focused: focused, initialOpacity: 0.7, scale: 1.2))
        .focused($focused)
    }
}

struct MediaPropertyDetailView: View {
    @Namespace var NamespaceProperty
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var eluvio: EluvioAPI
    
    @State var propertyId:String
    @State var pageId:String  = "main"
    
    @State private var property: MediaProperty?
    @State private var propertyView: MediaPropertyViewModel?
    @State private var sections : [MediaPropertySection] = []
    @FocusState private var switcherFocused
    @FocusState private var headerFocused
    @State private var playerItem : AVPlayerItem? = nil
    @State private var backgroundImage : String = ""
    @State private var opacity: Double = 0.0
    @State private var isRefreshing = false
    @State private var permissions : ResolvedPermission? = nil
    @State private var refreshId = ""
    @State private var showSwitcherMenu = false
    @State private var subProperties : [PropertySelector] = []
    @State private var currentSubproperty: MediaProperty?
    @State private var currentSubIndex: Int = 0
    @State private var menuOpen = false
    //let sectionRefreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView() {
            ZStack(alignment:.topLeading) {
                if let item = playerItem {
                    VStack(){
                        LoopingVideoPlayer([item], endAction: .loop)
                            .frame(width:UIScreen.main.bounds.size.width, height:  UIScreen.main.bounds.size.height)
                            .edgesIgnoringSafeArea([.top,.leading,.trailing])
                            .padding(0)
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
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea([.top,.leading,.trailing])
                        .frame(alignment: .topLeading)
                        .clipped()
                        .id(backgroundImage)
                }

                VStack(spacing:0) {
                    ForEach(Array(sections.enumerated()), id: \.offset ) {index, section in
                        if let propertyId = currentSubproperty?.id {
                            MediaPropertySectionView(propertyId: propertyId, pageId:pageId, section: section)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(0)
                        }else if let propertyId = property?.id {
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
                        HStack(spacing:20){
                            if !subProperties.isEmpty {
                                Menu{
                                    Picker(selection: $currentSubIndex, label:Text("")) {
                                        ForEach(Array(subProperties.enumerated()), id: \.offset) { index, property in
                                            Text(property.title)
                                            .padding(40)
                                            .tag(index)
                                        }
                                    }

                                }label: {
                                    HStack(){
                                        Image(uiImage: UIImage(named: "switcher")?.withTintColor(switcherFocused ? .black : .gray) ?? UIImage())
                                            .resizable()
                                            .frame(width:40, height:40)
                                            .padding()
                                        
                                    }
                                    .background(switcherFocused ? .white : Color.black.opacity(0.5))
                                    .clipShape(Circle())
                                }
                                .buttonStyle(IconButtonStyle(focused: switcherFocused, initialOpacity: 0.7, scale: 1.2))
                                .focused($switcherFocused)
                            }
                            
                            IconButton(action:{
                                debugPrint("Search....")
                                var propId = property?.id ?? ""
                                if let propertyId = currentSubproperty?.id {
                                    propId = propertyId
                                }
                                eluvio.pathState.searchParams = SearchParams(propertyId: propId)
                                eluvio.pathState.path.append(.search)
                                
                            }, iconName: "search")

                        }
                        
                        Spacer()
                    }
                }
                .zIndex(20)
                .focusSection()
                .padding(.trailing, 80)
                .padding(.top, 80)
                .frame(maxWidth:.infinity, maxHeight:120)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .opacity(opacity)
        .scrollClipDisabled()
        .edgesIgnoringSafeArea(.all)
        .onChange(of:currentSubIndex){
            if subProperties.count > currentSubIndex {
                let sub = subProperties[currentSubIndex]
                
                if sub.propertyId == self.currentSubproperty?.id ?? "" {
                    return
                }
                
                Task{
                    if let subproperty = try await eluvio.fabric.getProperty(property: sub.propertyId){
                        self.currentSubproperty = subproperty
                        eluvio.needsRefresh()
                    }
                    opacity = 0.0
                    refresh(findSubs:false)
                }
            }
        }
        .background(
            Color.black.edgesIgnoringSafeArea(.all)
        )
        .onAppear{
            debugPrint("MediaPropertyDetailView onAppear")
            refresh()
        }
        .onWillDisappear {
            withAnimation(.easeInOut(duration: 2)) {
              opacity = 0.0
            }
        }
        .onDisappear(){
            //eluvio.needsRefresh()
            //refresh()
        }
        /*
        .onReceive(sectionRefreshTimer) { _ in
            debugPrint("MediaPropertyDetailView refreshTimer")
            var propertyId = self.propertyId
            
            if let subId = currentSubproperty?.id {
                propertyId = subId
            }
            
            Task{
                do {
                    /*let sections = try await eluvio.fabric.getPropertyPageSections(property: propertyId, page: self.pageId)*/
                    
                    await MainActor.run {
                        debugPrint("MediaPropertyDetailView Sections count: ", sections.count)
                        self.sections = sections
                        eluvio.needsRefresh()
                    }
                }catch{
                    debugPrint(error)
                }
            }
        }
         */
    }
  
    func refresh(findSubs:Bool = true){
        debugPrint("MediaPropertyDetailView refresh() propertyId: ",propertyId)
        debugPrint("MediaPropertyDetailView refresh() page: ",pageId)
        if self.isRefreshing {
            debugPrint("no need for a refresh..exiting")
            withAnimation(.easeInOut(duration: 1)) {
              opacity = 1.0
            }
            return
        }
        
        playerItem = nil
        backgroundImage = ""
        self.isRefreshing = true
        
        if propertyId.isEmpty {
            print("Error: propertyId is empty")
            return
        }
        
        debugPrint("refresh, current supbproperty  ", currentSubproperty)
        
        Task {
            defer {
                self.isRefreshing = false
                self.refreshId = UUID().uuidString
                
                withAnimation(.easeInOut(duration: 1)) {
                  opacity = 1.0
                }
            }
            
            let newFetch = true
            
            do {
                debugPrint("Fetching property new? \(newFetch) ", propertyId)
                
                if let mediaProperty = try await eluvio.fabric.getProperty(property:propertyId, newFetch:newFetch) {
                    debugPrint("Fetched property ", mediaProperty.id)
                    self.propertyView = await MediaPropertyViewModel.create(mediaProperty:mediaProperty, fabric:eluvio.fabric)
                    await MainActor.run {
                        //self.property = nil
                        self.property = mediaProperty
                        debugPrint("Property title inside mainactor", mediaProperty.title)
                    }
                    
                    //Important to have currentSubproperty == nil to keep state of the switcher on child properties on refresh
                    if findSubs && currentSubproperty == nil{
                        //Retrieving sub properties to populate Search In: filters
                        var subs : [PropertySelector] = []
                        var parentProperty = mediaProperty
                        if let parentId = mediaProperty.parent_id {
                            debugPrint("Found parent id", parentId)
                            if !parentId.isEmpty {
                                if let prop = try await eluvio.fabric.getProperty(property:parentId) {
                                    parentProperty = prop
                                }
                            }
                        }
                        
                        if var subproperties = parentProperty.property_selection {
                            for subpropSelection in subproperties.arrayValue {
                                do {
                                    let selectorId = subpropSelection["property_id"].stringValue
                                    let perms = subpropSelection["permission_item_ids"].arrayValue
                                    //debugPrint("Subproperty permission ids ", perms)
                                    let authState = try await eluvio.fabric.getPropertyPermissions(propertyId: selectorId, noCache:false)
                                    //debugPrint("auth state::: ", authState)
                                    var authorized = try await eluvio.fabric.checkPermissionIds(permissionIds: perms, authState: authState["permission_auth_state"])
                                    //debugPrint("authorized::: ", authorized)
                                    
                                    if !authorized {
                                        continue
                                    }
                                    
                                    var logoUrl = ""
                                    debugPrint("subpropSelection : ", subpropSelection)
                                    debugPrint("logo link: ",subpropSelection["logo"])
                                    do {
                                        logoUrl = try eluvio.fabric.getUrlFromLink(link: subpropSelection["tile"])
                                    }catch{
                                        print("Could not get logo from link ", error)
                                    }
                                    
                                    var iconUrl = ""
                                    do {
                                        iconUrl = try eluvio.fabric.getUrlFromLink(link: subpropSelection["icon"])
                                    }catch{
                                        print("Could not get icon from link ", error)
                                    }
                                    
                                    let selector = PropertySelector(logoUrl: logoUrl,
                                                                    iconUrl: iconUrl,
                                                                    propertyId: selectorId,
                                                                    title: subpropSelection["title"].stringValue)
                                    debugPrint("selector created: ", selector)
                                    if !selector.isEmpty{
                                        subs.append(selector)
                                        debugPrint("added selector")
                                    }
                                }catch{
                                    print("Couldn't process sub property ", subpropSelection)
                                }
                            }
                        }
                        
                        await MainActor.run {
                            if subs.count > 1 {
                                subProperties = subs
                            }
                        }
                        
                        if !subProperties.isEmpty {
                            if let subproperty = try await eluvio.fabric.getProperty(property: subProperties[0].propertyId){
                                await MainActor.run {
                                    self.currentSubproperty = subproperty
                                }
                            }
                        }
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
            var altProperty = property
            var altPropertyId = propertyId

            if currentSubproperty != nil && currentSubproperty?.id != propertyId {
                if let subId = currentSubproperty?.id {
                    altPropertyId = subId
                    altProperty = currentSubproperty
                }
            }

            do {
                debugPrint("Property title ", altProperty?.title)
                debugPrint("Property permissions ", altProperty?.permissions)
                debugPrint("Property authState ", altProperty?.permission_auth_state)
                debugPrint("Page permissions ", altProperty?.main_page?.permissions)
                
                var pagePerms = try await eluvio.fabric.resolvePagePermission(propertyId: altPropertyId, pageId: altPageId)
                debugPrint("Main Page resolved permissions", pagePerms)
                if !pagePerms.authorized {
                    if pagePerms.behavior == .showAlternativePage {
                        self.pageId = pagePerms.alternatePageId
                        debugPrint("Alternate pageId ", pagePerms.alternatePageId)
                        //debugPrint("Setting pageId ", pageId)
                        altPageId = pagePerms.alternatePageId
                        
                        pagePerms = try await eluvio.fabric.resolvePagePermission(propertyId: altPropertyId, pageId: altPageId)
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
                print("Could not resolve permissions for property id \(altPropertyId)", error.localizedDescription)
            }

            do {
                debugPrint("MediaPropertyDetailView getting page sections")
                sections = try await eluvio.fabric.getPropertyPageSections(property: altPropertyId, page: altPageId)
                debugPrint("finished getting sections. ", sections)
            }catch(FabricError.apiError(let code, let response, let error)){
                debugPrint("Error getting page sections")
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
                                    //debugPrint("playerItem set")
                                }
                            }catch{
                                debugPrint("Error making video item: ", error)
                            }
                        }
                        
                        if !background.isEmpty {
                            do {
                                let item = try eluvio.fabric.getUrlFromLink(link: background)
                                backgroundImageString = item
                            }catch{
                                debugPrint("Error getting background image url: ", error)
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

