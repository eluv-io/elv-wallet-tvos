//
//  DiscoverView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.


import SwiftUI
import SwiftyJSON
import Combine
import SDWebImageSwiftUI

struct DiscoverView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @Namespace private var DiscoverViewNamespace
    @State private var properties : [MediaPropertyViewModel] = []
    @State private var fabricCancellable: AnyCancellable? = nil
    @State private var fabricCancellable2: AnyCancellable? = nil
    
    @FocusState var headerFocused
    var topId = "top"
    
    @State var backgroundImageURL = ""

    
    @State private var selected: MediaPropertyViewModel = MediaPropertyViewModel()
    @State private var position: Int?
    let timer = Timer.publish(every: 3*60, on: .main, in: .common).autoconnect()
    @State var isRefreshing = false
    @State private var opacity: Double = 1.0 // Start with visible content
    @State private var showHiddenMenu = false
    @State private var network = "main"
    let networkList = ["main", "demo"]
    @StateObject private var persistentCache = PersistentDataCache()
    
    static var refreshId = ""
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0){
                if eluvio.isCustomApp() {
                    VStack(alignment:.center, spacing:40){
                        Spacer()
                        if properties.count == 1 {
                            WebImage(url: URL(string: properties[0].startScreenImage))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width:900, height:400, alignment:.leading)
                                .id(topId)

                            MediaPropertyView(property:properties[0], selected: $selected, isSimple: true)
                                .environmentObject(self.eluvio.pathState)
                                .prefersDefaultFocus(in: DiscoverViewNamespace)

                        }
                        Spacer()
                    }
                }else {
                    ScrollView() {
                        VStack(alignment:.leading, spacing:0){
                            if !properties.isEmpty {
                                HStack(){
                                    Image("start-screen-logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width:801, height:240, alignment:.leading)
                                        .id(topId)
                                    Spacer()
                                }
                                .frame(maxWidth:.infinity)
                                .padding(.top, 60)
                                .padding(.bottom, 40)
                                
                                MediaPropertiesView(properties:$properties, selected: $selected)
                                    .environmentObject(self.eluvio.pathState)
                                    .transition(.opacity)
                            }
                        }
                    }
                }
            }
            .opacity(opacity)
        }
        .onChange(of:selected){ old, new in
            // Use the already loaded MediaPropertyViewModel data instead of fetching again
            withAnimation(.easeIn(duration:1)){
                if eluvio.isCustomApp() {
                    backgroundImageURL = new.startScreenBackground
                }else {
                    backgroundImageURL = new.backgroundImage
                }
            }
        }
        .onChange(of: properties) { oldProperties, newProperties in
            debugPrint("📊 Properties array changed - old count: \(oldProperties.count), new count: \(newProperties.count)")
            if newProperties.isEmpty {
                debugPrint("⚠️ Properties is now empty!")
            } else {
                debugPrint("✅ Properties now has \(newProperties.count) items")
                // Only show first 3 to avoid log spam
                for (index, property) in newProperties.prefix(3).enumerated() {
                    debugPrint("  Property \(index): \(property.title) (image: \(property.image.isEmpty ? "EMPTY" : "HAS_IMAGE"))")
                }
                if newProperties.count > 3 {
                    debugPrint("  ... and \(newProperties.count - 3) more properties")
                }
            }
            
            // Debug UI state when properties change
            debugPrint("🖥️ UI State - eluvio.isCustomApp(): \(eluvio.isCustomApp())")
            debugPrint("🖥️ UI State - properties.isEmpty: \(newProperties.isEmpty)")
            debugPrint("🖥️ UI State - current opacity: \(opacity)")
            
            // Force a UI refresh by triggering a state change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                debugPrint("🔄 Forced UI refresh check - final properties.count: \(self.properties.count)")
            }
        }
        .onChange(of: opacity) { oldOpacity, newOpacity in
            debugPrint("🎨 Opacity changed from \(oldOpacity) to \(newOpacity)")
        }
        .background(
            Group{
                if (!backgroundImageURL.isEmpty){
                    WebImage(url: URL(string:backgroundImageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                        .frame(width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height)
                }
            }
            .opacity(opacity)
            
        )
        .scrollClipDisabled()
        .task(id:eluvio.refreshId){
            debugPrint("DiscoverView onAppear()")
            
            // Load cached data immediately if available
            await loadCachedDataAndRefresh()
        }
        .onDisappear(){
            debugPrint("DiscoverView onDisappear")
            // Don't reset opacity or clear data on disappear to maintain state
        }
    }
    
    @MainActor
    func loadCachedDataAndRefresh() async {
        let currentNetwork = network
        let hasAuth = eluvio.accountManager.currentAccount != nil
        
        debugPrint("🔍 Starting loadCachedDataAndRefresh - network: \(currentNetwork), hasAuth: \(hasAuth)")
        debugPrint("🔍 Current properties.count before cache load: \(properties.count)")
        debugPrint("🔍 Current opacity before cache load: \(opacity)")
        
        // First, try to load ViewModels from cache (with resolved URLs!)
        if let cachedViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, authState: hasAuth) {
            debugPrint("🚀 Loading cached ViewModels: \(cachedViewModels.count)")
            debugPrint("🚀 Cache hit - ViewModels have resolved image URLs!")
            
            // Check cache validity
            debugPrint("💾 Cache validation - first property: \(cachedViewModels.first?.title ?? "nil")")
            debugPrint("💾 Cache validation - last property: \(cachedViewModels.last?.title ?? "nil")")
            debugPrint("💾 First property image URL: \(cachedViewModels.first?.image ?? "EMPTY")")
            
            // Use cached ViewModels directly - no conversion needed!
            self.properties = cachedViewModels
            debugPrint("✅ Set properties directly from cached ViewModels - count: \(properties.count)")
            
            // Show cached content immediately with smooth transition
            debugPrint("🎨 About to set opacity to 1.0...")
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1.0
            }
            
            debugPrint("🎨 Set opacity to 1.0, current properties count: \(properties.count)")
            debugPrint("🎨 UI should now be visible with cached ViewModels!")
            
            // Set background immediately from cached ViewModels
            if eluvio.isCustomApp() && cachedViewModels.count == 1 {
                selected = cachedViewModels[0]
                backgroundImageURL = cachedViewModels[0].startScreenBackground
                debugPrint("🎨 Custom app - set background: \(backgroundImageURL)")
            } else if cachedViewModels.count > 1 {
                selected = cachedViewModels[0]
                backgroundImageURL = cachedViewModels[0].backgroundImage
                debugPrint("🎨 Regular app - set background: \(backgroundImageURL)")
            }
            
            // If we have cached ViewModels, completely skip network refresh for now
            if !cachedViewModels.isEmpty {
                debugPrint("Using cached ViewModels, completely skipping network calls for startup")
                // Ensure Fabric signer is initialized so getProperty() works when user taps a property
                try? await eluvio.fabric.connect(token: eluvio.accountManager.currentAccount?.fabricToken ?? "")
                // Only refresh in background much later
                Task.detached {
                    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds later
                    await self.silentBackgroundRefresh()
                }
                debugPrint("🎯 Early return - ViewModel cache loading complete")
                return // Exit early - don't make network call at all
            }
        }
        
        // Fallback: try old raw property cache
        if let cachedProperties = persistentCache.loadCachedProperties(network: currentNetwork, authState: hasAuth) {
            debugPrint("💾 Loading cached raw properties: \(cachedProperties.count)")
            debugPrint("⚠️ Using fallback raw property cache - URLs may be empty")
            
            await updatePropertiesFromCache(cachedProperties)
            debugPrint("✅ After updatePropertiesFromCache - properties count: \(properties.count)")
            
            // Show cached content immediately with smooth transition
            debugPrint("🎨 About to set opacity to 1.0...")
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1.0
            }
            
            if !cachedProperties.isEmpty {
                debugPrint("Using cached raw properties, completely skipping network calls for startup")
                // Ensure Fabric signer is initialized so getProperty() works when user taps a property
                try? await eluvio.fabric.connect(token: eluvio.accountManager.currentAccount?.fabricToken ?? "")
                Task.detached {
                    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds later
                    await self.silentBackgroundRefresh()
                }
                debugPrint("🎯 Early return - raw property cache loading complete")
                return
            }
        }
        
        // If authenticated but no auth cache, try showing unauth cache as placeholder
        if hasAuth {
            if let unauthViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, authState: false),
               !unauthViewModels.isEmpty {
                debugPrint("📋 Auth cache miss - using unauth ViewModels as placeholder: \(unauthViewModels.count)")
                self.properties = unauthViewModels
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 1.0
                }
                if unauthViewModels.count > 1 {
                    selected = unauthViewModels[0]
                    backgroundImageURL = unauthViewModels[0].backgroundImage
                }
                // Connect signer then refresh silently after a delay
                // (signIn's background pre-cache Task may already be fetching auth properties)
                try? await eluvio.fabric.connect(token: eluvio.accountManager.currentAccount?.fabricToken ?? "")
                Task.detached {
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds - let signIn pre-cache finish first
                    await self.silentBackgroundRefresh()
                }
                return
            }
        }

        debugPrint("❌ No cached data found")
        debugPrint("🌐 Making immediate network call")
        await refreshFromNetwork(useCache: false)
    }
    
    @MainActor
    private func silentBackgroundRefresh() async {
        // Silent refresh without any indicators
        do {
            let noAuth = eluvio.accountManager.currentAccount == nil
            let currentNetwork = eluvio.fabric.network

            // Check if persistent cache already has fresh auth ViewModels
            // (e.g., from signIn's background pre-cache Task)
            if let freshViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, authState: !noAuth),
               !freshViewModels.isEmpty {
                let oldIds = self.properties.map { $0.id }
                let newIds = freshViewModels.map { $0.id }
                if oldIds != newIds {
                    debugPrint("Silent refresh: using pre-cached ViewModels (\(freshViewModels.count) items)")
                    await MainActor.run {
                        self.properties = freshViewModels
                    }
                } else {
                    debugPrint("Silent refresh: pre-cached ViewModels match current, skipping network call")
                }
                return
            }

            try await eluvio.fabric.connect(token: eluvio.accountManager.currentAccount?.fabricToken ?? "")

            let props = try await eluvio.fabric.getProperties(
                includePublic: true,
                noAuth: noAuth,
                newFetch: true, // Get fresh data
                devMode: eluvio.getDevMode(),
                properties: APP_CONFIG.allowed_properties
            )

            // Cache the fresh data (both raw and ViewModels)
            persistentCache.cacheProperties(props, network: network, authState: !noAuth)

            // Silently update properties if they've changed
            var newProperties: [MediaPropertyViewModel] = []
            for property in props {
                let mediaProperty = await MediaPropertyViewModel.create(mediaProperty: property, fabric: eluvio.fabric)
                if !mediaProperty.image.isEmpty || eluvio.isCustomApp() {
                    newProperties.append(mediaProperty)

                    // Pre-cache images silently in background
                    if !mediaProperty.image.isEmpty {
                        Task {
                            await preloadImage(url: mediaProperty.image)
                        }
                    }
                }
            }

            // Cache the ViewModels with resolved URLs
            persistentCache.cachePropertyViewModels(newProperties, network: network, authState: !noAuth)

            // Update if content changed (compare IDs, not just count)
            let oldIds = self.properties.map { $0.id }
            let newIds = newProperties.map { $0.id }
            if oldIds != newIds {
                await MainActor.run {
                    self.properties = newProperties
                }
            }

        } catch {
            debugPrint("Silent background refresh failed: \(error)")
        }
    }
    
    @MainActor
    func updatePropertiesFromCache(_ cachedProperties: [MediaProperty]) async {
        debugPrint("🔄 Starting updatePropertiesFromCache with \(cachedProperties.count) cached properties")
        
        var newProperties: [MediaPropertyViewModel] = []
        
        for (index, property) in cachedProperties.enumerated() {
            debugPrint("  🏗️ Creating MediaPropertyViewModel for property \(index): \(property.title ?? "nil")")
            
            do {
                let mediaProperty = await MediaPropertyViewModel.create(mediaProperty: property, fabric: eluvio.fabric)
                
                debugPrint("    ✅ Created MediaPropertyViewModel - id: \(mediaProperty.id), image: \(mediaProperty.image.isEmpty ? "EMPTY" : "HAS_IMAGE")")
                
                // For cached data, include all properties regardless of image status
                newProperties.append(mediaProperty)
                debugPrint("    ➕ Added property (count now: \(newProperties.count))")
                
                // Pre-cache images for faster loading (only if not empty)
                if !mediaProperty.image.isEmpty {
                    Task {
                        await preloadImage(url: mediaProperty.image)
                    }
                }
                
            } catch {
                debugPrint("    💥 Error creating MediaPropertyViewModel: \(error)")
            }
        }
        
        debugPrint("🎯 Final newProperties count: \(newProperties.count)")
        
        self.properties = newProperties
        
        debugPrint("📦 Set self.properties, count: \(self.properties.count)")
        
        // Force UI update and add debug info about the UI state
        debugPrint("🔍 UI Debug - eluvio.isCustomApp(): \(eluvio.isCustomApp())")
        debugPrint("🔍 UI Debug - properties.isEmpty: \(self.properties.isEmpty)")
        debugPrint("🔍 UI Debug - properties.count: \(self.properties.count)")
        
        // Batch preload images in background for instant display next time
        if !newProperties.isEmpty {
            Task {
                await batchPreloadImages(from: newProperties)
            }
        }
        
        // Set background immediately from cached data
        if eluvio.isCustomApp() && newProperties.count == 1 {
            selected = newProperties[0]
            backgroundImageURL = newProperties[0].startScreenBackground
            debugPrint("🎨 Custom app - set background: \(backgroundImageURL)")
        } else if newProperties.count > 1 {
            selected = newProperties[0]
            backgroundImageURL = newProperties[0].backgroundImage
            debugPrint("🎨 Regular app - set background: \(backgroundImageURL)")
        } else {
            debugPrint("⚠️ No properties to set as background")
        }
        
        debugPrint("✅ updatePropertiesFromCache completed - self.properties.count: \(self.properties.count)")
    }
    
    // MARK: - Image Caching
    private func preloadImage(url: String) async {
        guard !url.isEmpty, let imageUrl = URL(string: url) else { return }
        
        // Use SDWebImageManager to prefetch and cache images
        SDWebImageManager.shared.loadImage(with: imageUrl, options: [.highPriority, .continueInBackground], progress: nil) { _, _, _, _, _, _ in
            // Image is now cached for instant display
        }
    }
    
    private func batchPreloadImages(from properties: [MediaPropertyViewModel]) async {
        debugPrint("📸 Starting batch preload of \(properties.count) property images")
        
        // Limit concurrent downloads to avoid overwhelming the system
        await withTaskGroup(of: Void.self) { group in
            for (index, property) in properties.enumerated() {
                // Limit to 10 concurrent downloads
                if group.isEmpty && index >= 10 {
                    await group.next()
                }
                
                group.addTask {
                    await self.preloadImage(url: property.image)
                    if !property.backgroundImage.isEmpty {
                        await self.preloadImage(url: property.backgroundImage)
                    }
                    if !property.startScreenImage.isEmpty {
                        await self.preloadImage(url: property.startScreenImage)
                    }
                }
            }
        }
        
        debugPrint("📸 Completed batch preload")
    }
    
    func refreshFromNetwork(useCache: Bool = false) async {
        if isRefreshing {
            return
        }
        
        // If we're using cache and already have properties, skip network entirely
        if useCache && !properties.isEmpty {
            debugPrint("Skipping network refresh - using existing cached data")
            return
        }
        
        // Only show loading indicators if we don't have cached content already
        if !useCache {
            isRefreshing = true
        }
        
        debugPrint("DiscoverView refreshFromNetwork(useCache: \(useCache))")
        
        defer {
            if !useCache {
                self.isRefreshing = false
            }
        }
        
        for _ in 1...2 {
            var retry = false
            do {
                try await eluvio.fabric.connect(token: eluvio.accountManager.currentAccount?.fabricToken ?? "")
                
                let noAuth = eluvio.accountManager.currentAccount == nil
                
                // Use existing cache for faster response, but still fetch new data
                let props = try await eluvio.fabric.getProperties(
                    includePublic: true,
                    noAuth: noAuth,
                    newFetch: !useCache, // Use cache if we have content, otherwise force new fetch
                    devMode: eluvio.getDevMode(),
                    properties: APP_CONFIG.allowed_properties
                )
                
                // Cache the fresh data (both raw and ViewModels)
                persistentCache.cacheProperties(props, network: network, authState: !noAuth)
                
                var newProperties: [MediaPropertyViewModel] = []
                
                for property in props {
                    let mediaProperty = await MediaPropertyViewModel.create(mediaProperty: property, fabric: eluvio.fabric)
                    if !mediaProperty.image.isEmpty || eluvio.isCustomApp() {
                        newProperties.append(mediaProperty)
                        
                        // Pre-cache images for faster subsequent loads
                        if !mediaProperty.image.isEmpty {
                            Task {
                                await preloadImage(url: mediaProperty.image)
                            }
                        }
                    }
                    
                    // Progressive loading - show first few items quickly
                    if newProperties.count > 4 && self.properties.isEmpty {
                        await MainActor.run {
                            self.properties = newProperties
                            withAnimation(.easeInOut(duration: 0.3)) {
                                opacity = 1.0
                            }
                        }
                    }
                }
                
                // Cache the ViewModels with resolved URLs for instant future loading!
                persistentCache.cachePropertyViewModels(newProperties, network: network, authState: !noAuth)
                
                await MainActor.run {
                    // Update background with smooth transition
                    if eluvio.isCustomApp() && newProperties.count == 1 {
                        if selected.id != newProperties[0].id {
                            selected = newProperties[0]
                            withAnimation(.easeIn(duration: 0.5)) {
                                backgroundImageURL = newProperties[0].startScreenBackground
                            }
                        }
                    } else if newProperties.count > 1 {
                        if selected.id != newProperties[0].id {
                            selected = newProperties[0]
                            withAnimation(.easeIn(duration: 0.5)) {
                                backgroundImageURL = newProperties[0].backgroundImage
                            }
                        }
                    }
                    
                    // Update all properties
                    self.properties = newProperties
                    
                    // Ensure visibility
                    if opacity < 1.0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            opacity = 1.0
                        }
                    }
                    
                    debugPrint("Finished setting properties from network")
                }
                
                break // Success, exit retry loop
                
            } catch FabricError.apiError(let code, let response, let error) {
                eluvio.handleApiError(code: code, response: response, error: error)
                if code == 401 {
                    await eluvio.refreshFabricToken()
                    retry = true
                }
            } catch {
                print("Could not refresh properties: \(error)")
            }
            
            if !retry {
                break
            }
        }
    }
    
    func refresh() {
        Task {
            await refreshFromNetwork(useCache: false)
        }
    }
}
