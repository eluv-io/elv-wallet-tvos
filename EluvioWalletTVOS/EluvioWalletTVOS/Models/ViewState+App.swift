import EluvioCore
import Foundation

extension ViewState {
  /// Returns true if we can load the page
  func login(_ property: MediaProperty, eluvio: EluvioAPI, router: Router) {
    if property.accountType == AccountStore.shared.account?.type {
      debugPrint("Logged in with correct account type - navigating to Property.")
      let param = PropertyParam(propertyId: property.id)
      router.push(to: .property(param))
    } else {
      debugPrint("Not logged in with same account type as Property - navigating to Login.")
      router.push(to: .login(LoginParam(property: property)))
    }
  }
}
