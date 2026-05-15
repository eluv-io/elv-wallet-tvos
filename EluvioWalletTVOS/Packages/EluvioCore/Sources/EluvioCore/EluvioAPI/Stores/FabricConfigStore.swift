import Alamofire
import Foundation
import Observation
import UIKit

@Observable
public class FabricConfigStore {
  public static let shared = FabricConfigStore()

  private static let configKey = "persisted_fabric_config"

  public private(set) var config: FabricConfiguration! {
    didSet {
      guard let data = try? JSONEncoder().encode(config) else { return }
      let network = NetworkStore.shared.selectedNetwork
      UserDefaults.standard.set(data, forKey: "\(FabricConfigStore.configKey)_\(network.rawValue)")
    }
  }
  private var refreshTask: Task<Void, Never>?

  public var apiBaseUrl: String {
    config.getAuthServices().first?.ensuringSuffix("/") ?? ""
  }

  public var fabricBaseUrl: String {
    guard let base = config.getFabricAPI().first?.ensuringSuffix("/") else {
      debugPrint("WARNING: Failed to get fabric base URL from Config")
      return ""
    }
    guard let qspace = config.qspace.names.first else {
      debugPrint("WARNING: Failed to get qspace name from Config")
      return ""
    }
    return base + "s/" + qspace + "/"
  }

  public var walletUrl: String {
    APP_CONFIG.network[NetworkStore.shared.selectedNetwork.rawValue]!.wallet_url
  }

  private init() {
    config = FabricConfigStore.loadPersistedConfig(for: NetworkStore.shared.selectedNetwork)
  }

  /// Fetch config from server, then start the background refresh loop.
  /// Call once at app startup before displaying any UI.
  /// If the network fetch fails and we have no persisted config, falls back to a hardcoded config so the app can still function.
  public func bootstrap() async {
    let networkStore = NetworkStore.shared
    await refreshConfig(for: networkStore.selectedNetwork)
    if config == nil {
      print("Initial config fetch failed and no persisted config — using fallback config")
      config = fallbackConfig(for: networkStore.selectedNetwork)
    }
    startRefreshLoop(networkStore)
    registerLifecycleObservers(networkStore)
  }

  private func registerLifecycleObservers(_ networkStore: NetworkStore) {
    NotificationCenter.default.addObserver(
      forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.startRefreshLoop(networkStore)
    }
    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.stopRefreshLoop()
    }
  }

  private func startRefreshLoop(_ networkStore: NetworkStore) {
    guard refreshTask == nil else { return }
    refreshTask = Task {
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .minutes(3))
          await refreshConfig(for: networkStore.selectedNetwork)
        } catch {
          break
        }
      }
    }
  }

  private func stopRefreshLoop() {
    refreshTask?.cancel()
    refreshTask = nil
  }

  public func refreshConfig(for network: AppMode) async {
    guard let url = APP_CONFIG.network[network.rawValue]?.config_url else { return }
    let result = await AF.request(url)
      .serializingDecodable(FabricConfiguration.self)
      .result
    switch result {
    case .success(let value):
      await MainActor.run {
        config = value
      }
      debugPrint("New config fetched: \(value)")
    default:
      print("Failed to fetch config")
    }
  }

  private static func loadPersistedConfig(for network: AppMode) -> FabricConfiguration? {
    guard let data = UserDefaults.standard.data(forKey: "\(configKey)_\(network.rawValue)") else {
      return nil
    }
    return try? JSONDecoder().decode(FabricConfiguration.self, from: data)
  }
}

/// Hardcoded fallback used only if the initial network fetch fails (e.g. offline on first launch).
private func fallbackConfig(for network: AppMode) -> FabricConfiguration {
  switch network {
  case .main:
    return FabricConfiguration(
      nodeID: "inod2cFoGLUCfP9WFAKf6PrsQ1tXDTpW",
      network: Network(
        seedNodes: SeedNodes(
          fabricAPI: [
            "https://host-76-74-91-6.contentfabric.io",
            "https://host-76-74-28-232.contentfabric.io",
            "https://host-76-74-91-10.contentfabric.io",
          ],
          ethereumAPI: [
            "https://host-76-74-91-2.contentfabric.io/eth/",
            "https://host-76-74-91-8.contentfabric.io/eth/",
            "https://host-76-74-91-11.contentfabric.io/eth/",
          ]
        ),
        services: Services(
          authorityService: [
            "https://host-76-74-28-232.contentfabric.io/as",
            "https://host-76-74-29-8.contentfabric.io/as",
            "https://host-76-74-29-40.contentfabric.io/as",
          ],
          ethereumAPI: [
            "https://host-76-74-91-2.contentfabric.io/eth/",
            "https://host-76-74-91-8.contentfabric.io/eth/",
            "https://host-76-74-91-11.contentfabric.io/eth/",
          ],
          fabricAPI: [
            "https://host-76-74-91-6.contentfabric.io",
            "https://host-76-74-28-232.contentfabric.io",
            "https://host-76-74-91-10.contentfabric.io",
          ],
          search: [
            "https://host-76-74-29-4.contentfabric.io/",
            "https://host-76-74-29-35.contentfabric.io/",
          ]
        )
      ),
      qspace: Qspace(
        id: "ispc2RUoRe9eR2v33HARQUVSp1rYXzw1",
        version: "BaseContentSpace20191203120000PO",
        type: "Ethereum",
        names: ["main"]
      ),
    )
  case .demo:
    return FabricConfiguration(
      nodeID: "inod4T4nRPqKa3MK8JrP89Ghggio2eWQ",
      network: Network(
        seedNodes: SeedNodes(
          fabricAPI: [
            "https://host-76-74-28-233.contentfabric.io",
            "https://host-76-74-28-235.contentfabric.io",
            "https://host-76-74-28-227.contentfabric.io",
          ],
          ethereumAPI: [
            "https://host-76-74-28-235.contentfabric.io/eth/",
            "https://host-76-74-28-227.contentfabric.io/eth/",
            "https://host-76-74-28-233.contentfabric.io/eth/",
          ]
        ),
        services: Services(
          authorityService: [
            "https://host-76-74-28-227.contentfabric.io/as"
          ],
          ethereumAPI: [
            "https://host-76-74-28-235.contentfabric.io/eth/",
            "https://host-76-74-28-227.contentfabric.io/eth/",
            "https://host-76-74-28-233.contentfabric.io/eth/",
          ],
          fabricAPI: [
            "https://host-76-74-28-233.contentfabric.io",
            "https://host-76-74-28-235.contentfabric.io",
            "https://host-76-74-28-227.contentfabric.io",
          ],
          search: [
            "https://host-154-14-192-77.contentfabric.io/"
          ]
        )
      ),
      qspace: Qspace(
        id: "ispc3ANoVSzNA3P6t7abLR69ho5YPPZU",
        version: "BaseContentSpace20191203120000PO",
        type: "Ethereum",
        names: ["demov3", "dv3"]
      ),
    )
  }
}
