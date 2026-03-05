struct ResolvedPermission: Codable, Hashable {
  var authorized: Bool = true
  var behavior: PermissionBehavior = .hide
  var secondaryPurchaseOption: String = ""
  var alternatePageId: String = ""
  var permissionItemIds: [String] = []
  var cause: String = ""
}

extension ResolvedPermission {
  var hide: Bool {
    return !authorized && behavior == .hide
  }

  var disable: Bool {
    return !authorized && behavior == .disable
  }

  var purchaseGate: Bool {
    return !authorized && behavior == .showPurchase
  }

  var showAlternatePage: Bool {
    return !authorized && behavior == .showAlternativePage
  }
}
