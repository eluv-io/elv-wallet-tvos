public protocol Permissionable: AnyObject {
  // Set by server. Doesn't tell the full story until resolved.
  var permissions: PermissionsDto? { get }
  // Set on the client after resolution.
  var resolvedPermissions: ResolvedPermission? { get set }
  // Direct children that also have permissions.
  var permissionChildren: [any Permissionable] { get }
}
