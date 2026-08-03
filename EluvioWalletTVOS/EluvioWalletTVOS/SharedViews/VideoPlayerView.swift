import AVKit
import EluvioCore
import MUXSDKStats
import SwiftUI

// MARK: - Stream Selector View Controller
class StreamSelectorViewController: UIHostingController<StreamSelectorView> {
  init(viewModel: VideoPlayerViewModel, eluvio: EluvioAPI) {
    super.init(rootView: StreamSelectorView(viewModel: viewModel, eluvio: eluvio))
    self.title = "Stream Selector"
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
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
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
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
      }
    }
    .frame(maxWidth: .infinity)
    .onAppear {
      // Focus removal: prevents list from jumping when switching streams
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
  let video: MediaPropertySectionMediaItem
  let isSelected: Bool
  @Environment(\.isFocused) var isFocused

  private let width: CGFloat = 280
  private let height: CGFloat = 150

  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        ScaledWebImage(url: video.thumbnail(), height: height)
          .placeholder(content: {
            Color.clear
              .overlay(
                Image(systemName: "play.rectangle.fill")
                  .font(.system(size: 60))
                  .foregroundColor(.white.opacity(0.5))
              )

          })
          .resizable()
          .aspectRatio(16 / 9, contentMode: .fill)

        if isSelected {
          Image(systemName: "play.circle.fill")
            .font(.system(size: 50))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.5), radius: 5)
        }
      }
      .frame(width: width, height: height)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .shadow(color: .black.opacity(0.3), radius: 10)

      Text(video.title ?? "")
        .foregroundColor(isFocused ? .black : .white)
        .lineLimit(1)
        .multilineTextAlignment(.center)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(width: width)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(
              isFocused ? Color.white : (isSelected ? Color.white.opacity(0.2) : Color.clear))
        )
        .padding(.top, 20)
    }
    .padding(5)
  }
}

// MARK: - View Model
class VideoPlayerViewModel: ObservableObject {
  var eluvio: EluvioAPI?
  var property: MediaProperty?
  @Published var videos: [MediaPropertySectionMediaItem] = []
  @Published var currentVideo: MediaPropertySectionMediaItem?
  var propertyId: String?
  @Published var player: AVPlayer?
  var playerViewController: AVPlayerViewController?
  var audioLoaded = false
  var finishedObserver = PlayerFinishedObserver()
  var seekTimeS: Double = 0
  var currentTimeS: Double = -1
  private var errorLogObserver: NSObjectProtocol?
  private var progressObserverToken: Any?

  var hasSeeked: Bool {
    return currentTimeS > seekTimeS
  }

  var progressCallback: ((_ progress: Double, _ currentTimeS: Double, _ durationS: Double) -> Void)?

  func seekS(_ s: Double) {
    debugPrint("PlayerView seekS ", s)
    self.player?.pause()
    self.player?.seek(to: CMTime(seconds: s, preferredTimescale: 1))
    self.player?.play()
  }

  func clear() {
    // Remove progress observer before releasing player
    if let token = progressObserverToken, let player = player {
      player.removeTimeObserver(token)
    }
    progressObserverToken = nil
    if let observer = errorLogObserver {
      NotificationCenter.default.removeObserver(observer)
      errorLogObserver = nil
    }
    // Detach MUX so it releases the player VC and its observers
    MUXSDKStats.destroyPlayer("mainPlayer")
    // Drop buffered media and the VC's player reference; MUX otherwise
    // keeps the VC (and everything it retains) alive
    player?.replaceCurrentItem(with: nil)
    playerViewController?.player = nil
    playerViewController = nil
    videos.removeAll()
    currentVideo = nil
    player = nil
    audioLoaded = false
    seekTimeS = 0
    currentTimeS = -1
    propertyId = nil
  }

