import Alamofire
import Foundation
import Observation

@Observable
class FabricConfigStore {
  static let shared = FabricConfigStore()

  var config: FabricConfiguration

  var apiBaseUrl: String {
    config.getAuthServices().first?.ensuringSuffix("/") ?? ""
  }

  var fabricBaseUrl: String {
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

  var walletUrl: String {
    APP_CONFIG.network[NetworkStore.shared.selectedNetwork.rawValue]!.wallet_url
  }

  private init() {
    let networkStore = NetworkStore.shared
    config = defaultConfig(for: networkStore.selectedNetwork)
    Task {
      repeat {
        do {
          await refreshConfig(for: networkStore.selectedNetwork)
          try await Task.sleep(for: .minutes(3))  // This throws if task is cancelled
        } catch {
          break
        }
      } while !Task.isCancelled
    }
  }

  func refreshConfig(for network: AppMode) async {
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
}

// Create a default config so we never have to wait on it during startup - it should immediately be replaced by one fetched from server
private func defaultConfig(for network: AppMode) -> FabricConfiguration {
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
