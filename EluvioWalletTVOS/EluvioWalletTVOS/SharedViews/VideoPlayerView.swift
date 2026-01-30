import SwiftUI
import AVKit
import MUXSDKStats

// MARK: - Video Model
struct Video: Identifiable {
    let id : String = UUID().uuidString
    let title: String
    let thumbnail: String
    let url: URL
    let mediaItem: MediaItem?
    let description: String
    let isLive: Bool
}

// MARK: - Video Player Container
struct VideoPlayerContainerView: View {
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        PlayerViewController(viewModel: viewModel)
            .ignoresSafeArea()
    }
}

// MARK: - AVPlayerViewController Wrapper
struct PlayerViewController: UIViewControllerRepresentable {
    @EnvironmentObject var eluvio : EluvioAPI
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = viewModel.player
        
        // Configure for tvOS
        controller.allowsPictureInPicturePlayback = false
        
        // Create default info view controller
        let defaultInfoVC = DefaultInfoViewController(viewModel: viewModel, eluvio: eluvio)
        
        // Create custom stream selector view controller
        let streamSelectorVC = StreamSelectorViewController(viewModel: viewModel, eluvio: eluvio)
        
        // Add custom info tabs
        let defaultInfoTab = UITabBarItem(
            title: "Info",
            image: UIImage(systemName: "info.circle"),
            tag: 0
        )
        defaultInfoVC.tabBarItem = defaultInfoTab
        
        let streamSelectorTab = UITabBarItem(
            title: "Streams",
            image: UIImage(systemName: "play.rectangle.on.rectangle"),
            tag: 1
        )
        streamSelectorVC.tabBarItem = streamSelectorTab
        
        // Set custom info view controllers
        controller.customInfoViewControllers = [defaultInfoVC, streamSelectorVC]
        
        context.coordinator.playerViewController = controller
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== viewModel.player {
            uiViewController.player = viewModel.player
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerViewController: AVPlayerViewController?
    }
}

