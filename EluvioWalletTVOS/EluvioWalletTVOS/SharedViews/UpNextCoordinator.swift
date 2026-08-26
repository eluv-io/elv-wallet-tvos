//
//  UpNextCoordinator.swift
//  EluvioWalletTVOS
//

import AVKit
import EluvioCore
import SwiftUI

/// Runs the Up Next offer: asking the store what plays next, putting the card up over the
/// player, and taking the viewer wherever their answer leads.
///
/// This lives outside `PlayerView` because none of it is view state — the card is a UIKit
/// presentation over the player controller, so nothing here is read while rendering. What the
/// player has to supply is the handful of things only it knows: which controller is on screen,
/// which item is playing, and how to let go of the player before the next item takes over.
@MainActor
final class UpNextCoordinator: ObservableObject {
  /// How long before the end the store is asked what plays next
  private let prefetchLeadS: Double = 30
  /// How far back from the end counts as watching again rather than resuming the ending,
  /// which is what makes a previous Cancel stale
  private let reofferS: Double = 5

  private var eluvio: EluvioAPI?
  private var router: Router?
  private var property: MediaProperty?
  private var context: PlaybackContext = .init()
  private var currentMediaId: () -> String = { "" }
  private var presenter: () -> UIViewController? = { nil }
  private var releasePlayer: () -> Void = {}

  private var offered: MediaPropertySectionMediaItem?
  private var pending: MediaPropertySectionMediaItem?
  private var prefetchedPlayout: (id: String, playout: PlayoutInfo)?
  private var host: UIHostingController<AnyView>?
  private var cancelled = false
  private var wantsOffer = false
  private var offerTask: Task<Void, Never>?
  private var playoutTask: Task<Void, Never>?
  private var advanceTask: Task<Void, Never>?

  /// True while the card or its loading state is up. The player uses this to leave itself
  /// alone: the video behind the card has to outlive a lifecycle callback or two.
  var isOffering: Bool { offered != nil }

  /// False once the viewer has declined this ending, or while the card is already up. The
  /// player reads it to decide whether stopping short of the end is worth doing.
  var wantsToOffer: Bool { !cancelled && offered == nil }

  /// - Parameters:
  ///   - currentMediaId: read each time, since multiview can be showing any of its streams.
  ///   - presenter: the controller on screen, which the card is presented over.
  ///   - releasePlayer: lets go of the finished player before the next item takes over.
  func configure(
    eluvio: EluvioAPI,
    router: Router,
    property: MediaProperty?,
    context: PlaybackContext,
    currentMediaId: @escaping () -> String,
    presenter: @escaping () -> UIViewController?,
    releasePlayer: @escaping () -> Void
  ) {
    self.eluvio = eluvio
    self.router = router
    self.property = property
    self.context = context
    self.currentMediaId = currentMediaId
    self.presenter = presenter
    self.releasePlayer = releasePlayer
  }

  /// Called with the seconds left in the item, from whichever player is running.
  func trackTimeRemaining(_ remainingS: Double) {
    if remainingS < prefetchLeadS {
      prefetchNextItem()
    }
    // Cancel declines the offer made at that ending. Going back into the item and watching
    // up to the end again earns a fresh offer; resuming the last moment of it does not.
    if cancelled, remainingS > reofferS {
      debugPrint("Up next re-armed, ", remainingS, " left")
      cancelled = false
    }
  }

  /// Playback has reached the end: offer the next item, if there is one to offer.
  func offerNow() {
    guard !cancelled, offered == nil, property != nil else { return }
    wantsOffer = true
    // A no-op unless the item was too short for the prefetch window
    prefetchNextItem()
    offer()
  }

  /// Drops any pending work and takes the card down. For a real exit, not for a lifecycle
  /// callback that fires while the card is up.
  func stop() {
    offerTask?.cancel()
    playoutTask?.cancel()
    advanceTask?.cancel()
    dismissHost()
  }

  // MARK: - Asking

  /// Asks the store while the video is still running, so the card can go up the moment
  /// playback stops instead of after a round trip. Asked once per playback.
  private func prefetchNextItem() {
    guard let property, offerTask == nil else { return }
    offerTask = Task {
      // Nothing to play is the normal answer for an item outside a sequential run
      let next = await AutoplayStore.shared.nextItem(
        propertyId: property.id,
        mediaId: currentMediaId(),
        sectionId: context.sectionId,
        mediaListId: context.mediaListId)
      guard !Task.isCancelled else { return }
      debugPrint("Up next prefetched item ", next?.id ?? "none")
      pending = next
      // Playback can reach the end before the answer does
      offer()
    }
  }

  /// Puts the card up, once playback has reached the end and the store has answered —
  /// whichever order those happen in.
  private func offer() {
    guard wantsOffer, !cancelled, offered == nil, let next = pending, let property else { return }
    debugPrint("Up next offering ", next.id, next.title)
    offered = next
    present(
      AnyView(
        UpNextView(
          item: next,
          onCancel: { [weak self] in self?.decline() },
          onPlay: { [weak self] in self?.play(next) }
        )))
    // No point resolving playout for something the viewer has to buy first, or for an event
    // that has not started
    if next.resolvedPermissions?.authorized != false, !next.isUpcoming {
      prefetchPlayout(for: next, property: property)
    }
  }

