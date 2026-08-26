//
//  PlayerView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-10.
//

import AVKit
import Combine
import EluvioCore
import Foundation
import MUXSDKStats
import SwiftUI

class PlayerFinishedObserver: ObservableObject {
  @Published
  var publisher = PassthroughSubject<Void, Never>()
  private var cancellable: AnyCancellable?

  init(player: AVPlayer? = nil) {
    if let player = player {
      let item = player.currentItem

      cancellable = NotificationCenter.default.publisher(
        for: .AVPlayerItemDidPlayToEndTime, object: item
      ).sink { [weak self] _ in
        self?.publisher.send()
      }
    }
  }

  deinit {
    cancellable?.cancel()
  }
}

struct PlayerView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var viewState: ViewState
  @EnvironmentObject var router: Router
  @Environment(\.openURL) private var openURL
  @StateObject private var model = VideoPlayerViewModel()
  @StateObject private var upNext = UpNextCoordinator()
  var viewItem: MediaPropertySectionMediaItemViewModel?
  var playerItem: AVPlayerItem?
  var property: MediaProperty?
  var playout: PlayoutInfo?
  var context: PlaybackContext = .init()

  var mediaId: String { viewItem?.media_id ?? "" }
  var title: String { viewItem?.title ?? "" }
  var videoDescription: String { viewItem?.description ?? "" }
  var imageThumb: String { viewItem?.thumbnail ?? "" }
  @State var playerImageOverlayUrl = ""
  @State var playerTextOverlay = ""
  var seekTimeS: Double = 0
  var finished: Binding<Bool> = .constant(false)
  var progressCallback: ((_ progress: Double, _ currentTimeS: Double, _ durationS: Double) -> Void)?

  var backLink: String = ""
  var backLinkIcon: String = ""
  @State private var didSetup = false
  @State private var setupTask: Task<Void, Never>?

  var body: some View {
    AVPlayerView(viewModel: model)
      .ignoresSafeArea()
      .proactiveTokenRefresh()
      .onChange(of: AccountStore.shared.bestToken) { _, _ in
        Task {
          await model.player?.refreshCurrentItemAuth()
        }
      }
      .overlay {
        VStack {
          if !playerImageOverlayUrl.isEmpty {
            ScaledWebImage(url: playerImageOverlayUrl, height: 600)
              .resizable()
              .indicator(.activity)  // Activity Indicator
              .transition(.fade(duration: 0.5))
              .aspectRatio(contentMode: .fill)
              .frame(width: 600, height: 600)
              .cornerRadius(15)
          }

          if !playerTextOverlay.isEmpty {
            Text(playerTextOverlay)
              .foregroundColor(Color.white)
              .font(.title)
              .lineLimit(3)
              .frame(width: 1000, alignment: .center)
          }
        }
      }
      .onAppear {
        // The up next card is presented over this view, and tvOS can run onAppear again
        // around a presentation. Setting up twice would rebuild the item and re-seek to
        // saved progress, rewinding the video on its own.
        if didSetup { return }
        didSetup = true
        configure()
        setupTask = Task { await start() }
      }
      .onWillDisappear {
        print("PlayerView onDisappear")
        // The card is presented over the player, and presenting can fire this too; tearing
        // the player down here would drop the video sitting behind the card.
        if upNext.isOffering {
          return
        }
        // Stop the setup from loading and playing an item into a player that is being torn
        // down, and don't push the next item's player onto a screen the viewer has left.
        setupTask?.cancel()
        upNext.stop()
        model.releasePlayer()
        Task {
          try? await Task.sleep(for: .seconds(1.5))
          model.clear()
        }
        followBackLink()
      }
  }

  private func configure() {
    model.eluvio = eluvio
    model.property = property
    model.propertyId = property?.id
    model.seekTimeS = seekTimeS
    model.progressCallback = progressCallback
    model.onRemainingTime = { remainingS in upNext.trackTimeRemaining(remainingS) }
    model.onNearingEnd = { upNext.offerNow() }
    model.onFinished = {
      finished.wrappedValue = true
      upNext.offerNow()
    }

    upNext.configure(
      eluvio: eluvio,
      router: router,
      property: property,
      context: context,
      currentMediaId: { model.currentMediaId },
      presenter: { model.playerViewController },
      releasePlayer: { model.releasePlayer() })
  }

  /// Additional views and a property sidebar turn a single item into a set of streams. Either
  /// way the model plays it the same; the difference is only how many there are to switch
  /// between.
  private func start() async {
    debugPrint("*** PlayerView onAppear() ", self.property)

    if let rawMedia = viewItem?.mediaItem ?? viewItem?.sectionItem?.media {
      var streams: [MediaPropertySectionMediaItem] = []

      if rawMedia.additional_views != nil {
        streams = rawMedia.additionalViews()
      }

      if let propId = property?.id {
        streams += await MultiviewFetcher.shared.getPropertyMultiview(propertyId: propId)
      }

      // Remove duplicates with the primary media
      streams = streams.filter { $0.id != rawMedia.id }

      if !streams.isEmpty {
        if Task.isCancelled { return }
        // The item the viewer picked leads
        streams.insert(rawMedia, at: 0)
        model.load(videos: streams, starting: rawMedia)
        return
      }
    }

    var resolvedPlayerItem = self.playerItem
    if resolvedPlayerItem == nil, let playout {
      resolvedPlayerItem = await MakePlayerItemFromPlayoutInfo(
        playoutInfo: playout, fabricToken: eluvio.fabric.fabricToken,
        title: title, description: videoDescription, imageThumb: imageThumb)
    }

    guard let resolvedPlayerItem else {
      print("playerItem == nil")
      return
    }

    // Resolving the item above is slow enough that the view can be torn down while it runs.
    // Handing the item to the player after that resurrects a player nothing owns any more,
    // and it keeps playing with no way to stop it.
    if Task.isCancelled { return }
    model.load(item: resolvedPlayerItem, mediaId: mediaId, title: title)
  }

  private func followBackLink() {
    guard backLink != "", let url = URL(string: backLink) else { return }
    openURL(url) { accepted in
      print(accepted ? "Success" : "Failure")
      if !accepted {
        print("Could not open URL ", backLink)
      } else {
        self.presentationMode.wrappedValue.dismiss()
      }
    }
  }
}

