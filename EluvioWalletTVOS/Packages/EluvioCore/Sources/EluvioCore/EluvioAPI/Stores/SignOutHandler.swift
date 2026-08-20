public enum SignOutHandler {
  /// Set by the app target at startup to reset the navigation stack.
  /// EluvioCore has no knowledge of the app's Router type.
  public static var resetNavigation: (() -> Void)?

  public static func signOut() async {
      AccountStore.shared.signOut()
      await CacheManager().clearAccountScopedCaches()
      resetNavigation?()
      // Re-fetch properties after reset
      await PropertyStore.shared.fetchProperties()
  }
}
