public enum SignOutHandler {
  /// Set by the app target at startup to reset the navigation stack.
  /// EluvioCore has no knowledge of the app's Router type.
  public static var resetNavigation: (() -> Void)?

  public static func signOut() async {
      AccountStore.shared.signOut()
      await CacheManager().clearAccountScopedCaches()
      resetNavigation?()
      // Re-fetch the Discover page after reset. Goes through DiscoverStore rather than
      // straight to fetchProperties, because clearAccountScopedCaches drops the rows too -
      // and it falls back to fetchProperties on its own if the rows don't come back.
      await DiscoverStore.shared.load()
  }
}
