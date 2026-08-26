import AVKit
import Combine
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

/// Owns playback: the player, the controller AVKit renders it in, and everything that has to be
/// set up around a playing item — analytics, observers, resume position, progress reporting.
///
/// One item and several streams are the same thing here. Playback is either seeded with an item
/// whose playout is already resolved, or with media items it resolves itself and can switch
/// between; both end up in `attach`, so a stream swap and a fresh player run the same code.
class VideoPlayerViewModel: ObservableObject {
  var eluvio: EluvioAPI?
  var property: MediaProperty?
  @Published var videos: [MediaPropertySectionMediaItem] = []
  @Published var currentVideo: MediaPropertySectionMediaItem?
  var propertyId: String?
  @Published var player: AVPlayer?
  var playerViewController: AVPlayerViewController?
  var audioLoaded = false
  var seekTimeS: Double = 0
  var currentTimeS: Double = -1
  private var errorLogObserver: NSObjectProtocol?
  private var progressObserverToken: Any?
  private var endBoundaryToken: Any?
  private var finishedCancellable: AnyCancellable?

  /// Set when playback was seeded with an already-resolved item rather than a media item
  private var presetMediaId: String?
  private var presetTitle: String?
  /// What the running observers belong to, which during a stream switch is not yet the
  /// selected item
  private var playingMediaId: String = ""

  /// Called a breath before the current item plays out, with the player already paused.
  /// Letting an item finish makes AVKit reset its playhead to zero.
  var onNearingEnd: (() -> Void)?
  /// Called on each progress tick with the seconds left in the current item.
  var onRemainingTime: ((Double) -> Void)?
  /// Called when the current item does play to its end.
  var onFinished: (() -> Void)?
  /// How far before the end `onNearingEnd` fires
  private let nearingEndLeadS: Double = 0.5

  /// The item playing, which for multiview is whichever stream is selected.
  var currentMediaId: String { currentVideo?.id ?? presetMediaId ?? "" }

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

  // MARK: - Starting playback

  /// Plays an item whose playout is already resolved: the video destination, and the players
  /// presented directly with an AVPlayerItem.
  func load(item: AVPlayerItem, mediaId: String, title: String) {
    presetMediaId = mediaId
    presetTitle = title
    attach(playerItem: item)
  }

  /// Plays one of a set of media items, resolving playout as each is selected.
  func load(videos: [MediaPropertySectionMediaItem], starting: MediaPropertySectionMediaItem) {
    self.videos = videos
    selectVideo(starting)
  }

  func selectVideo(_ video: MediaPropertySectionMediaItem) {
    player?.pause()
    // Stop reporting before the switch, not after the incoming stream resolves: a tick landing
    // in between would file the outgoing item's position against the incoming one, which then
    // resumes where the last stream left off.
    removeObservers()
    currentVideo = video
    // Explicitly on main: the player, its controller and the analytics binding are all
    // main-thread only, and this runs from a nonisolated method
    Task { @MainActor in
      guard let eluvio = eluvio else { return }
      do {
        let playerItem = try await video.playerItem(
          eluvio: eluvio, propertyId: propertyId ?? "")
        if Task.isCancelled { return }
        attach(playerItem: playerItem)
      } catch {
        print("Error creating player", error)
      }
    }
  }

  /// Everything a newly playing item needs. One player is kept across items, so switching
  /// streams replaces the item rather than the player AVKit is rendering.
  private func attach(playerItem: AVPlayerItem) {
    removeObservers()
    if player == nil {
      player = AVPlayer()
    }
    player?.replaceCurrentItem(with: playerItem)
    audioLoaded = false
    playingMediaId = currentMediaId

    monitorWithMux(playerItem: playerItem)
    observeProgress()
    observeErrors()
    observeFinish()
    seekToStart()

    player?.play()
    if let error = player?.error {
      print("*** PlayerView error:", error)
    }
  }

  /// Resume where the viewer left off, unless a specific time was asked for.
  private func seekToStart() {
    if seekTimeS != 0 {
      seekS(seekTimeS)
      return
    }
    do {
      guard let addr = AccountStore.shared.account?.getAccountAddress() else { return }
      let progress = try eluvio?.fabric.getUserViewedProgress(
        address: addr, mediaId: currentMediaId)
      let savedTime = progress?.current_time_s ?? 0
      if savedTime > 0 {
        seekS(savedTime)
      }
    } catch {
      debugPrint(error)
    }
  }

  // MARK: - Releasing

  /// Releases the player but keeps the view controller, which may still be presenting
  /// something of its own.
  func releasePlayer() {
    removeObservers()
    player?.pause()
    // Detach MUX so it releases the player VC and its observers
    MUXSDKStats.destroyPlayer("mainPlayer")
    player?.replaceCurrentItem(with: nil)
  }

  func clear() {
    releasePlayer()
    playerViewController?.player = nil
    playerViewController = nil
    videos.removeAll()
    currentVideo = nil
    presetMediaId = nil
    presetTitle = nil
    playingMediaId = ""
    player = nil
    audioLoaded = false
    seekTimeS = 0
    currentTimeS = -1
    propertyId = nil
  }

