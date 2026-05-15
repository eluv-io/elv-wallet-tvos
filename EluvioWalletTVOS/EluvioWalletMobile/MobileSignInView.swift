import EluvioCore
import SwiftUI

/// Mobile device-activation sign-in: loads the activation URL in a WebView and
/// polls DeviceActivationFlow for completion in parallel. Mirrors Android's
/// MobileSignInViewModel/SignInFragment pattern.
struct MobileSignInView: View {
  let property: MediaProperty
  /// Called when sign-in succeeds. The caller is responsible for navigation.
  var onComplete: () -> Void

  @State private var activation: ActivationCode?
  @State private var pollTask: Task<Void, Never>?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if let activation {
          WebView(url: activation.url)
            .ignoresSafeArea(edges: .bottom)
        } else {
          ProgressView("Requesting sign-in URL…")
        }
      }
      .navigationTitle("Sign In")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .task { await beginSignIn() }
    .onDisappear { pollTask?.cancel() }
  }

  private func beginSignIn() async {
    let flow = DeviceActivationFlow(property: property, shortenUrl: false)
    do {
      let act = try await flow.requestActivation()
      activation = act
      pollTask = Task {
        do {
          try await flow.awaitCompletion(activation: act)
          await MainActor.run { onComplete() }
        } catch is CancellationError {
          // expected on sheet dismiss
        } catch {
          print("Sign-in polling failed:", error)
        }
      }
    } catch {
      print("Couldn't request activation code:", error)
    }
  }
}
