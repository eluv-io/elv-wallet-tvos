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

  /// Begin sign-in for `property`. Calls `onComplete` once the wallet service
  /// accepts the activation (i.e. `AccountStore` has been populated and the
  /// property's first page+sections have been prefetched).
  func start(
    property: MediaProperty,
    onComplete: @MainActor @escaping () -> Void
  ) {
    Task { [weak self] in
      let flow = DeviceActivationFlow(property: property, shortenUrl: false)
      do {
        let activation = try await flow.requestActivation()
        guard let url = URL(string: activation.url) else {
          print("MobileSignIn: invalid activation URL")
          return
        }
        self?.present(
          url: url, flow: flow, activation: activation, onComplete: onComplete
        )
      } catch {
        print("MobileSignIn: couldn't request activation:", error)
      }
    }
  }

  /// Tear down any in-progress session. Useful for view-disappear cleanup.
  func cancel() {
    pollTask?.cancel()
    pollTask = nil
    session?.cancel()
    session = nil
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
