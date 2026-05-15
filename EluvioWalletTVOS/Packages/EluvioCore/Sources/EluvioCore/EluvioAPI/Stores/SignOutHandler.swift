enum SignOutHandler {
  static func signOut() async {
      AccountStore.shared.signOut()
      await PropertyStore.shared.clear()
      await PersistentDataCache().clearCache()
      Router.shared.reset()
      // Re-fetch properties after reset
      await PropertyStore.shared.fetchProperties()
  }
}
