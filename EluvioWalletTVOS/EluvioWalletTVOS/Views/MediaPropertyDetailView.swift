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
    @State private var loadingError: String? = nil
    
    @State private var currentPropertyId : String = ""
    @State private var currentPageId : String = ""
    
    
    
    let refreshTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

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
                    // Show loading indicator when refreshing and no content
                    if isRefreshing && sections.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(2.0)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Loading...")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding(.top, 20)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    // Show error message if there's a loading error
                    else if let error = loadingError {
                        VStack {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                            Text("Error Loading Content")
                                .foregroundColor(.white)
                                .font(.title)
                                .padding(.top, 10)
                            Text(error)
                                .foregroundColor(.gray)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.top, 5)
                            Button("Retry") {
                                loadingError = nil
                                Task {
                                    await refreshAsync()
                                }
                            }
                            .padding(.top, 20)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    // Show content sections
                    else {
                        ForEach(Array(sections.enumerated()), id: \.element) {index, section in
                            if let propertyId = currentSubproperty?.id {
                                MediaPropertySectionView(propertyId: propertyId, pageId:pageId, section: section,
                                                         isFirstSection: index == 0)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(0)
                            }else if let propertyId = property?.id {
                                MediaPropertySectionView(propertyId: propertyId, pageId:pageId, section: section,
                                                         isFirstSection: index == 0)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(0)
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: sections)
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
                            .padding(.trailing, 20)
                            .padding(.top, 20)

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
                    do {
                        if let subproperty = try await eluvio.fabric.getProperty(property: sub.propertyId){
                            await MainActor.run {
                                self.currentSubproperty = subproperty
                            }
                            eluvio.needsRefresh()
                            
                            // Fade out, refresh, then fade back in
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    opacity = 0.3
                                }
                            }
                            
                            await refreshAsync()
                            
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    opacity = 1.0
                                }
                            }
                        } else {
                            debugPrint("Failed to get subproperty: \(sub.propertyId)")
                        }
                    } catch {
                        debugPrint("Error getting subproperty: \(error)")
                        // Ensure we still show something even if there's an error
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                opacity = 1.0
                            }
                        }
                    }
                }
            }
        }
        .background(
            Color.black.edgesIgnoringSafeArea(.all)
        )
        .onAppear{
            debugPrint("MediaPropertyDetailView onAppear")
            // Set initial opacity to show loading state
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0.3  // Show partial opacity to indicate loading
            }
            
            Task {
                // Refresh content first, then show full visibility
                await refreshAsync()
                
                // Only show full opacity after content is loaded
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 1.0
                }
            }
        }
        .onWillDisappear {
            withAnimation(.easeInOut(duration: 2)) {
              opacity = 0.0
            }
            eluvio.needsRefresh()
        }
        .onReceive(refreshTimer) { _ in
            // Only execute timer code if the view is visible
            guard opacity > 0 else { return }
            
            Task{
                if let currentAccount = eluvio.accountManager.currentAccount {
                    if currentAccount.isTokenExpiredIn(seconds: 2*24*60*60) {
                        await eluvio.refreshFabricToken()
                    }
                    await refreshPageSections()
                }
            }
        }
    }
    
    func refreshPageSections() async {
        if self.currentPropertyId == "" || self.currentPageId == ""{
            return;
        }
        do {
            debugPrint("MediaPropertyDetailView getting page sections")
            sections = try await eluvio.fabric.getPropertyPageSections(property: currentPropertyId, page: currentPageId)
            debugPrint("finished getting sections. ", sections.count)
        }catch(FabricError.apiError(let code, let response, let error)){
            debugPrint("Error getting page sections")
            eluvio.handleApiError(code: code, response: response, error: error)
        }catch {
            debugPrint("Error:",error)
        }
    }
  
    func refreshAsync() async {
        debugPrint("MediaPropertyDetailView refreshAsync() propertyId: ", propertyId)
        debugPrint("MediaPropertyDetailView refreshAsync() page: ", pageId)
        
        // Clear any previous error
        await MainActor.run {
            loadingError = nil
        }
        
        // Check if we have the required parameters
        if propertyId.isEmpty {
            debugPrint("Error: propertyId is empty")
            await MainActor.run {
                sections = []
                loadingError = "Invalid property ID"
            }
            return
        }
        
        // Check authentication state
        if eluvio.accountManager.currentAccount == nil {
            debugPrint("No current account, user may need to sign in")
            await MainActor.run {
                loadingError = "Please sign in to access this content"
            }
            return
        }
        
        if eluvio.fabric.fabricToken.isEmpty {
            debugPrint("No fabric token available")
            await MainActor.run {
                loadingError = "Authentication required"
            }
            return
        }
        
        // Check if already refreshing to avoid duplicate calls
        if self.isRefreshing {
            debugPrint("Already refreshing, skipping")
            return
        }
        
        // Check if we need to refresh based on refresh ID
        if self.refreshId == eluvio.refreshId {
            debugPrint("Already up to date, skipping refresh")
            return
        }
        
        await MainActor.run {
            self.refreshId = eluvio.refreshId
            self.isRefreshing = true
        }
        
        defer {
            Task { @MainActor in
                self.isRefreshing = false
            }
        }
        
        // Reset background content
        await MainActor.run {
            playerItem = nil
            backgroundImage = ""
        }
        
        // Call the existing refresh logic but in an async context
        refresh(findSubs: true)
    }
  
    func refresh(findSubs:Bool = true){
        debugPrint("MediaPropertyDetailView refresh() propertyId: ",propertyId)
        debugPrint("MediaPropertyDetailView refresh() page: ",pageId)
        debugPrint("MediaPropertyDetailView refresh() currentAccount: ", eluvio.accountManager.currentAccount?.id ?? "nil")
        debugPrint("MediaPropertyDetailView refresh() fabricToken: ", eluvio.fabric.fabricToken.prefix(20), "...")
        
        // Validate authentication state
        if eluvio.accountManager.currentAccount == nil {
            debugPrint("ERROR: No current account available")
            return
        }
        
        if eluvio.fabric.fabricToken.isEmpty {
            debugPrint("ERROR: No fabric token available") 
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
                debugPrint("MediaPropertyDetailView refresh done: setting refreshId ",refreshId)
            }
            
            let newFetch = true
            var _mediaProperty:MediaProperty?
            do {
                debugPrint("Fetching property new? \(newFetch) ", propertyId)
                _mediaProperty = try await eluvio.fabric.getProperty(property:propertyId, newFetch:newFetch)
            }catch(FabricError.apiError(let code, let response, let error)){
                await eluvio.handleApiError(code: code, response: response, error: error)
            }catch{
                debugPrint("Could not fetch property ",error)
            }

            if let mediaProperty = _mediaProperty {
                debugPrint("Fetched property ", mediaProperty.id)
                self.propertyView = await MediaPropertyViewModel.create(mediaProperty:mediaProperty, fabric:eluvio.fabric)
                await MainActor.run {
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
                                let authorized = eluvio.fabric.checkPermissionIds(permissionIds: perms, authState: authState["permission_auth_state"])
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
                //debugPrint("Property permissions ", altProperty?.permissions)
                //debugPrint("Property authState ", altProperty?.permission_auth_state)
                //debugPrint("Page permissions ", altProperty?.main_page?.permissions)
                
                var pagePerms = try await eluvio.fabric.resolvePagePermission(propertyId: altPropertyId, pageId: altPageId)
                //debugPrint("Main Page resolved permissions", pagePerms)
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
                        //TODO: what to show?
                    }
                }
            }catch{
                print("Could not resolve permissions for property id \(altPropertyId)", error.localizedDescription)
            }
            
            self.currentPropertyId = altPropertyId
            self.currentPageId = altPageId

            do {
                debugPrint("MediaPropertyDetailView getting page sections inside refresh", altPropertyId)
                let fetchedSections = try await eluvio.fabric.getPropertyPageSections(property: altPropertyId, page: altPageId)
                debugPrint("finished getting sections. Count: ", fetchedSections.count)
                
                await MainActor.run {
                    sections = fetchedSections
                }
                
                if fetchedSections.isEmpty {
                    debugPrint("WARNING: No sections found for property \(altPropertyId) page \(altPageId)")
                }
                
            }catch(FabricError.apiError(let code, let response, let error)){
                debugPrint("ERROR getting page sections - Code: \(code)")
                debugPrint("ERROR response: ", response)
                await eluvio.handleApiError(code: code, response: response, error: error)
                
                // Set empty sections and error state
                await MainActor.run {
                    sections = []
                    if code == 401 || code == 403 {
                        loadingError = "Authentication required. Please sign in again."
                    } else {
                        loadingError = "Failed to load content (Error \(code))"
                    }
                }
            }catch {
                debugPrint("ERROR getting page sections:", error.localizedDescription)
                // Set empty sections and error state
                await MainActor.run {
                    sections = []
                    loadingError = "Failed to load content: \(error.localizedDescription)"
                }
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
                if self.playerItem == nil && !backgroundImageString.isEmpty {
                    self.backgroundImage = backgroundImageString
                }
            }
        }
    }
}

