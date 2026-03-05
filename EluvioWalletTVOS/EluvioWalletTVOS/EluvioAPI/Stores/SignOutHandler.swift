enum SignOutHandler {
  static func signOut() async {
      await PropertyStore.shared.clear()
      await PersistentDataCache().clearCache()
      await EluvioAPI.shared.signOut()
      Router.shared.reset()
      // Re-fetch properties after reset
      await PropertyStore.shared.fetchProperties()
  }
}
