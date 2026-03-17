import Foundation
import Observation

@Observable
class AccountStore {
  static var shared = AccountStore()

  var staticToken: String

  var account: Account? {
    didSet {
      debugPrint(
        "Account updated: addr=\(account?.id ?? "<nil>") token=\(account?.fabricToken.prefix(30).appending("...") ?? "<nil>")"
      )
      saveAccount(account)
    }
  }

  // Either a fabric token is the user is logged in, or a static token for the current network
  var bestToken: String {
    account?.fabricToken ?? staticToken
  }

  private init() {
    account = getSavedAccount()

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

  var isLoggedOut: Bool {
    return account == nil
  }

  func signOut() {
    account = nil
  }

  private func saveAccount(_ account: Account?) {
    if account == nil {
      UserDefaults.standard.removeObject(forKey: "current_account")
    } else if let encoded = try? JSONEncoder().encode(account) {
      UserDefaults.standard.set(encoded, forKey: "current_account")
    }
  }
}

private func getSavedAccount() -> Account? {
  // We used to save a "type" field, which didn't hold enough data to
  guard let accountData = UserDefaults.standard.object(forKey: "current_account") as? Data else {
    return nil
  }
  guard let account = try? JSONDecoder().decode(Account.self, from: accountData) else {
    return nil
  }
  debugPrint("Retrieved " + account.id)

  debugPrint("Now Date \(Date())")
  debugPrint("ExpiresAt \(account.expiresAt)")

  return account
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