struct PlayerView2: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @Environment(\.colorScheme) var colorScheme
  @State var player = AVPlayer()
  @State var playoutUrl: URL?
  @State var finishedObserver = PlayerFinishedObserver()
  @Binding var finished: Bool

  @State var playerItem: AVPlayerItem?
  @State private var progressObserverToken: Any?
  @Binding var currentTimeMS: Int64
  @Binding var durationMS: Int64
  @Binding var seekTimeMS: Int64
  @Binding var playPause: Bool

  init(
    playoutUrl: URL?, finished: Binding<Bool> = .constant(false),
    currentTimeMS: Binding<Int64> = .constant(0),
    durationMS: Binding<Int64> = .constant(0),
    seekTimeMS: Binding<Int64> = .constant(0),
    playPause: Binding<Bool> = .constant(false)
  ) {
    _finished = finished
    _currentTimeMS = currentTimeMS
    _durationMS = durationMS
    _seekTimeMS = seekTimeMS
    _playoutUrl = State(initialValue: playoutUrl)
    _playPause = playPause
  }

  func seekMS(_ ms: Double) {
    debugPrint("PlayerView seekMS ", ms)
    player.pause()
    player.seek(to: CMTime(seconds: ms / 1000, preferredTimescale: 1))
    player.play()
  }

  var body: some View {
    ZStack {
      VideoPlayer(player: player)
    }
    .onChange(of: seekTimeMS) {
      seekMS(Double(seekTimeMS))
    }
    .onChange(of: playPause) {
      if playPause {
        player.play()
      } else {
        player.pause()
      }
    }
    .ignoresSafeArea()
    .onReceive(finishedObserver.publisher) {
      debugPrint("Video Finished!")
      self.finished = true
    }
    .onAppear {
      debugPrint("PlayerView2 onAppear ", playoutUrl)
      guard let url = self.playoutUrl else { return }
      let urlAsset = AVURLAsset(url: url)
      self.playerItem = AVPlayerItem(asset: urlAsset)
      self.player.replaceCurrentItem(with: playerItem)
      self.finished = false
      // self.player.seek(to: CMTime(seconds:240, preferredTimescale: 1))
      self.player.play()
      self.finishedObserver = PlayerFinishedObserver(player: player)
      debugPrint("PlayerView onAppear finsihed.")

      progressObserverToken = player.addProgressObserver(intervalSeconds: 0.1) { _ in
        // debugPrint("Player progress: ", progress)
        // debugPrint("Player duration seconds: ", player.currentItem?.duration.seconds)
        // debugPrint("Player currentTime seconds: ", player.currentItem?.currentTime().seconds)

        let currentTimeS = player.currentItem?.currentTime().seconds ?? -1.0

        if currentTimeS == -1.0 {
          return
        }

        if currentTimeS.isNormal {
          currentTimeMS = Int64(currentTimeS * 1000)
        }
        let duration = player.currentItem?.duration.seconds ?? 0.0
        if duration.isNormal {
          self.durationMS = Int64(duration * 1000)
        }

        if player.timeControlStatus == .playing && !playPause {
          playPause = true
        }
      }
    }
    .onDisappear {
      if let token = progressObserverToken {
        player.removeTimeObserver(token)
        progressObserverToken = nil
      }
      player.pause()
      player.replaceCurrentItem(with: nil)
    }
  }

  func playerDidFinishPlaying(note _: NSNotification) {
    print("Video Finished")
  }
}