  func selectVideo(_ video: MediaPropertySectionMediaItem) {
    self.player?.pause()
    // Remove progress observer from the old player before it's replaced below
    if let token = progressObserverToken, let oldPlayer = player {
      oldPlayer.removeTimeObserver(token)
      progressObserverToken = nil
    }
    currentVideo = video
    Task {
      do {
        guard let eluvio = eluvio else { return }
        let playerItem = try await video.playerItem(
          eluvio: eluvio, propertyId: propertyId ?? "")

        await MainActor.run {
          player = AVPlayer(playerItem: playerItem)
        }

        guard let playerViewController = self.playerViewController else {
          print("missing playerViewController")
          return
        }

        let initTime = NSNumber(value: Date().timeIntervalSince1970 * 1000)

        var objectId = ""
        var versionHash = ""
        var videoHostname = ""
        var userId = AccountStore.shared.account?.getAccountAddress() ?? ""
        var tenantId = ""
        var sessionId = ""
        var offering = ""

        if let asset = playerItem.asset as? AVURLAsset {
          let url = asset.url
          videoHostname = url.host() ?? ""

          // Position-independent: handles both /q/hq__... and /s/main/q/hq__... URL shapes
          if let hash = url.pathComponents.first(where: { $0.hasPrefix("hq__") }) {
            versionHash = hash
          }

          sessionId = url.queryParameters?["sid"] ?? ""

          let reg = /\/rep\/(playout|channel)\/([^\/]+)/
          if let match = url.absoluteString.firstMatch(of: reg) {
            offering = String(match.2)
          }

          if !versionHash.isEmpty {
            let dec = DecodeVersionHash(versionHash: versionHash)
            if !dec.objectId.isEmpty {
              objectId = dec.objectId
              let tenant = property?.tenant
              tenantId = tenant?.tenant_iten ?? tenant?.tenant_id ?? ""
            }
          }
        }

        let playerData = MUXSDKCustomerPlayerData(
          environmentKey: APP_CONFIG.network[eluvio.fabric.network]?.mux.env_key ?? "")
        playerData?.playerName = "AVPlayer"
        playerData?.subPropertyId = tenantId
        playerData?.viewerUserId = userId
        playerData?.playerInitTime = initTime

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = objectId
        videoData.videoVariantId = versionHash
        videoData.videoVariantName = offering
        videoData.videoTitle = self.currentVideo?.title
        videoData.videoCdn = videoHostname

        let viewData = MUXSDKCustomerViewData()
        viewData.viewSessionId = sessionId

        // Ensure MUX SDK initialization happens on the main thread
        await MainActor.run {
          if let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData, videoData: videoData, viewData: viewData,
            customData: nil, viewerData: nil)
          {
            let _ = MUXSDKStats.monitorAVPlayerViewController(
              playerViewController, withPlayerName: "mainPlayer", customerData: customerData)
            debugPrint("MUX initialized on main thread.")
          }
        }
      } catch {
        print("Error creating player", error)
        return
      }

      progressObserverToken = player?.addProgressObserver { [weak self] progress in
        guard let self = self else { return }
        self.currentTimeS = self.player?.currentItem?.currentTime().seconds ?? -1.0

        if self.currentTimeS == -1.0 {
          return
        }

        if let progressCallback = self.progressCallback {
          progressCallback(
            progress,
            self.player?.currentItem?.currentTime().seconds ?? 0.0,
            self.player?.currentItem?.duration.seconds ?? 0.0)
        } else {
          self.onPlayerProgress(
            progress,
            self.player?.currentItem?.currentTime().seconds ?? 0.0,
            self.player?.currentItem?.duration.seconds ?? 0.0)
        }

        if self.player?.status == .readyToPlay {
          if !self.audioLoaded {
            let playerItem = self.player?.currentItem
            if let group = playerItem?.asset.mediaSelectionGroup(
              forMediaCharacteristic: .audible)
            {
              if let defaultOption = group.defaultOption {
                playerItem?.select(defaultOption, in: group)
              } else {
                playerItem?.select(group.options.first, in: group)
              }
            }
            self.audioLoaded = true
          }
        }
      }

      // Remove previous error observer before adding a new one
      if let observer = errorLogObserver {
        NotificationCenter.default.removeObserver(observer)
      }
      errorLogObserver = NotificationCenter.default.addObserver(
        forName: .AVPlayerItemNewErrorLogEntry, object: player?.currentItem, queue: .main
      ) { [weak self] _ in
        if let comment = self?.player?.currentItem?.errorLog()?.events.last?.errorComment {
          print("AVPlayer error:", comment)
        }
      }

      // Seek to saved progress or specified time before playing
      if seekTimeS == 0 {
        do {
          if let addr = AccountStore.shared.account?.getAccountAddress() {
            let progress = try eluvio?.fabric.getUserViewedProgress(
              address: addr, mediaId: currentVideo?.id ?? "")
            let savedTime = progress?.current_time_s ?? 0
            if savedTime > 0 {
              await MainActor.run {
                self.seekS(savedTime)
              }
            }
          }
        } catch {
          debugPrint(error)
        }
      } else {
        await MainActor.run {
          seekS(seekTimeS)
        }
      }

      await MainActor.run {
        player?.play()
        if let error = player?.error {
          print("*** PlayerView error:", error)
        }
        self.finishedObserver = PlayerFinishedObserver(player: player)
      }
    }
  }

  func playFromBeginning() {
    guard let player = player else { return }
    player.seek(to: .zero)
    player.play()
  }

  func watchLive() {
    guard let player = player,
      let currentItem = player.currentItem
    else { return }

    if let seekableRange = currentItem.seekableTimeRanges.last?.timeRangeValue {
      let livePosition = CMTimeAdd(seekableRange.start, seekableRange.duration)
      player.seek(to: livePosition)
      player.play()
    }
  }

  func onPlayerProgress(_ progress: Double, _ currentTimeS: Double, _ durationS: Double) {
    guard let currentVideo = currentVideo else { return }

    if durationS.isNaN || durationS.isInfinite {
      return
    }

    let mediaProgress = MediaProgress(
      id: currentVideo.id ?? "", duration_s: durationS, current_time_s: currentTimeS)

    do {
      if let addr = AccountStore.shared.account?.getAccountAddress() {
        try eluvio?.fabric.setUserViewedProgress(
          address: addr, mediaId: currentVideo.id ?? "",
          progress: mediaProgress)
      }
    } catch {
      print(error)
    }
  }
}
