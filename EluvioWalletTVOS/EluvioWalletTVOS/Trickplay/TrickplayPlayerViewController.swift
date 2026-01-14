//
//  TrickplayPlayerViewController.swift
//  EluvioWalletTVOS
//
//  AVPlayerViewController wrapper with trickplay thumbnail support
//

import UIKit
import AVKit
import Combine

/// Custom AVPlayerViewController that displays trickplay thumbnails during scrubbing
class TrickplayPlayerViewController: AVPlayerViewController {

    private let trickplayManager = TrickplayManager()
    private var thumbnailView: ScrubThumbnailUIView?
    private var timeObserverToken: Any?
    private var rateObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()

    // Track scrubbing state
    private var lastKnownTime: CMTime = .zero
    private var lastUpdateTime: Date = Date()
    private var isScrubbing = false
    private var scrubCheckTimer: Timer?

    // Duration for thumbnail display
    private var videoDuration: Double = 0

    // Prevent multiple loads
    private var thumbnailsLoaded = false
    private var observersSetup = false

    override func viewDidLoad() {
        super.viewDidLoad()
        debugPrint("TrickplayPlayerViewController: viewDidLoad")
        setupThumbnailView()
    }

    private func setupThumbnailView() {
        debugPrint("TrickplayPlayerViewController: setupThumbnailView")
        let thumbView = ScrubThumbnailUIView(frame: .zero)
        thumbView.thumbnailWidth = 400 // Larger for tvOS
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(thumbView)

        NSLayoutConstraint.activate([
            thumbView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thumbView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            thumbView.heightAnchor.constraint(equalToConstant: 300)
        ])

        thumbnailView = thumbView
        // Bring thumbnail view to front
        view.bringSubviewToFront(thumbView)
    }

    private func setupObservers() {
        guard !observersSetup, let player = player else {
            debugPrint("TrickplayPlayerViewController: setupObservers - skipping (observersSetup=\(observersSetup), player=\(String(describing: player))")
            return
        }

        debugPrint("TrickplayPlayerViewController: setupObservers - setting up observers")
        observersSetup = true

        // Observe player rate changes
        rateObserver = player.observe(\.rate, options: [.new, .old]) { [weak self] player, change in
            self?.handleRateChange(player: player, newRate: change.newValue ?? 0)
        }

        // Add periodic time observer for scrub detection
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleTimeUpdate(time: time)
        }