// MARK: - SwiftUI Previews

#Preview("Sound Player") {
  SoundPlayer(playoutUrl: nil)
    .padding()
    .background(Color.black)
}

struct SoundPlayer: View {
  @State var playoutUrl: URL?
  @State var finishedObserver = PlayerFinishedObserver()
  @Binding var finished: Bool
  @Binding var currentTimeMS: Int64
  @Binding var durationMS: Int64
  @Binding var seekTimeMS: Int64
  @Binding var playPause: Bool
  @State var audioPlayer: AVAudioPlayer?

  init(
    playoutUrl: URL?, finished: Binding<Bool> = .constant(false),
    currentTimeMS: Binding<Int64> = .constant(0),
    durationMS: Binding<Int64> = .constant(0),
    seekTimeMS: Binding<Int64> = .constant(0),
    playPause: Binding<Bool> = .constant(false)
  ) {
    _finished = finished
    _currentTimeMS = currentTimeMS
    _durationMS = durationMS
    _seekTimeMS = seekTimeMS
    _playoutUrl = State(initialValue: playoutUrl)
    _playPause = playPause
  }

  var body: some View {
    Image(systemName: playPause ? "mic.fill" : "mic")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 48, height: 48)
      .foregroundColor(playPause ? .blue : .white)
      .onChange(of: seekTimeMS) {
        AudioPlayer.pause()
        self.play()
      }
      .onChange(of: playPause) {
        self.play()
      }
      .onAppear {
        debugPrint("SoundPlayer on Appear ", playoutUrl)
        self.play()
      }
      .onDisappear {
        AudioPlayer.pause()
      }
  }

  func play() {
    if playPause {
      if let audioUrl = playoutUrl {
        AudioPlayer.play(url: audioUrl, seekS: Double(_seekTimeMS.wrappedValue) / 1000.0) {
          current, duration in
          debugPrint("AudioProgress: current \(current) duration \(duration)")
          if current.isNormal {
            self.currentTimeMS = Int64(current * 1000)
          }

          if duration.isNormal {
            self.durationMS = Int64(duration * 1000)
          }

          if currentTimeMS == durationMS {
            finished = true
          }
        }
      }
    } else {
      AudioPlayer.pause()
    }
  }

  func playerDidFinishPlaying(note _: NSNotification) {
    print("Video Finished")
  }
}
