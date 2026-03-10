import Alamofire
import Foundation
import SwiftyJSON

class NetworkManager {
  static let shared = NetworkManager()

  let configStore: FabricConfigStore
  let accountStore: AccountStore

  private var session: Session

  private init() {
    self.configStore = FabricConfigStore.shared
    self.accountStore = AccountStore.shared
    let interceptor = AuthInterceptor(accountStore: accountStore)
    self.session = Session(interceptor: interceptor)
  }

  func request<T: Decodable>(
    _ path: String,
    method: HTTPMethod = .get,
    parameters: Parameters = [:],
    body: (any Encodable)? = nil
  ) async throws -> T {
    var url = URL(string: configStore.apiBaseUrl + path.trimmingPrefix("/"))!
    if NetworkStore.shared.environment == .staging {
      url = url.appending(queryItems: [URLQueryItem(name: "env", value: "staging")])
    }
    let headers: HTTPHeaders = [
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer \(accountStore.bestToken)",
    ]

    var urlRequest = URLRequest(url: url)
    urlRequest.method = method
    urlRequest.headers = headers

    if let body {
      urlRequest.method = .post
      urlRequest.httpBody = try JSONEncoder().encode(body)
    } else if !parameters.isEmpty {
      if method == .get {
        let queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        urlRequest.url = url.appending(queryItems: queryItems)
      } else {
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters)
      }
    }

    let response = await session.request(urlRequest)
      .debugLog()
      .validate()
      .serializingDecodable(T.self)
      .response
    guard let value = response.value else {
      throw FabricError.unexpectedResponse(response.description)
    }
    return value
  }

  func refreshToken() async {
    guard let account = accountStore.account, let refreshToken = account.refreshToken else {
      // Not logged in, or not refresh token available
      return
    }
    try? await EluvioWalletTVOS.refreshToken(
      refreshToken: refreshToken, nonce: EluvioAPI.NONCE,
      fabricToken: account.fabricToken)
  }
}

class AuthInterceptor: RequestInterceptor {
  private var accountStore: AccountStore
  private var isRefreshing = false
  private let lock = NSLock()

  init(accountStore: AccountStore) {
    self.accountStore = accountStore
  }

  // Add auth header to requests
  func adapt(
    _ urlRequest: URLRequest, for session: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    var request = urlRequest
    let path = urlRequest.url?.relativePath ?? ""
    if path.contains("wlt/login/jwt") {
      // Only used in deeplink auth flow.
      //XXX: skip until we figure out where this is saved after the big refactor
      request.setValue("Bearer \("idToken-placeholder")", forHTTPHeaderField: "Authorization")
    } else if path.contains("wlt/sign/csat"),
      let clusterToken = accountStore.accountManager.currentAccount?.clusterToken
    {
      request.setValue("Bearer \(clusterToken)", forHTTPHeaderField: "Authorization")
    } else {
      let token =
        accountStore.accountManager.currentAccount?.fabricToken ?? accountStore.staticToken
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    completion(.success(request))
  }

  // Retry on 401 after refreshing token
  func retry(
    _ request: Request, for session: Session, dueTo error: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    guard let response = request.task?.response as? HTTPURLResponse,
      [401].contains(response.statusCode)
    else {
      completion(.doNotRetry)
      return
    }

    lock.lock()
    guard !isRefreshing else {
      lock.unlock()
      completion(.retryWithDelay(0.5))  // Wait for ongoing refresh
      return
    }
    isRefreshing = true
    lock.unlock()

    Task {
      do {
        guard let account = accountStore.account, let refToken = account.refreshToken else {
          // Not logged in, or not refresh token available
          completion(.doNotRetry)
          return
        }
        try await refreshToken(
          refreshToken: refToken, nonce: EluvioAPI.NONCE,
          fabricToken: account.fabricToken)
        lock.withLock {
          isRefreshing = false
        }
        completion(.retry)
      } catch {
        // Refresh failed. Sign out
        await SignOutHandler.signOut()
        lock.withLock {
          isRefreshing = false
        }
        completion(.doNotRetryWithError(error))
      }
    }
  }
}

func refreshToken(refreshToken: String, nonce: String, fabricToken: String) async throws {
  return try await withCheckedThrowingContinuation { continuation in
    debugPrint("****** refreshFabricToken ******")
    do {
      var endpoint = FabricConfigStore.shared.apiBaseUrl.appending("/wlt/refresh/csat")
      let environment = NetworkStore.shared.environment
      if environment != .prod {
        endpoint = endpoint.appending("?env=\(environment)")
      }

      let headers: HTTPHeaders = [
        "Accept": "application/json",
        "Content-Type": "application/json",
      ]

      let body: JSON = [
        "refresh_token": refreshToken,
        "nonce": nonce,
        "last_csat": fabricToken,
          // "exp": 30,  // Only for debugging short-lived tokens
      ]

      var request = URLRequest(url: URL(string: endpoint)!)
      request.httpMethod = "POST"
      request.headers = headers
      do {
        request.httpBody = try body.rawData()
      } catch {
        print("Could not serialize body", error)
      }

      AF.request(request)
        .debugLog()
        .responseString { response in
          var respJSON = JSON()
          do {
            respJSON = try JSON(data: response.data ?? Data())
          } catch {}

          debugPrint("refresh response: ", respJSON)

          switch response.result {
          case .success(let result):
            if respJSON["errors"].exists() {
              continuation.resume(
                throwing: FabricError.apiError(
                  code: response.response?.statusCode ?? 0,
                  response: respJSON, error: FabricError.unexpectedResponse("")))
            } else {

              let fabricToken = respJSON["token"].stringValue
              let refreshToken = respJSON["refresh_token"].stringValue
              let expiresAt = respJSON["expires_at"].int64Value

              if fabricToken.isEmpty || refreshToken.isEmpty || expiresAt == 0 {
                continuation.resume(throwing: FabricError.badInput(respJSON["error"].stringValue))
              }
              guard let account = AccountStore.shared.account else {
                continuation.resume(
                  throwing: FabricError.noLogin(
                    "Tried refreshing token while no account is available"))
                return
              }
              account.fabricToken = fabricToken
              account.refreshToken = refreshToken
              account.expiresAt = expiresAt

              continuation.resume()
            }

          case .failure(let error):
            var respJSON = JSON()
            do {
              respJSON = try JSON(data: response.data ?? Data())
            } catch {}
            continuation.resume(
              throwing: FabricError.apiError(
                code:
                  response.response?.statusCode ?? 0,
                response: respJSON, error: error))
          }
        }
    } catch {
      continuation.resume(throwing: error)
    }
  }
}
