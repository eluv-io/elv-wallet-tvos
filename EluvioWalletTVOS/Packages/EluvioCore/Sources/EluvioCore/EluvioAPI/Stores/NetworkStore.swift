import Foundation
import Observation

//XXX: in Android we call this EnvironmentStore, but here the name Environment is reseved for the distinction between prod/staging, and not main/demov3
@Observable
public class NetworkStore {
  public static let shared = NetworkStore()

  public var selectedNetwork: AppMode {
    didSet {
      debugPrint("Network changed: \(selectedNetwork)")
      UserDefaults.standard.set(selectedNetwork.rawValue, forKey: "fabric_network")
      #if DEBUG
        // Killing the app too quickly after changing envs leads to unflushed changes
        UserDefaults.standard.synchronize()
      #endif
    }
  }

  public var environment: APIEnvironment {
    didSet {
      debugPrint("Environemnt changed: \(environment)")
      UserDefaults.standard.set(environment.rawValue, forKey: "api_environment")
      #if DEBUG
        // Killing the app too quickly after changing envs leads to unflushed changes
        UserDefaults.standard.synchronize()
      #endif
    }
  }

  private init() {
    let envVal = UserDefaults.standard.string(forKey: "api_environment") ?? ""
    environment = APIEnvironment.init(rawValue: envVal) ?? APIEnvironment.prod

    let networkVal = UserDefaults.standard.string(forKey: "fabric_network") ?? ""
    selectedNetwork = AppMode.init(rawValue: networkVal) ?? AppMode.main
  }
}
