import Foundation
import Observation

@Observable
class AccountStore {
  static var shared = AccountStore()

  var staticToken: String

  //temp
  let accountManager = AccountManager()

  var account: Account? {
    accountManager.currentAccount
  }

  // Either a fabric token is the user is logged in, or a static token for the current network
  var bestToken: String {
    account?.fabricToken ?? staticToken
  }

  private init() {
    let configStore = FabricConfigStore.shared
    self.staticToken = createStaticToken(qspace: configStore.config.qspace.id)
    withObservationTracking { [weak self] in
      let qspace = configStore.config.qspace.id
      if qspace.starts(with: "ispc") {
        self?.staticToken = createStaticToken(qspace: configStore.config.qspace.id)
      } else {
        print("Unexpected qspace id, not generating static token (qspaceid=\(qspace))")
      }
    }
  }
}

private func createStaticToken(qspace: String) -> String {
  do {
    let dict: [String: Any] = ["qspace_id": qspace]
    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
    let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
    return jsonString.base64()
  } catch {
    print(error.localizedDescription)
  }

  return ""
}
