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
    @State var isRefreshing = false
    @State private var opacity: Double = 1.0 // Start with visible content
    @State private var showHiddenMenu = false
    @State private var network = "main"
    let networkList = ["main", "demo"]
    @StateObject private var persistentCache = PersistentDataCache()
    
    static var refreshId = ""
    /// Prevents multiple DiscoverView instances from doing heavy loading simultaneously.
    /// Only the first instance to acquire the lock does the full load; others skip.
    @State private var isLoadingOwner = false
    private static var isLoading = false

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
            if oldProperties.count != newProperties.count {
                debugPrint("Properties: \(oldProperties.count) → \(newProperties.count)")
            }
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

            // .task(id:) cancels any previous task, so reset the loading flag
            // in case the previous task's defer hasn't executed yet
            DiscoverView.isLoading = false

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
        let currentEnvironment = eluvio.fabric.environment.rawValue
        let hasAuth = eluvio.accountManager.currentAccount != nil
        let forceRefresh = eluvio.forceNetworkRefresh

        // Consume the flag so subsequent refreshes use cache normally
        if forceRefresh {
            eluvio.forceNetworkRefresh = false
        }

        debugPrint("🔍 Starting loadCachedDataAndRefresh - network: \(currentNetwork), env: \(currentEnvironment), hasAuth: \(hasAuth), forceRefresh: \(forceRefresh)")

        // Prevent multiple DiscoverView instances from doing heavy loading simultaneously
        guard !DiscoverView.isLoading else {
            debugPrint("🔍 Another DiscoverView is already loading - skipping")
            // Still try to load from cache for display
            if let cachedViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, environment: currentEnvironment, authState: hasAuth),
               !cachedViewModels.isEmpty {
                self.properties = cachedViewModels
                withAnimation(.easeInOut(duration: 0.3)) { opacity = 1.0 }
                if cachedViewModels.count > 1 {
                    selected = cachedViewModels[0]
                    backgroundImageURL = cachedViewModels[0].backgroundImage
                }
            }
            return
        }
        DiscoverView.isLoading = true
        isLoadingOwner = true
        defer {
            if isLoadingOwner {
                DiscoverView.isLoading = false
                isLoadingOwner = false
            }
        }

        // On environment change, skip cache early-returns and refresh from network immediately.
        // Still show any matching cache as a placeholder while the network call runs.
        if forceRefresh {
            debugPrint("🔄 Force refresh (environment change) - going straight to network")
            // Show existing env-specific cache as placeholder if available (no flicker)
            if let cachedViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, environment: currentEnvironment, authState: hasAuth),
               !cachedViewModels.isEmpty {
                self.properties = cachedViewModels
                withAnimation(.easeInOut(duration: 0.3)) { opacity = 1.0 }
                if eluvio.isCustomApp() && cachedViewModels.count == 1 {
                    selected = cachedViewModels[0]
                    backgroundImageURL = cachedViewModels[0].startScreenBackground
                } else if cachedViewModels.count > 1 {
                    selected = cachedViewModels[0]
                    backgroundImageURL = cachedViewModels[0].backgroundImage
                }
            }
            await refreshFromNetwork(useCache: false)
            return
        }

        // First, try to load ViewModels from cache (with resolved URLs!)
        if let cachedViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, environment: currentEnvironment, authState: hasAuth) {
            debugPrint("🚀 ViewModel cache hit: \(cachedViewModels.count) items, first: \(cachedViewModels.first?.title ?? "nil")")

            // Use cached ViewModels directly - no conversion needed!
            self.properties = cachedViewModels

            // Show cached content immediately with smooth transition
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1.0
            }

            // Set background immediately from cached ViewModels
            if eluvio.isCustomApp() && cachedViewModels.count == 1 {
                selected = cachedViewModels[0]
                backgroundImageURL = cachedViewModels[0].startScreenBackground
            } else if cachedViewModels.count > 1 {
                selected = cachedViewModels[0]
                backgroundImageURL = cachedViewModels[0].backgroundImage
            }

            // If we have cached ViewModels, completely skip network refresh for now
            if !cachedViewModels.isEmpty {
                debugPrint("Using cached ViewModels, completely skipping network calls for startup")
                // Ensure Fabric signer is initialized so getProperty() works when user taps a property
                guard !Task.isCancelled else { return }
                try? await eluvio.fabric.connect(token: eluvio.accountManager.currentAccount?.fabricToken ?? "")
                // Only refresh in background much later
                Task.detached {
                    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds later
                    guard !Task.isCancelled else { return }
                    await self.silentBackgroundRefresh()
                }
                debugPrint("🎯 Early return - ViewModel cache loading complete")
                return // Exit early - don't make network call at all
            }
        }

        // Fallback: try old raw property cache
        if let cachedProperties = persistentCache.loadCachedProperties(network: currentNetwork, environment: currentEnvironment, authState: hasAuth) {
            debugPrint("💾 Raw property cache fallback: \(cachedProperties.count) items")

            await updatePropertiesFromCache(cachedProperties)

            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1.0
            }

            if !cachedProperties.isEmpty {
                guard !Task.isCancelled else { return }
                try? await eluvio.fabric.connect(token: eluvio.accountManager.currentAccount?.fabricToken ?? "")
                Task.detached {
                    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds later
                    guard !Task.isCancelled else { return }
                    await self.silentBackgroundRefresh()
                }
                return
            }
        }

        // If authenticated but no auth cache, try showing unauth cache as placeholder
        if hasAuth {
            if let unauthViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, environment: currentEnvironment, authState: false),
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
                guard !Task.isCancelled else { return }
                try? await eluvio.fabric.connect(token: eluvio.accountManager.currentAccount?.fabricToken ?? "")
                Task.detached {
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds - let signIn pre-cache finish first
                    guard !Task.isCancelled else { return }
                    await self.silentBackgroundRefresh()
                }
                return
            }
        }

        // If no unauth cache, try auth cache as placeholder (e.g., after sign-out)
        if !hasAuth {
            if let authViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, environment: currentEnvironment, authState: true),
               !authViewModels.isEmpty {
                debugPrint("📋 Unauth cache miss - using auth ViewModels as placeholder: \(authViewModels.count)")
                self.properties = authViewModels
                withAnimation(.easeInOut(duration: 0.3)) { opacity = 1.0 }
                if authViewModels.count > 1 {
                    selected = authViewModels[0]
                    backgroundImageURL = authViewModels[0].backgroundImage
                }
                guard !Task.isCancelled else { return }
                try? await eluvio.fabric.connect(token: "")
                Task.detached {
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                    guard !Task.isCancelled else { return }
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
            let currentEnvironment = eluvio.fabric.environment.rawValue

            // Check if persistent cache already has fresh auth ViewModels
            // (e.g., from signIn's background pre-cache Task)
            if let freshViewModels = persistentCache.loadCachedPropertyViewModels(network: currentNetwork, environment: currentEnvironment, authState: !noAuth),
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
            persistentCache.cacheProperties(props, network: currentNetwork, environment: currentEnvironment, authState: !noAuth)

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
            persistentCache.cachePropertyViewModels(newProperties, network: currentNetwork, environment: currentEnvironment, authState: !noAuth)

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
        debugPrint("🔄 updatePropertiesFromCache: \(cachedProperties.count) cached properties")

        var newProperties: [MediaPropertyViewModel] = []

        for property in cachedProperties {
            let mediaProperty = await MediaPropertyViewModel.create(mediaProperty: property, fabric: eluvio.fabric)
            newProperties.append(mediaProperty)
        }

        debugPrint("🔄 updatePropertiesFromCache: built \(newProperties.count) ViewModels")

        self.properties = newProperties
        
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
            guard !Task.isCancelled else { break }
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
                let currentEnvironment = eluvio.fabric.environment.rawValue
                persistentCache.cacheProperties(props, network: network, environment: currentEnvironment, authState: !noAuth)
                
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
                persistentCache.cachePropertyViewModels(newProperties, network: network, environment: currentEnvironment, authState: !noAuth)
                
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