  private func removeObservers() {
    if let token = progressObserverToken, let player = player {
      player.removeTimeObserver(token)
    }
    progressObserverToken = nil
    if let token = endBoundaryToken, let player = player {
      player.removeTimeObserver(token)
    }
    endBoundaryToken = nil
    if let observer = errorLogObserver {
      NotificationCenter.default.removeObserver(observer)
      errorLogObserver = nil
    }
    finishedCancellable?.cancel()
    finishedCancellable = nil
  }

  // MARK: - Observers

  private func observeProgress() {
    progressObserverToken = player?.addProgressObserver { [weak self] progress in
      guard let self = self else { return }
      self.currentTimeS = self.player?.currentItem?.currentTime().seconds ?? -1.0

      if self.currentTimeS == -1.0 {
        return
      }

      let durationS = self.player?.currentItem?.duration.seconds ?? 0
      if durationS.isFinite, durationS > self.nearingEndLeadS {
        if self.endBoundaryToken == nil {
          self.installEndBoundary(durationS: durationS)
        }
        self.onRemainingTime?(durationS - self.currentTimeS)
      }

      if let progressCallback = self.progressCallback {
        progressCallback(progress, self.currentTimeS, durationS)
      } else {
        self.onPlayerProgress(progress, self.currentTimeS, durationS)
      }

      if self.player?.status == .readyToPlay, !self.audioLoaded {
        self.selectDefaultAudio()
      }
    }
  }

  private func selectDefaultAudio() {
    let playerItem = player?.currentItem
    if let group = playerItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
      if let defaultOption = group.defaultOption {
        playerItem?.select(defaultOption, in: group)
      } else {
        playerItem?.select(group.options.first, in: group)
      }
    }
    audioLoaded = true
  }

  private func observeErrors() {
    errorLogObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemNewErrorLogEntry, object: player?.currentItem, queue: .main
    ) { [weak self] _ in
      if let comment = self?.player?.currentItem?.errorLog()?.events.last?.errorComment {
        print("AVPlayer error:", comment)
      }
    }
  }

  private func observeFinish() {
    finishedCancellable = NotificationCenter.default.publisher(
      for: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem
    ).sink { [weak self] _ in
      print("Finished!")
      self?.onFinished?()
    }
  }

  /// Fires `onNearingEnd` just before the item plays out, so a card can be offered while the
  /// item is merely paused near its end rather than finished.
  private func installEndBoundary(durationS: Double) {
    guard let player = player else { return }
    endBoundaryToken = player.addBoundaryTimeObserver(
      forTimes: [
        NSValue(time: CMTime(seconds: durationS - nearingEndLeadS, preferredTimescale: 600))
      ],
      queue: .main
    ) { [weak self] in
      guard let self = self else { return }
      self.player?.pause()
      self.onNearingEnd?()
    }
  }

  // MARK: - Analytics

  private func monitorWithMux(playerItem: AVPlayerItem) {
    guard let eluvio = eluvio, let playerViewController = playerViewController else {
      debugPrint("MUX skipped, no player view controller yet")
      return
    }

    let initTime = NSNumber(value: Date().timeIntervalSince1970 * 1000)
    var objectId = ""
    var versionHash = ""
    var videoHostname = ""
    var userId = ""
    var tenantId = ""
    var sessionId = ""
    var offering = ""

    if let address = AccountStore.shared.account?.getAccountAddress() {
      userId = Hash(address)
    }

    if let urlAsset = playerItem.asset as? AVURLAsset {
      debugPrint("Playout URL: ", urlAsset.url)
      videoHostname = urlAsset.url.host() ?? ""

      // Position-independent: handles both /q/hq__... and /s/main/q/hq__... URL shapes
      if let hash = urlAsset.url.pathComponents.first(where: { $0.hasPrefix("hq__") }) {
        versionHash = hash
      }

      sessionId = urlAsset.url.queryParameters?["sid"] ?? ""

      let reg = /\/rep\/(playout|channel)\/([^\/]+)/
      if let match = urlAsset.url.absoluteString.firstMatch(of: reg) {
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
    videoData.videoTitle = currentVideo?.title ?? presetTitle
    videoData.videoCdn = videoHostname

    let viewData = MUXSDKCustomerViewData()
    viewData.viewSessionId = sessionId

    if let customerData = MUXSDKCustomerData(
      customerPlayerData: playerData, videoData: videoData, viewData: viewData,
      customData: nil, viewerData: nil)
    {
      let _ = MUXSDKStats.monitorAVPlayerViewController(
        playerViewController, withPlayerName: "mainPlayer", customerData: customerData)
      debugPrint("MUX initialized.")
    }
  }

  // MARK: - Playback controls

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
    let mediaId = playingMediaId
    if mediaId.isEmpty {
      return
    }

    if durationS.isNaN || durationS.isInfinite {
      return
    }

    let mediaProgress = MediaProgress(
      id: mediaId, duration_s: durationS, current_time_s: currentTimeS)

    do {
      if let addr = AccountStore.shared.account?.getAccountAddress() {
        try eluvio?.fabric.setUserViewedProgress(
          address: addr, mediaId: mediaId, progress: mediaProgress)
      }
    } catch {
      print(error)
    }
  }
}