  /// Resolves the next item's playout while the countdown runs, so Play now usually has
  /// nothing to wait for. A failure just leaves the slower path to report it properly.
  private func prefetchPlayout(for item: MediaPropertySectionMediaItem, property: MediaProperty) {
    guard let eluvio else { return }
    prefetchedPlayout = nil
    playoutTask = Task {
      do {
        let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(
          propertyId: property.id, mediaId: item.id)
        let playout = try ResolveMediaPlayoutInfo(
          fabric: eluvio.fabric, optionsJson: optionsJson)
        if Task.isCancelled { return }
        prefetchedPlayout = (id: item.id, playout: playout)
        debugPrint("Up next prefetched playout for ", item.id)
      } catch {
        debugPrint("Up next prefetch failed ", error)
      }
    }
  }

  // MARK: - Answering

  private func decline() {
    dismissHost()
    offered = nil
    cancelled = true
    offerTask?.cancel()
    playoutTask?.cancel()
    prefetchedPlayout = nil
  }

  /// Back during the load: drop the pending item and leave the player, which has already
  /// given up its own media by this point.
  private func cancelLoad() {
    debugPrint("Up next load cancelled")
    advanceTask?.cancel()
    playoutTask?.cancel()
    dismissHost()
    offered = nil
    router?.navigateBack()
  }

  private func play(_ item: MediaPropertySectionMediaItem) {
    guard let property, let router, let eluvio else { return }
    debugPrint("Up next playing ", item.id, item.title)
    let viewItem = MediaPropertySectionMediaItemViewModel.create(media: item)
    // The finished video goes now either way, rather than sitting on its last frame
    releasePlayer()

    // A live event that has not started yet gets the countdown screen, which is what tapping
    // it anywhere else in the app does. Autoplay returns these deliberately.
    if item.isUpcoming {
      debugPrint("Up next item has not started, showing the countdown ", item.id)
      leaveCard()
      router.replace(
        with: .upcomingLiveEvent(
          UpcomingVideoParams(mediaItem: item, propertyId: property.id)))
      return
    }

    // Autoplay hands back items the viewer is not entitled to — it deliberately does not
    // filter on permissions — so the gate takes the player's place, the same one tapping a
    // locked card would reach, rather than playback failing on a link it cannot resolve.
    if let permission = item.resolvedPermissions, !permission.authorized {
      debugPrint("Up next item is not authorized, showing the gate ", item.id)
      leaveCard()
      do {
        try handleUnauthorizedItem(
          router: router, eluvio: eluvio, property: property,
          pageId: context.pageId, sectionId: context.sectionId,
          viewItem: viewItem, itemId: item.id, itemType: item.type,
          mediaItem: item, permission: permission)
      } catch {
        print("Could not build the purchase gate for the next item ", error)
        router.replace(with: .errorView("Could not access media."))
      }
      return
    }

    // Prefetched during the countdown: nothing to wait for
    if let prefetched = prefetchedPlayout, prefetched.id == item.id {
      leaveCard()
      router.replace(
        with: .video(
          VideoParams(
            viewItem: viewItem, playout: prefetched.playout, property: property,
            context: context)))
      return
    }

    // Otherwise the presentation stays up, showing the loading state in the card's place so
    // the wait is still focusable and Back still works
    present(AnyView(UpNextLoadingView(onCancel: { [weak self] in self?.cancelLoad() })))
    advanceTask = Task {
      await handleVideoItem(
        router: router, eluvio: eluvio, property: property,
        viewItem: viewItem, mediaItem: item, context: context)
    }
  }

  private func leaveCard() {
    dismissHost()
    offered = nil
  }

  // MARK: - Presentation

  /// Presented by the player controller itself, over its content rather than instead of it. A
  /// SwiftUI fullScreenCover presents opaquely, so UIKit ran the player's disappear/appear
  /// lifecycle around it — which made AVKit pause and resume playback, and left its own
  /// controls with stale focus once they had been opened. Over-full-screen keeps the player on
  /// screen and lets AVKit restore its own focus.
  private func present(_ content: AnyView) {
    if let host {
      host.rootView = content
      return
    }
    let host = UIHostingController(rootView: content)
    host.modalPresentationStyle = .overFullScreen
    host.view.backgroundColor = .clear
    self.host = host
    // The player may already be presenting something of its own — the subtitle or info panel
    // — and a controller can only present one thing at a time, so presenting from the player
    // itself would silently do nothing. Go from whatever is topmost.
    guard var from = presenter() else { return }
    while let presented = from.presentedViewController {
      from = presented
    }
    from.present(host, animated: true)
  }

  private func dismissHost() {
    host?.dismiss(animated: true)
    host = nil
  }
}
