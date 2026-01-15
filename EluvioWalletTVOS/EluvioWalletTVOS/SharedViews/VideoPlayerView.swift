import SwiftUI
import AVKit

// MARK: - Video Model
struct Video: Identifiable {
    let id = UUID()
    let title: String
    let thumbnail: String
    let url: URL
    let description: String
    let isLive: Bool
}

// MARK: - Video Player Container
struct VideoPlayerContainerView: View {
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        PlayerViewController(viewModel: viewModel)
            .ignoresSafeArea()
            .onAppear {
                viewModel.loadVideos()
            }
    }
}

// MARK: - AVPlayerViewController Wrapper
struct PlayerViewController: UIViewControllerRepresentable {
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = viewModel.player
        
        // Configure for tvOS
        controller.allowsPictureInPicturePlayback = false
        
        // Create default info view controller
        let defaultInfoVC = DefaultInfoViewController(viewModel: viewModel)
        
        // Create custom stream selector view controller
        let streamSelectorVC = StreamSelectorViewController(viewModel: viewModel)
        
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
    init(viewModel: VideoPlayerViewModel) {
        super.init(rootView: DefaultInfoView(viewModel: viewModel))
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
    
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            
            HStack(alignment: .top, spacing: 60) {
                // Thumbnail
                if let currentVideo = viewModel.currentVideo {
                    AsyncImage(url: URL(string: currentVideo.thumbnail)) { image in
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
                        Text(currentVideo.title)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Description
                        Text(currentVideo.description)
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
                        
                        if currentVideo.isLive {
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
    init(viewModel: VideoPlayerViewModel) {
        super.init(rootView: StreamSelectorView(viewModel: viewModel))
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
    @FocusState private var focusedVideo: UUID?
    
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
    let video: Video
    let isSelected: Bool
    @Environment(\.isFocused) var isFocused
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack {
                AsyncImage(url: URL(string: video.thumbnail)) { image in
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
            .frame(width: 240, height: 135)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color.white : (isSelected ? Color.blue : Color.clear), lineWidth: 6)
            )
            .shadow(color: .black.opacity(0.3), radius: 10)
            
            // Title with background
            Text(video.title)
                .font(.system(size: 16))
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(width: 240)
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
    @Published var videos: [Video] = []
    @Published var currentVideo: Video?
    @Published var player: AVPlayer?
    
    func loadVideos() {
        // Sample video data - replace with your actual video URLs
        videos = [
            Video(
                title: "Rugby Match 1",
                thumbnail: "https://picsum.photos/seed/rugby1/800/450",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                description: "An exciting rugby match featuring intense gameplay and spectacular moments. Watch as teams battle it out on the field.",
                isLive: false
            ),
            Video(
                title: "Rugby Match 2 - LIVE",
                thumbnail: "https://picsum.photos/seed/rugby2/800/450",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!,
                description: "Live coverage of the championship match. Don't miss a single moment of this thrilling encounter.",
                isLive: true
            ),
            Video(
                title: "Rugby Match 3",
                thumbnail: "https://picsum.photos/seed/rugby3/800/450",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
                description: "Highlights from yesterday's game with amazing tries and crucial defensive plays.",
                isLive: false
            ),
            Video(
                title: "Rugby Match 4",
                thumbnail: "https://picsum.photos/seed/rugby4/800/450",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!,
                description: "A classic match replay from the archives. Relive the greatest moments in rugby history.",
                isLive: false
            ),
            Video(
                title: "Rugby Match 5 - LIVE",
                thumbnail: "https://picsum.photos/seed/rugby5/800/450",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4")!,
                description: "Live stream of the international tournament final. Join us for edge-of-your-seat action.",
                isLive: true
            ),
            Video(
                title: "Rugby Match 6",
                thumbnail: "https://picsum.photos/seed/rugby6/800/450",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4")!,
                description: "Full match coverage with expert commentary and analysis throughout the game.",
                isLive: false
            )
        ]
        
        // Auto-play first video
        if let firstVideo = videos.first {
            selectVideo(firstVideo)
        }
    }
    
    func selectVideo(_ video: Video) {
        currentVideo = video
        player = AVPlayer(url: video.url)
        player?.play()
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
}
