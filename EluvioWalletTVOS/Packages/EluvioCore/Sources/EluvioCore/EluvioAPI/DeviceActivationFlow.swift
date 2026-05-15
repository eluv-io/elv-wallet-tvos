import Foundation
import UIKit

/// Device-activation sign-in flow, shared between TV (QR code) and mobile (WebView).
///
/// The UI presentation differs per app — TV renders the activation URL as a QR
/// code; mobile loads it in a WebView — but the URL construction, polling,
/// token storage, and post-auth property prefetch are identical and live here.
///
/// Typical usage:
///
///     let flow = DeviceActivationFlow(property: property, shortenUrl: true)
///     let activation = try await flow.requestActivation()
///     // Surface activation.code and activation.url in the UI.
///     try await flow.awaitCompletion(activation: activation)
///     // Navigate; AccountStore is now set and property page+sections are prefetched.
public struct DeviceActivationFlow: Sendable {
  public let property: MediaProperty
  public let shortenUrl: Bool

  public init(property: MediaProperty, shortenUrl: Bool) {
    self.property = property
    self.shortenUrl = shortenUrl
  }

  /// Request a new activation code from the wallet service. Returns the
  /// user-visible code, the secret passcode used for polling, and the URL
  /// the user must visit (already shortened if `shortenUrl` was true).
  public func requestActivation() async throws -> ActivationCode {
    let nonce = EluvioAPI.NONCE_HASHED

    var dest = FabricConfigStore.shared.walletUrl
    dest += "/login?pid=\(property.id)"
    dest += "&action=login&mode=login&response=code&source=code"
    dest += "&installId=\(nonce)&origin=\(UIDevice.current.name)"
    if MockData.testShortTokens {
      dest += "&ttl=0.025"  // Time in hours, only for debugging short-lived tokens
    }

    let response: ActivationCodeResponse = try await NetworkManager.shared.request(
      "/wlt/login/redirect/metamask",
      method: .post,
      parameters: ["op": "create", "dest": dest]
    )

    var url = response.url
    if !url.hasPrefix("http") {
      url = "https://" + url
    }
    if shortenUrl {
      url = await UrlShortener.shortenUrl(url)
    }

    return ActivationCode(
      code: response.id,
      passcode: response.passcode,
      url: url,
      expiration: response.expiration
    )
  }

  /// Polls every `interval` seconds until the activation is approved. On
  /// success, writes the `Account` to `AccountStore` and prefetches the
  /// property's first authorized page and sections.
  ///
  /// Cooperatively cancellable via `Task.cancel()`.
  public func awaitCompletion(
    activation: ActivationCode,
    interval: TimeInterval = 5.0
  ) async throws {
    while !Task.isCancelled {
      try await Task.sleep(for: .seconds(interval))
      if let payload = try? await checkAuthLogin(
        code: activation.code,
        passcode: activation.passcode
      ) {
        await applyToken(payload)
        await prefetchPropertyAndSections()
        return
      }
    }
    throw CancellationError()
  }

  private func applyToken(_ payload: CheckTokenPayload) async {
    let account = Account()
    account.type = property.accountType
    account.addr = payload.addr
    account.expiresAt = payload.expiresAt ?? Int64.max
    account.email = payload.email
    account.fabricToken = payload.token
    account.clusterToken = payload.clusterToken
    account.refreshToken = payload.refreshToken
    AccountStore.shared.account = account
  }

  private func prefetchPropertyAndSections() async {
    // Fetch a fresh copy — now that we have an auth token, permissions may differ.
    await PropertyStore.shared.fetchProperty(id: property.id)
    guard let property = PropertyStore.shared.getProperty(id: property.id) else { return }
    guard let page = try? await PropertyStore.shared.getFirstAuthorizedPage(property: property)
    else { return }
    await PropertyStore.shared.fetchSections(property: property, page: page)
  }
}

/// Activation code returned by [DeviceActivationFlow.requestActivation].
public struct ActivationCode: Sendable {
  /// User-visible code (shown next to the QR on TV; not shown on mobile).
  public let code: String
  /// Server-side secret sent alongside `code` when polling for token approval.
  public let passcode: String
  /// URL the user must visit to authorize. Already shortened if requested.
  public let url: String
  /// Unix timestamp at which `code` expires.
  public let expiration: Int64
}

/// Poll the wallet service for a token. Returns the payload on success, nil
/// if the user has not yet authorized.
private func checkAuthLogin(code: String, passcode: String) async throws -> CheckTokenPayload? {
  let response: CheckTokenResponse = try await NetworkManager.shared.request(
    "wlt/login/redirect/metamask/\(code)/\(passcode)"
  )
  return response.payload
}

public struct ActivationCodeResponse: Codable {
  public var id: String
  public var passcode: String
  public var url: String
  public var expiration: Int64
}

public struct CheckTokenResponse: Decodable {
  public var payload: CheckTokenPayload

  enum CodingKeys: CodingKey {
    case payload
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let payloadString = try container.decode(String.self, forKey: .payload)
    let payloadData = Data(payloadString.utf8)
    self.payload = try JSONDecoder().decode(CheckTokenPayload.self, from: payloadData)
  }
}

public struct CheckTokenPayload: Decodable {
  public var token: String
  public var expiresAt: Int64?
  public var refreshToken: String?
  public var addr: String
  public var clusterToken: String?
  public var email: String?
}
