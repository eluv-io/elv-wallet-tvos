import AuthenticationServices
import EluvioCore
import UIKit

/// iOS device-activation sign-in via `ASWebAuthenticationSession`. Presents a
/// system Safari-like view for the activation URL while `DeviceActivationFlow`
/// polls the wallet service in parallel. When polling completes the session is
/// programmatically cancelled and `onComplete` fires.
///
/// `callbackURLScheme` is required by ASWebAuth even though we don't actually
/// rely on a callback — the wallet redirects nowhere in this flow. The scheme
/// is just a placeholder; if the server ever adds real callback support, we'd
/// switch to a proper OAuth flow and drop the polling.
@MainActor
final class MobileSignIn: NSObject, ASWebAuthenticationPresentationContextProviding {
  private var session: ASWebAuthenticationSession?
  private var pollTask: Task<Void, Never>?
  /// Synchronously guards against re-entry — set on `start()` before the async
  /// network hop, cleared by the session completion handler or by an error
  /// path. Without this a double-tap kicks off two parallel auth sessions.
  private var isInProgress = false

  /// Invoked whenever a sign-in stops being in flight — success, user cancel,
  /// or error. Callers that show a spinner need this to unstick it.
  private var onDismiss: (@MainActor () -> Void)?

  /// Activation request started by `prefetch(property:)` — in flight or already
  /// settled. Consumed by the next `start(...)`.
  private var prefetchTask: Task<ActivationCode, Error>?
  /// Property `prefetchTask` was started for. A code only works for the property
  /// it was minted against, so a mismatch means discard and re-request.
  private var prefetchedFor: String?

  /// Request an activation code ahead of the tap. Nothing about the request
  /// depends on user input, so a screen that exists to offer sign-in can pay
  /// for the round trip on appear and leave the tap with nothing to wait on.
  /// tvOS does the equivalent in OryDeviceFlowView, which requests on appear
  /// so it has a URL to render as a QR code.
  func prefetch(property: MediaProperty) {
    guard prefetchTask == nil, !isInProgress else { return }
    prefetchedFor = property.id
    prefetchTask = Task {
      try await DeviceActivationFlow(property: property, shortenUrl: false).requestActivation()
    }
  }

  /// Begin sign-in for `property`. Calls `onComplete` once the wallet service
  /// accepts the activation, and `onDismiss` once the attempt ends for any
  /// reason. No-op if a sign-in is already in flight.
  func start(
    property: MediaProperty,
    onComplete: @MainActor @escaping () -> Void,
    onDismiss: (@MainActor () -> Void)? = nil
  ) {
    guard !isInProgress else { return }
    isInProgress = true
    self.onDismiss = onDismiss

    Task { [weak self] in
      guard let self else { return }
      let flow = DeviceActivationFlow(property: property, shortenUrl: false)
      do {
        let activation = try await self.takeActivation(for: property, flow: flow)
        guard let url = URL(string: activation.url) else {
          print("MobileSignIn: invalid activation URL")
          self.finish()
          return
        }
        self.present(
          url: url, flow: flow, activation: activation, onComplete: onComplete
        )
      } catch {
        print("MobileSignIn: couldn't request activation:", error)
        self.finish()
      }
    }
  }

  /// The activation to open, preferring a prefetched one. Codes are only good
  /// for five minutes, so one that went stale while the user sat on the welcome
  /// screen gets dropped rather than opening a dead login page. Either way the
  /// prefetch is consumed — a code is single-use.
  private func takeActivation(
    for property: MediaProperty,
    flow: DeviceActivationFlow
  ) async throws -> ActivationCode {
    let task = prefetchTask
    let matchesProperty = prefetchedFor == property.id
    prefetchTask = nil
    prefetchedFor = nil

    if let task, matchesProperty,
      let activation = try? await task.value, !activation.hasExpired
    {
      return activation
    }
    return try await flow.requestActivation()
  }

  /// Tear down any in-progress session. Useful for view-disappear cleanup.
  func cancel() {
    pollTask?.cancel()
    pollTask = nil
    session?.cancel()
    session = nil
    finish()
  }

  /// Clear the in-flight guard and notify the caller exactly once.
  private func finish() {
    isInProgress = false
    let dismiss = onDismiss
    onDismiss = nil
    dismiss?()
  }

  private func present(
    url: URL,
    flow: DeviceActivationFlow,
    activation: ActivationCode,
    onComplete: @MainActor @escaping () -> Void
  ) {
    let session = ASWebAuthenticationSession(
      url: url,
      callbackURLScheme: "elvwallet"
    ) { [weak self] _, _ in
      // Fires when the session ends (user cancel OR our programmatic cancel).
      // Just clean up — success path has already invoked onComplete.
      self?.pollTask?.cancel()
      self?.pollTask = nil
      self?.session = nil
      self?.finish()
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = true
    self.session = session

    pollTask = Task { [weak self] in
      do {
        try await flow.awaitCompletion(activation: activation)
        await MainActor.run {
          self?.session?.cancel()
          self?.session = nil
          onComplete()
        }
      } catch is CancellationError {
        // expected when user cancels the session
      } catch {
        print("MobileSignIn: polling failed:", error)
      }
    }

    session.start()
  }

  // MARK: - ASWebAuthenticationPresentationContextProviding

  // System guarantees this is called on the main thread.
  nonisolated func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    MainActor.assumeIsolated {
      UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
  }
}

private extension ActivationCode {
  /// `expiration` is a Unix timestamp in seconds; the service currently mints
  /// codes with a five-minute TTL. The margin keeps us from handing the web
  /// view a code that dies while the login page is still loading.
  var hasExpired: Bool {
    Date().timeIntervalSince1970 > Double(expiration) - 30
  }
}
