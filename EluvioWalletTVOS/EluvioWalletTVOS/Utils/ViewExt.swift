import SwiftUI

extension View {
  /// Same as calling .onChange(of: value, initial: true, action).
  /// Just a convenience to remember calling initial: true
  func onAnyChange<V: Equatable>(of value: V, _ action: @escaping (V, V) -> Void) -> some View {
    return onChange(of: value, initial: true, action)
  }

  /// Starts a task when view appears and repeats it until repeatAction throws.
  /// The caller is responsible for calling Task.sleep
  func repeatTask(_ repeatAction: @escaping () async throws -> Void) -> some View {
    task {
      repeat {
        do {
          try await repeatAction()
        } catch {
          break
        }
      } while !Task.isCancelled
    }
  }

  /// We use this modifier for video players that interact with the Fabric, but don't automatically handle token expiration.
  ///
  /// API / image fetching should already handle token refreshing.
  func proactiveTokenRefresh() -> some View {
    modifier(ProactiveTokenRefreshModifier())
  }
}

// MARK: - Proactive Token Refresh

private struct ProactiveTokenRefreshModifier: ViewModifier {
  /// Refresh when 4 hours remain
  private let refreshThresholdS: TimeInterval = MockData.testShortTokens ? 60 : 4 * 60 * 60

  /// Tracks the account identity so the task restarts on login/logout
  private var accountId: String? { AccountStore.shared.account?.id }

  func body(content: Content) -> some View {
    content
      .task(id: accountId) {
        guard AccountStore.shared.account != nil else {
          debugPrint("Proactive refresh skipped: no account")
          return
        }

        repeat {
          do {
            guard let account = AccountStore.shared.account else { return }

            let expiresAtS = Double(account.expiresAt) / 1000
            let now = Date().timeIntervalSince1970
            let timeUntilExpiry = expiresAtS - now

            if timeUntilExpiry <= refreshThresholdS {
              debugPrint("Proactive token refresh triggered")
              await NetworkManager.shared.refreshToken()
              continue
            }

            let sleepDuration = timeUntilExpiry - refreshThresholdS
            debugPrint("Proactive token refresh queued up for \(sleepDuration) seconds from now.")
            try await Task.sleep(for: .seconds(sleepDuration))
          } catch {
            debugPrint("Proactive token refresh cancelled")
            return
          }
        } while !Task.isCancelled
      }
  }
}
