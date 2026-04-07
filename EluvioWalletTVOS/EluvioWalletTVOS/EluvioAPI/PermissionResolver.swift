import Foundation

/// Recursively resolves permissions and updates entities with resolved permissions.
enum PermissionResolver {

  static func resolvePermissions(
    _ permissionable: any Permissionable,
    parentPermissions: ResolvedPermission? = nil,
    permissionStates: PermissionStateMap
  ) {
    // Resolve property/page-level permissions first
    if resolveSpecialPermissions(permissionable, permissionStates: permissionStates) {
      return
    }

    resolveContentPermissions(
      permissionable, parentPermissions: parentPermissions, permissionStates: permissionStates)

    for child in permissionable.permissionChildren {
      resolvePermissions(
        child, parentPermissions: permissionable.resolvedPermissions,
        permissionStates: permissionStates)
    }
  }

  static func resolvePermissions(
    _ permissionables: [any Permissionable],
    parentPermissions: ResolvedPermission? = nil,
    permissionStates: PermissionStateMap
  ) {
    for permissionable in permissionables {
      resolvePermissions(
        permissionable, parentPermissions: parentPermissions, permissionStates: permissionStates)
    }
  }

  // MARK: - Private

  /// Resolves property-level or page-level permissions.
  /// Returns true if we should short-circuit (skip content permission resolution).
  private static func resolveSpecialPermissions(
    _ permissionable: any Permissionable,
    permissionStates: PermissionStateMap
  ) -> Bool {
    guard let dto = permissionable.permissions else { return false }

    if let property = permissionable as? MediaProperty {
      // Resolve property-level permissions
      if let ids = dto.property_permissions, !ids.isEmpty {
        let propDto = PermissionsDto(
          permission_item_ids: ids,
          behavior: dto.property_permissions_behavior,
          alternate_page_id: dto.property_permissions_alternate_page_id,
          secondary_market_purchase_option: dto
            .property_permissions_secondary_market_purchase_option
        )
        property.resolvedPropertyPermissions = propDto.toResolvedPermission(
          permissionStates: permissionStates)
      }
      // Resolve search-level permissions
      if let searchBehavior = dto.search_permissions_behavior {
        let searchDto = PermissionsDto(
          permission_item_ids: nil,
          behavior: searchBehavior,
          alternate_page_id: dto.search_permissions_alternate_page_id,
          secondary_market_purchase_option: dto.search_permissions_secondary_market_purchase_option
        )
        property.resolvedSearchPermissions = searchDto.toResolvedPermission(
          permissionStates: permissionStates)
      }
      // An inaccessible property could still render a Page, so don't short-circuit
      return false
    } else if let page = permissionable as? MediaPropertyPage {
      // Resolve page-level permissions
      if let ids = dto.page_permissions, !ids.isEmpty {
        let pageDto = PermissionsDto(
          permission_item_ids: ids,
          behavior: dto.page_permissions_behavior,
          alternate_page_id: dto.page_permissions_alternate_page_id,
          secondary_market_purchase_option: dto.page_permissions_secondary_market_purchase_option
        )
        page.resolvedPagePermissions = pageDto.toResolvedPermission(
          permissionStates: permissionStates)
      }
      // If page is unauthorized, skip content permissions — nothing will be visible
      return page.resolvedPagePermissions?.authorized == false
    }

    return false
  }

  private static func resolveContentPermissions(
    _ permissionable: any Permissionable,
    parentPermissions: ResolvedPermission?,
    permissionStates: PermissionStateMap
  ) {
    guard let rawPermissions = permissionable.permissions else {
      // No permissions defined, inherit parent as-is
      permissionable.resolvedPermissions = parentPermissions
      return
    }

    if let parentPermissions {
      permissionable.resolvedPermissions = merge(
        parent: parentPermissions,
        child: rawPermissions,
        permissionStates: permissionStates
      )
    } else {
      // Top level, resolve with own permissions as parent
      permissionable.resolvedPermissions = merge(
        parent: rawPermissions.toResolvedPermission(permissionStates: permissionStates),
        child: nil,
        permissionStates: permissionStates
      )
    }
  }

  /// Merges parent and child permissions. Parent permissions take over once we hit an unauthorized state.
  private static func merge(
    parent: ResolvedPermission,
    child: PermissionsDto?,
    permissionStates: PermissionStateMap
  ) -> ResolvedPermission {
    guard let child else {
      // No child permissions, inherit parent
      return parent
    }

    if !parent.authorized {
      // Parent is not authorized — everything down the line is unauthorized.
      // Use parent's fields, fill gaps from child.
      return ResolvedPermission(
        authorized: false,
        behavior: parent.behavior,
        secondaryPurchaseOption: parent.secondaryPurchaseOption.isEmpty
          ? (child.secondary_market_purchase_option ?? "") : parent.secondaryPurchaseOption,
        alternatePageId: parent.alternatePageId.isEmpty
          ? (child.alternate_page_id ?? "") : parent.alternatePageId,
        permissionItemIds: parent.permissionItemIds.isEmpty
          ? (child.permission_item_ids ?? []) : parent.permissionItemIds
      )
    } else {
      // Parent is authorized — child checks its own permissions.
      let childResolved = child.toResolvedPermission(permissionStates: permissionStates)
      return ResolvedPermission(
        authorized: childResolved.authorized,
        behavior: child.behavior ?? parent.behavior,
        secondaryPurchaseOption: child.secondary_market_purchase_option
          ?? parent.secondaryPurchaseOption,
        alternatePageId: child.alternate_page_id ?? parent.alternatePageId,
        permissionItemIds: (child.permission_item_ids ?? []).isEmpty
          ? parent.permissionItemIds : (child.permission_item_ids ?? [])
      )
    }
  }
}

// MARK: - PermissionsDto helpers

extension PermissionsDto {
  func toResolvedPermission(permissionStates: PermissionStateMap) -> ResolvedPermission {
    ResolvedPermission(
      authorized: calcAuthorized(permissionStates: permissionStates),
      behavior: behavior ?? .hide,
      secondaryPurchaseOption: secondary_market_purchase_option ?? "",
      alternatePageId: alternate_page_id ?? "",
      permissionItemIds: permission_item_ids ?? []
    )
  }

  func calcAuthorized(permissionStates: PermissionStateMap) -> Bool {
    let ids = permission_item_ids ?? []
    return ids.isEmpty || ids.contains { permissionStates[$0]?.authorized == true }
  }
}
