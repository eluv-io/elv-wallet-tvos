public struct ResolvedPermission: Codable, Hashable {
  public var authorized: Bool = true
  public var behavior: PermissionBehavior = .hide
  public var secondaryPurchaseOption: String = ""
  public var alternatePageId: String = ""
  public var permissionItemIds: [String] = []
  public var cause: String = ""
}

public extension ResolvedPermission {
  public var hide: Bool {
    if authorized {
      behavior == .showIfUnauthorized
    } else {
      behavior == .hide
    }
  }

  public var disable: Bool {
    return !authorized && behavior == .disable
  }

  public var purchaseGate: Bool {
    return !authorized && behavior == .showPurchase
  }

  public var showAlternatePage: Bool {
    return !authorized && behavior == .showAlternativePage
  }
}