        // Timer to check for scrubbing state
        scrubCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkScrubbingState()
        }
    }

    private func handleRateChange(player: AVPlayer, newRate: Float) {
        debugPrint("TrickplayPlayerViewController: Rate changed to \(newRate)")

        // When rate is not 1 (playing normally), we might be scrubbing or paused
        if newRate == 0 {
            // Player is paused - could be scrubbing
            lastUpdateTime = Date()
        } else if newRate != 1.0 && newRate != 0 {
            // Fast forward or rewind - show thumbnails
            debugPrint("TrickplayPlayerViewController: Fast forward/rewind detected, showing thumbnails")
            isScrubbing = true
            showThumbnailForCurrentTime()
        } else {
            // Normal playback
            hideThumbnail()
            isScrubbing = false
        }
    }

    private func handleTimeUpdate(time: CMTime) {
        guard isScrubbing || player?.rate == 0 else { return }

        // Update video duration if needed
        if let duration = player?.currentItem?.duration, duration.isNumeric {
            videoDuration = CMTimeGetSeconds(duration)
        }

        // Check if time changed significantly while paused (user is scrubbing)
        let timeDiff = abs(CMTimeGetSeconds(time) - CMTimeGetSeconds(lastKnownTime))
        let elapsedRealTime = Date().timeIntervalSince(lastUpdateTime)

        if timeDiff > 0.5 && elapsedRealTime < 0.5 && player?.rate == 0 {
            // Time jumped while paused - user is scrubbing
            debugPrint("TrickplayPlayerViewController: Time jump detected while paused (scrubbing)")
            isScrubbing = true
            showThumbnailForTime(time)
        }

        lastKnownTime = time
        lastUpdateTime = Date()
    }

    private func checkScrubbingState() {
        guard let player = player else { return }

        // Detect scrubbing by checking if time is changing while rate is 0 or not 1
        if player.rate == 0 {
            let currentTime = player.currentTime()
            let timeDiff = abs(CMTimeGetSeconds(currentTime) - CMTimeGetSeconds(lastKnownTime))

            if timeDiff > 0.2 {
                isScrubbing = true
                showThumbnailForTime(currentTime)
            } else if Date().timeIntervalSince(lastUpdateTime) > 0.5 && isScrubbing {
                // User stopped scrubbing
                hideThumbnail()
                isScrubbing = false
            }
        } else if abs(player.rate) > 1.0 {
            // Fast forward/rewind
            isScrubbing = true
            showThumbnailForCurrentTime()
        }
    }

    private func showThumbnailForCurrentTime() {
        guard let player = player else { return }
        showThumbnailForTime(player.currentTime())
    }

    private func showThumbnailForTime(_ time: CMTime) {
        debugPrint("TrickplayPlayerViewController: showThumbnailForTime - hasThumbnails=\(trickplayManager.hasThumbnails), duration=\(videoDuration)")

        guard trickplayManager.hasThumbnails else {
            debugPrint("TrickplayPlayerViewController: No thumbnails available")
            return
        }
        guard videoDuration > 0 else {
            debugPrint("TrickplayPlayerViewController: Duration is 0")
            return
        }

        let timeSeconds = CMTimeGetSeconds(time)
        let positionMs = Int64(timeSeconds * 1000)
        let fraction = CGFloat(timeSeconds / videoDuration)

        debugPrint("TrickplayPlayerViewController: Getting thumbnail for position \(positionMs)ms, fraction=\(fraction)")

        if let thumbnail = trickplayManager.getThumbnail(forPosition: positionMs) {
            debugPrint("TrickplayPlayerViewController: Got thumbnail, showing it")
            thumbnailView?.updateThumbnail(image: thumbnail, fraction: fraction)
            thumbnailView?.show()
        } else {
            debugPrint("TrickplayPlayerViewController: No thumbnail for position \(positionMs)ms")
        }
    }

    private func hideThumbnail() {
        thumbnailView?.hide()
    }

    /// Load trickplay thumbnails from WebVTT URL
    /// - Parameter webVttUrl: The WebVTT URL
    func loadTrickplayThumbnails(webVttUrl: String) {
        guard !thumbnailsLoaded else {
            debugPrint("TrickplayPlayerViewController: Thumbnails already loaded, skipping")
            return
        }

        debugPrint("TrickplayPlayerViewController: loadTrickplayThumbnails - URL: \(webVttUrl)")
        thumbnailsLoaded = true

        // Setup observers now that we're about to have thumbnails
        setupObservers()

        Task {
            await trickplayManager.loadThumbnails(webVttUrl: webVttUrl)
            debugPrint("TrickplayPlayerViewController: Thumbnails loaded, hasThumbnails=\(trickplayManager.hasThumbnails)")
        }
    }

    /// Set auth token for thumbnail requests
    func setAuthToken(_ token: String?) {
        debugPrint("TrickplayPlayerViewController: setAuthToken - hasToken=\(token != nil)")
        trickplayManager.setAuthToken(token)
    }

    /// Clear loaded thumbnails
    func clearThumbnails() {
        trickplayManager.clear()
        thumbnailsLoaded = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanup()
    }

    private func cleanup() {
        scrubCheckTimer?.invalidate()
        scrubCheckTimer = nil

        if let token = timeObserverToken, let player = player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }

        rateObserver?.invalidate()
        rateObserver = nil

        cancellables.removeAll()
        observersSetup = false
    }

    deinit {
        cleanup()
    }
}