// MARK: - Default Info View Controller
class DefaultInfoViewController: UIHostingController<DefaultInfoView> {
    init(viewModel: VideoPlayerViewModel, eluvio: EluvioAPI) {
        super.init(rootView: DefaultInfoView(viewModel: viewModel, eluvio:eluvio))
        self.title = "Info"
        self.preferredContentSize = CGSize(width: 0, height: 300)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Default Info View
struct DefaultInfoView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    var eluvio: EluvioAPI
    
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            
            HStack(alignment: .top, spacing: 60) {
                // Thumbnail
                if let currentVideo = viewModel.currentVideo {
                    AsyncImage(url: URL(string: currentVideo.thumbnail(eluvio:eluvio))) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 320, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 10)
                }
                
                // Info and Actions
                VStack(alignment: .leading, spacing: 20) {
                    if let currentVideo = viewModel.currentVideo {
                        // Title
                        Text(currentVideo.title ?? "")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Description
                        Text(currentVideo.description ?? "")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(4)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Action Buttons (Right Side)
                VStack(alignment: .trailing, spacing: 20) {
                    if let currentVideo = viewModel.currentVideo {
                        Button(action: {
                            viewModel.playFromBeginning()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("From Beginning")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        
                        if currentVideo.live_video ?? false {
                            Button(action: {
                                viewModel.watchLive()
                            }) {
                                HStack {
                                    Image(systemName: "dot.radiowaves.left.and.right")
                                    Text("Watch Live")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
    }
}

// MARK: - Stream Selector View Controller
class StreamSelectorViewController: UIHostingController<StreamSelectorView> {
    init(viewModel: VideoPlayerViewModel, eluvio: EluvioAPI) {
        super.init(rootView: StreamSelectorView(viewModel: viewModel, eluvio: eluvio))
        self.title = "Stream Selector"
        
        // Set preferred content size to keep the view at the bottom
        // Height should be enough for thumbnails + padding
        self.preferredContentSize = CGSize(width: 0, height: 300)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Stream Selector SwiftUI View
struct StreamSelectorView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @ObservedObject var eluvio: EluvioAPI
    @FocusState private var focusedVideo: String?
    
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 40) {
                        ForEach(viewModel.videos) { video in
                            Button(action: {
                                viewModel.selectVideo(video)
                            }) {
                                VideoThumbnailCard(
                                    video: video,
                                    isSelected: viewModel.currentVideo?.id == video.id
                                )
                                .environmentObject(eluvio)
                            }
                            .buttonStyle(TransparentButtonStyle())
                            .focused($focusedVideo, equals: video.id)
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                }
                .frame(height: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .onAppear {
            // Set focus to current video or first video
            if let currentVideo = viewModel.currentVideo {
                focusedVideo = currentVideo.id
            } else if let firstVideo = viewModel.videos.first {
                focusedVideo = firstVideo.id
            }
        }
    }
}

// MARK: - Transparent Button Style
struct TransparentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.clear)
    }
}

// MARK: - Video Thumbnail Card
struct VideoThumbnailCard: View {
    @EnvironmentObject var eluvio: EluvioAPI
    let video: MediaPropertySectionMediaItem
    let isSelected: Bool
    @Environment(\.isFocused) var isFocused
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack {
                AsyncImage(url: URL(string: video.thumbnail(eluvio:eluvio))) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Color.clear
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                // Play icon overlay for currently playing video
                if isSelected {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                }
            }
            .frame(width: 280, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color.white : (isSelected ? Color.blue : Color.clear), lineWidth: 6)
            )
            .shadow(color: .black.opacity(0.3), radius: 10)
            
            // Title with background
            Text(video.title ?? "")
                .font(.system(size: 18))
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(width: 280)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.white : Color.gray.opacity(0.5))
                )
                .padding(.top, 20)
        }
        .padding(5)
    }
}

// MARK: - View Model
class VideoPlayerViewModel: ObservableObject {
    var eluvio: EluvioAPI?
    @Published var videos: [MediaPropertySectionMediaItem] = []
    @Published var currentVideo: MediaPropertySectionMediaItem?
    var propertyId: String?
    @Published var player: AVPlayer?
    var playerViewController : AVPlayerViewController?
    @State var audioLoaded = false
    @State var finishedObserver = PlayerFinishedObserver()
    var seekTimeS: Double = 0
    @State var currentTimeS: Double = -1
    var hasSeeked : Bool {
        return currentTimeS > seekTimeS
    }
    
    var progressCallback: ((_ progress: Double,_ currentTimeS: Double,_ durationS: Double)->Void )?
    
    func seekS(_ s: Double){
        debugPrint("PlayerView seeMS ", s)
        self.player?.pause()
        self.player?.seek(to: CMTime(seconds:s, preferredTimescale: 1))
        self.player?.play()
    }

    func clear(){
        player?.pause()
        videos.removeAll();
        currentVideo = nil;
        player = nil;
        audioLoaded = false;
        seekTimeS = 0;
        currentTimeS = -1;
        propertyId = nil;
    }
    
    func selectVideo(_ video: MediaPropertySectionMediaItem) {
        currentVideo = video
        Task{

            do {
                guard let eluvio = eluvio else {
                    return;
                }
                let playerItem = try await video.playerItem(eluvio:eluvio, propertyId: propertyId ?? "")
                
                await MainActor.run {
                    player = AVPlayer(playerItem: playerItem)
                }
            
                guard let playerViewController = self.playerViewController else{
                    print("missing playerViewController")
                    return
                }
                
                let initTime = ((Date().now) as NSNumber)
                
                var objectId: String = ""
                var versionHash: String = ""
                var videoHostname: String = ""
                var userId: String = ""
                var tenantId: String = ""
                var sessionId: String = ""
                var offering: String = ""
                
                if let account = eluvio.accountManager.currentAccount {
                    //If our token expires in 4 hours we refresh
                    if (account.isTokenExpiredIn(seconds: 60*60*4)){
                        await eluvio.refreshFabricToken()
                    }
                    
                    let address = account.getAccountAddress()
                    debugPrint("Address ", address)
                    
                    //FIXME: Can't find viewer_user_id to store userId
                    userId = Hash(account.getAccountAddress());
                    debugPrint("UserID: ", userId)
                }
                
                if let asset = playerItem.asset as? AVURLAsset {
                    let url = asset.url
                    debugPrint("Playout URL: ",url)
                    videoHostname = url.host() ?? ""
                    
                    let pathComponents = url.pathComponents
                    if pathComponents.count > 2 {
                        debugPrint("PATH: ", pathComponents[2])
                        if pathComponents[2].hasPrefix("hq_") {
                            versionHash = pathComponents[2]
                            debugPrint("HASH: ", versionHash)
                        }
                    }
                    
                    sessionId = url.queryParameters?["sid"] ?? ""
                    debugPrint("sessionId ", sessionId)
                    
                    let reg = /\/rep\/(playout|channel)\/([^\/]+)/
                    
                    if let match = url.absoluteString.firstMatch(of:reg) {
                        debugPrint("match 1", match.1)
                        debugPrint("match 2", match.2)
                        offering = String(match.2)
                        debugPrint("offering", offering)
                    }
                    
                    if !versionHash.isEmpty {
                        let dec = DecodeVersionHash(versionHash: versionHash)
                        debugPrint("Decoded VersionHash ", dec)
                        if !dec.objectId.isEmpty {
                            objectId = dec.objectId
                            debugPrint("objectId ", objectId)
                            
                            do {
                                tenantId = try await eluvio.fabric.getTenantId(objectId: objectId)
                                debugPrint("tenantID: ", tenantId)
                            }catch {
                                print("Could not get tenantId from object \(objectId).", error);
                            }
                            
                        }
                    }
                    
                }
                
                //debugPrint("AVPlayerView makeUIViewController()")
                let playerData = MUXSDKCustomerPlayerData(environmentKey: APP_CONFIG.network[eluvio.fabric.network]?.mux.env_key ?? "");
                // insert player metadata
                playerData?.playerName = "AVPlayer"
                playerData?.subPropertyId = tenantId
                playerData?.viewerUserId = userId
                playerData?.playerInitTime = initTime
                
                let videoData = MUXSDKCustomerVideoData()
                // insert videoData metadata
                videoData.videoId = objectId
                videoData.videoVariantId = versionHash
                videoData.videoVariantName = offering
                videoData.videoTitle = self.currentVideo?.title
                videoData.videoCdn = videoHostname
                
                let viewData = MUXSDKCustomerViewData()
                viewData.viewSessionId = sessionId
                
                
                if let customerData = MUXSDKCustomerData(customerPlayerData: playerData, videoData: videoData, viewData: viewData, customData: nil, viewerData: nil){
                    let playerBinding = MUXSDKStats.monitorAVPlayerViewController(playerViewController, withPlayerName: "mainPlayer", customerData: customerData)
                    debugPrint("MUX initialized.")
                }
            }catch {
                print("Error creating player", error)
                return
            }
            
            
            player?.addProgressObserver { progress in
                
                self.currentTimeS = self.player?.currentItem?.currentTime().seconds ?? -1.0
                
                if self.currentTimeS == -1.0 {
                    return
                }
                
                if let progressCallback = self.progressCallback {
                    progressCallback(progress,
                                     self.player?.currentItem?.currentTime().seconds ?? 0.0,
                                     self.player?.currentItem?.duration.seconds ?? 0.0)
                }else {
                    self.onPlayerProgress(progress,
                                          self.player?.currentItem?.currentTime().seconds ?? 0.0,
                                          self.player?.currentItem?.duration.seconds ?? 0.0)
                }
                
                guard let eluvio = self.eluvio else {
                    return;
                }
                
                if let account = eluvio.accountManager.currentAccount {
                    Task{
                        //If our token expires in 4 hours we refresh
                        if (account.isTokenExpiredIn(seconds: 60*60*4)){
                            await eluvio.refreshFabricToken()
                        }
                    }
                }
                
                if self.player?.status == .readyToPlay {
                    //Fixes a bug where the default audio track is not loaded with some playlists with missing default
                    if !self.audioLoaded {
                        let playerItem = self.player?.currentItem
                        if let group = playerItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
                            debugPrint("group options ", group.options)
                            debugPrint("group default option", group.defaultOption)
                            if let defaultOption = group.defaultOption {
                                playerItem?.select(defaultOption, in: group)
                            }else {
                                playerItem?.select(group.options.first, in: group)
                            }
                        }
                        self.audioLoaded = true
                    }
                }
                
            }
            
            NotificationCenter.default.addObserver(forName: .AVPlayerItemNewErrorLogEntry, object: player?.currentItem, queue: .main) { [self] _ in
                print(player?.currentItem?.errorLog()?.events.last?.errorComment)
            }
            
            if seekTimeS == 0 {
                do {
                    if let account = eluvio?.accountManager.currentAccount {
                        let progress = try eluvio?.fabric.getUserViewedProgress(address:account.getAccountAddress(), mediaId: currentVideo?.id ?? "")
                        debugPrint("Finsihed getting progress ", progress)
                        seekS(progress?.current_time_s ?? 0)
                    }
                }catch{
                    debugPrint(error)
                }
            }else {
                seekS(seekTimeS)
            }
            
            player?.play()
            print("*** PlayerView errors: ", player?.error)

            self.finishedObserver = PlayerFinishedObserver(player: player)
        }

    }
    
    func playFromBeginning() {
        guard let player = player else { return }
        player.seek(to: .zero)
        player.play()
    }
    
    func watchLive() {
        guard let player = player,
              let currentItem = player.currentItem else { return }
        
        // Seek to the live edge
        // For live streams, seekableTimeRanges contains the available time range
        if let seekableRange = currentItem.seekableTimeRanges.last?.timeRangeValue {
            let livePosition = CMTimeAdd(seekableRange.start, seekableRange.duration)
            player.seek(to: livePosition)
            player.play()
        }
    }
    
    func onPlayerProgress(_ progress: Double,_ currentTimeS: Double,_ durationS: Double) {
        debugPrint("progress observer mediaId ", currentVideo?.id)
        debugPrint("onPlayerProgress progress: ", progress)
        debugPrint("onPlayerProgress duration seconds: ", durationS)
        debugPrint("onPlayerProgress currentTime seconds: ", currentTimeS)

        guard let currentVideo = currentVideo else{
            return
        }
        
        if durationS.isNaN || durationS.isInfinite {
            return
        }
        
        let mediaProgress = MediaProgress(id: currentVideo.id ?? "",  duration_s: durationS, current_time_s: currentTimeS)

        do {
            if let account = eluvio?.accountManager.currentAccount {
                try eluvio?.fabric.setUserViewedProgress(address:account.getAccountAddress(), mediaId: currentVideo.id ?? "", progress:mediaProgress)
                debugPrint("Finsihed setting progress.")
            }
        }catch{
            print(error)
        }
    }
}
